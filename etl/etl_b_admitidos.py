"""
ETL B · Admitidos (primera y segunda opción)
Proyecto 02 · TI-6900 Inteligencia de Negocios · Escuela de ATI (TEC)
Responsable: Persona 6

Uso:
    python etl/etl_b_admitidos.py --fuente "data/raw/Datos proyecto BI v2.xlsx" \
                                  --bd data/dw/dw_ati.db

Fases: extracción -> validación de origen -> transformación (reglas RT-B01..RT-B09)
       -> carga idempotente de dimensiones y de fact_admisiones
       -> validaciones posteriores -> pruebas de consistencia agregada con solicitantes.
"""
from __future__ import annotations

import argparse
import logging
import sqlite3
import sys
from pathlib import Path

import pandas as pd

sys.path.insert(0, str(Path(__file__).resolve().parent))
from comun import (ahora, clave, limpiar, normalizar_generico, normalizar_provincia,  # noqa: E402
                   nuevo_lote, obtener_o_crear)
from reglas_dimensiones_b import (clasificar_rango, estandarizar_perfil, evaluar_nota,  # noqa: E402
                                  homologar_forma_ingreso)

COMPONENTE = "ETL_B"
RAIZ = Path(__file__).resolve().parents[1]

HOJAS_ADMITIDOS = {"Admitidos primera opción": 1, "Admitidos segunda opción": 2}
HOJAS_SOLICITANTES = {"Solicitantes primera opción": 1, "Solicitantes segunda opción": 2}

COLUMNAS_ADMITIDOS = [
    "Año", "Modalidad del Colegio", "Tipo de Financiamiento del Colegio", "Zona de Residencia",
    "Región de Planificación", "Provincia de Procedencia", "Cantón de Procedencia",
    "Distrito de Procedencia", "Nivel de Desarrollo Social", "Zona GAM", "Rango de Edad",
    "Forma de Ingreso", "Nota de Admisión", "Rango de Nota de Admisión", "Nacionalidad",
    "Tipo de Estudiante", "Solicitud de Adecuación", "Tipo de Diploma de Secundaria",
]
# RT-B08: atributo sensible que NO se carga al modelo
COLUMNAS_EXCLUIDAS = ["Solicitud de Adecuación"]
ANIO_MIN, ANIO_MAX = 2020, 2026

log = logging.getLogger(COMPONENTE)


# ==========================================================================
# Utilidades de control
# ==========================================================================
class Control:
    """Registra pasos de bitácora y resultados de validación del lote."""

    def __init__(self, con: sqlite3.Connection, lote: str):
        self.con, self.lote = con, lote
        self.validaciones: list[dict] = []

    def paso(self, nombre: str, inicio: str, filas: int | None, estado="OK", detalle=""):
        self.con.execute(
            "INSERT INTO etl_bitacora (id_lote, componente, paso, inicio, fin, filas, estado, detalle)"
            " VALUES (?,?,?,?,?,?,?,?)",
            (self.lote, COMPONENTE, nombre, inicio, ahora(), filas, estado, detalle))
        log.info("%-38s filas=%-6s estado=%s %s", nombre, filas if filas is not None else "-",
                 estado, detalle)

    def validar(self, codigo, prueba, esperado, obtenido, ok: bool,
                nivel_fallo="ERROR", detalle=""):
        estado = "OK" if ok else nivel_fallo
        fila = dict(id_lote=self.lote, componente=COMPONENTE, codigo=codigo, prueba=prueba,
                    esperado=str(esperado), obtenido=str(obtenido), estado=estado, detalle=detalle)
        self.validaciones.append(fila)
        self.con.execute(
            "INSERT INTO etl_validacion (id_lote, componente, codigo, prueba, esperado, obtenido,"
            " estado, detalle) VALUES (:id_lote,:componente,:codigo,:prueba,:esperado,:obtenido,"
            ":estado,:detalle)", fila)
        log.log(logging.INFO if ok else logging.WARNING, "[%s] %-11s %s | esperado=%s obtenido=%s %s",
                codigo, estado, prueba, esperado, obtenido, detalle)


# ==========================================================================
# 1. Extracción
# ==========================================================================
def extraer(fuente: Path, hojas: dict[str, int]) -> pd.DataFrame:
    """Lee las hojas como texto (sin inferir tipos) y añade linaje y opción (RT-B01, RT-B02)."""
    marcos = []
    for hoja, opcion in hojas.items():
        df = pd.read_excel(fuente, sheet_name=hoja, dtype=str, keep_default_na=False)
        df["hoja_origen"] = hoja
        df["fila_origen"] = df.index + 2          # fila real en Excel (fila 1 = encabezado)
        df["codigo_opcion"] = opcion
        marcos.append(df)
    return pd.concat(marcos, ignore_index=True)


# ==========================================================================
# 2. Transformación
# ==========================================================================
def transformar(df: pd.DataFrame, ctl: Control) -> pd.DataFrame:
    filas = []
    no_clasificadas = 0
    for _, f in df.iterrows():
        forma = homologar_forma_ingreso(f["Forma de Ingreso"])
        no_clasificadas += 0 if forma["clasificada"] else 1
        rango = clasificar_rango(f["Rango de Nota de Admisión"])
        nota = evaluar_nota(f["Nota de Admisión"], forma, rango)
        perfil = estandarizar_perfil(f)
        filas.append(dict(
            hoja_origen=f["hoja_origen"], fila_origen=int(f["fila_origen"]),
            codigo_opcion=int(f["codigo_opcion"]), anio=int(limpiar(f["Año"])),
            # dimensiones compartidas: misma normalización que el ETL A (módulo comun)
            provincia=normalizar_provincia(f["Provincia de Procedencia"]),
            canton=normalizar_generico(f["Cantón de Procedencia"]),
            distrito=normalizar_generico(f["Distrito de Procedencia"]),
            region_planificacion=normalizar_generico(f["Región de Planificación"]),
            zona_residencia=normalizar_generico(f["Zona de Residencia"]),
            nivel_desarrollo_social=normalizar_generico(f["Nivel de Desarrollo Social"]),
            zona_gam=normalizar_generico(f["Zona GAM"]),
            modalidad=normalizar_generico(f["Modalidad del Colegio"]),
            tipo_financiamiento=normalizar_generico(f["Tipo de Financiamiento del Colegio"]),
            forma_origen=limpiar(f["Forma de Ingreso"]), **{k: v for k, v in forma.items() if k != "clasificada"},
            **rango, **nota, **perfil,
        ))
    t = pd.DataFrame(filas)
    if no_clasificadas:
        log.warning("Formas de ingreso no clasificadas: %s", no_clasificadas)
    return t


# ==========================================================================
# 3. Carga
# ==========================================================================
def cargar(con: sqlite3.Connection, t: pd.DataFrame, lote: str) -> dict:
    cache: dict = {}
    creados = {d: 0 for d in ["dim_tiempo", "dim_geografia", "dim_colegio", "dim_opcion",
                              "dim_forma_ingreso", "dim_rango_nota", "dim_perfil_estudiante"]}

    def oc(tabla, sk, natural, atributos):
        valor, nuevo = obtener_o_crear(con, tabla, sk, natural, atributos, cache)
        creados[tabla] += int(nuevo)
        return valor

    registros = []
    fecha = ahora()
    for r in t.itertuples(index=False):
        sk_tiempo = oc("dim_tiempo", "sk_tiempo", {"anio": r.anio}, {"etiqueta_anio": str(r.anio)})
        geo = dict(provincia=r.provincia, canton=r.canton, distrito=r.distrito,
                   region_planificacion=r.region_planificacion, zona_residencia=r.zona_residencia,
                   nivel_desarrollo_social=r.nivel_desarrollo_social, zona_gam=r.zona_gam)
        sk_geo = oc("dim_geografia", "sk_geografia",
                    {"clave_natural": "|".join(clave(v) for v in geo.values())}, geo)
        col = dict(modalidad=r.modalidad, tipo_financiamiento=r.tipo_financiamiento)
        sk_col = oc("dim_colegio", "sk_colegio",
                    {"clave_natural": "|".join(clave(v) for v in col.values())}, col)
        sk_opc = oc("dim_opcion", "sk_opcion", {"codigo_opcion": r.codigo_opcion},
                    {"opcion": "Primera opción" if r.codigo_opcion == 1 else "Segunda opción"})
        sk_forma = oc("dim_forma_ingreso", "sk_forma_ingreso", {"clave_natural": clave(r.forma_ingreso)},
                      dict(forma_ingreso=r.forma_ingreso, valor_origen=r.forma_origen,
                           tipo_via=r.tipo_via, exige_nota=r.exige_nota))
        sk_rango = oc("dim_rango_nota", "sk_rango_nota", {"clave_natural": clave(r.rango_nota)},
                      dict(rango_nota=r.rango_nota, limite_inferior=r.limite_inferior,
                           limite_superior=r.limite_superior, orden=r.orden, tipo_rango=r.tipo_rango))
        perfil = dict(condicion_academica=r.condicion_academica, rango_edad=r.rango_edad,
                      nacionalidad=r.nacionalidad, tipo_diploma=r.tipo_diploma)
        sk_perfil = oc("dim_perfil_estudiante", "sk_perfil",
                       {"clave_natural": "|".join(clave(v) for v in perfil.values())},
                       {**perfil, "orden_rango_edad": r.orden_rango_edad,
                        "grupo_nacionalidad": r.grupo_nacionalidad})
        nota = None if pd.isna(r.nota_admision) else float(r.nota_admision)
        registros.append((sk_tiempo, sk_geo, sk_col, sk_opc, sk_perfil, sk_forma, sk_rango,
                          nota, r.estado_nota, int(r.es_nota_valida), 1,
                          r.hoja_origen, int(r.fila_origen), lote, fecha))

    # RT-B09: recarga idempotente. Se reemplazan solo las filas de las hojas de admitidos,
    # dentro de la misma transacción; la restricción UNIQUE(hoja_origen, fila_origen)
    # impide que una segunda ejecución duplique hechos.
    hojas = tuple(HOJAS_ADMITIDOS)
    borradas = con.execute(
        f"DELETE FROM fact_admisiones WHERE hoja_origen IN ({','.join('?' * len(hojas))})", hojas
    ).rowcount
    con.executemany(
        "INSERT INTO fact_admisiones (sk_tiempo, sk_geografia, sk_colegio, sk_opcion, sk_perfil,"
        " sk_forma_ingreso, sk_rango_nota, nota_admision, estado_nota, es_nota_valida,"
        " cantidad_admisiones, hoja_origen, fila_origen, id_lote, fecha_carga)"
        " VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)", registros)
    return dict(creados=creados, borradas=borradas, insertadas=len(registros))


# ==========================================================================
# 4. Validaciones
# ==========================================================================
def validar_origen(df: pd.DataFrame, ctl: Control):
    for hoja in HOJAS_ADMITIDOS:
        sub = df[df.hoja_origen == hoja]
        faltantes = [c for c in COLUMNAS_ADMITIDOS if c not in sub.columns]
        ctl.validar("VO-01", f"Estructura de columnas · {hoja}", "18 columnas esperadas",
                    "completa" if not faltantes else f"faltan {faltantes}", not faltantes)
    anios = pd.to_numeric(df["Año"].map(limpiar), errors="coerce")
    fuera = int((anios.isna() | (anios < ANIO_MIN) | (anios > ANIO_MAX)).sum())
    ctl.validar("VO-02", "Dominio del año (2020-2026)", 0, fuera, fuera == 0)
    vacias = int((df[COLUMNAS_ADMITIDOS].apply(lambda s: s.map(limpiar)) == "").sum().sum())
    ctl.validar("VO-03", "Celdas vacías en columnas de origen", 0, vacias, vacias == 0,
                "ADVERTENCIA")
    identicas = int(df.duplicated(subset=COLUMNAS_ADMITIDOS + ["hoja_origen"]).sum())
    ctl.validar("VO-04", "Filas idénticas dentro de una misma hoja", 0, identicas, identicas == 0,
                "ADVERTENCIA", "Se conservan: sin identificador no se puede probar duplicación real")


def validar_transformacion(t: pd.DataFrame, ctl: Control):
    no_clas = int((t.tipo_via == "No clasificada").sum())
    ctl.validar("VT-01", "Formas de ingreso homologadas contra catálogo", 0, no_clas, no_clas == 0)
    fuera = t[t.estado_nota == "Fuera de rango"]
    ctl.validar("VT-02", "Nota numérica dentro del rango de nota registrado", 0, len(fuera),
                fuera.empty, "ADVERTENCIA",
                "; ".join(f"{h} fila {f}" for h, f in zip(fuera.hoja_origen, fuera.fila_origen)))
    sin_nota = t[(t.exige_nota == 0) & (t.estado_nota != "No aplica")]
    con_na = t[(t.exige_nota == 1) & (t.estado_nota == "No aplica")]
    ctl.validar("VT-03", "Exención <=> nota 'No aplica' (coherencia forma-nota)", 0,
                len(sin_nota) + len(con_na), sin_nota.empty and con_na.empty, "ADVERTENCIA")
    rango_na = t[(t.estado_nota == "No aplica") != (t.rango_nota == "No aplica")]
    ctl.validar("VT-04", "Nota 'No aplica' <=> rango 'No aplica'", 0, len(rango_na), rango_na.empty,
                "ADVERTENCIA")
    otros = int((t.orden_rango_edad == 9).sum())
    ctl.validar("VT-05", "Rangos de edad reconocidos por el catálogo", 0, otros, otros == 0,
                "ADVERTENCIA")


def validar_carga(con: sqlite3.Connection, df: pd.DataFrame, ctl: Control):
    for hoja in HOJAS_ADMITIDOS:
        origen = int((df.hoja_origen == hoja).sum())
        destino = con.execute("SELECT COUNT(*) FROM fact_admisiones WHERE hoja_origen = ?",
                              (hoja,)).fetchone()[0]
        ctl.validar("VC-01", f"Conteo origen = conteo cargado · {hoja}", origen, destino,
                    origen == destino)
    total = con.execute("SELECT COUNT(*) FROM fact_admisiones").fetchone()[0]
    ctl.validar("VC-02", "Total cargado en fact_admisiones", len(df), total, total == len(df))
    dup = con.execute("SELECT COUNT(*) FROM (SELECT hoja_origen, fila_origen FROM fact_admisiones"
                      " GROUP BY 1,2 HAVING COUNT(*) > 1)").fetchone()[0]
    ctl.validar("VC-03", "Sin duplicados por fila de origen", 0, dup, dup == 0)
    huerfanos = 0
    for sk, dim in [("sk_tiempo", "dim_tiempo"), ("sk_geografia", "dim_geografia"),
                    ("sk_colegio", "dim_colegio"), ("sk_opcion", "dim_opcion"),
                    ("sk_perfil", "dim_perfil_estudiante"), ("sk_forma_ingreso", "dim_forma_ingreso"),
                    ("sk_rango_nota", "dim_rango_nota")]:
        n = con.execute(f"SELECT COUNT(*) FROM fact_admisiones f LEFT JOIN {dim} d USING ({sk})"
                        f" WHERE d.{sk} IS NULL").fetchone()[0]
        huerfanos += n
    ctl.validar("VC-04", "Integridad referencial: hechos sin dimensión (7 llaves)", 0, huerfanos,
                huerfanos == 0)
    for col, tabla in [("anio", "dim_tiempo")]:
        origen = df["Año"].map(limpiar).astype(int).value_counts().sort_index().to_dict()
        destino = dict(con.execute(
            "SELECT t.anio, COUNT(*) FROM fact_admisiones f JOIN dim_tiempo t USING (sk_tiempo)"
            " GROUP BY t.anio ORDER BY t.anio").fetchall())
        ctl.validar("VC-05", "Distribución por año conservada (origen vs. modelo)", origen, destino,
                    origen == destino)
    validas = con.execute("SELECT SUM(es_nota_valida), ROUND(AVG(CASE WHEN es_nota_valida = 1"
                          " THEN nota_admision END), 2) FROM fact_admisiones").fetchone()
    ctl.validar("VC-06", "Notas válidas cargadas (criterio K06) y su promedio", "informativo",
                f"{validas[0]} notas, promedio {validas[1]}", True)


def consistencia_agregada(fuente: Path, t_adm: pd.DataFrame, ctl: Control, salida: Path):
    """
    RT-B10: pruebas de consistencia entre solicitantes y admitidos A NIVEL AGREGADO.
    No se empareja ninguna fila: se comparan conteos por año, opción y categoría.
    Supuesto verificado: toda persona admitida en una opción debió solicitarla, por lo que
    en cada celda (año, opción, categoría) los admitidos no deberían superar a los solicitantes.
    """
    sol = extraer(fuente, HOJAS_SOLICITANTES)
    t_sol = transformar(sol, ctl)
    clave_celda = ["anio", "codigo_opcion"]
    a = t_adm.groupby(clave_celda).size().rename("admitidos")
    s = t_sol.groupby(clave_celda).size().rename("solicitantes")
    tot = pd.concat([a, s], axis=1).fillna(0).astype(int)
    viol = tot[tot.admitidos > tot.solicitantes]
    ctl.validar("CA-01", "Admitidos <= solicitantes por año y opción", 0, len(viol), viol.empty)
    sin_sol = tot[(tot.admitidos > 0) & (tot.solicitantes == 0)]
    ctl.validar("CA-02", "Años con admitidos tienen solicitantes en la misma opción", 0,
                len(sin_sol), sin_sol.empty)

    atributos = {"forma_ingreso": "Forma de ingreso", "rango_nota": "Rango de nota",
                 "condicion_academica": "Condición académica", "nacionalidad": "Nacionalidad",
                 "provincia": "Provincia", "modalidad": "Modalidad del colegio",
                 "tipo_financiamiento": "Financiamiento del colegio", "zona_gam": "Zona GAM"}
    detalle = []
    for col, nombre in atributos.items():
        a = t_adm.groupby(clave_celda + [col]).size().rename("admitidos")
        s = t_sol.groupby(clave_celda + [col]).size().rename("solicitantes")
        m = pd.concat([a, s], axis=1).fillna(0).astype(int).reset_index()
        m = m[m.admitidos > 0]
        malas = m[m.admitidos > m.solicitantes].copy()
        malas.insert(0, "atributo", nombre)
        malas = malas.rename(columns={col: "categoria"})
        detalle.append(malas)
        ctl.validar("CA-03", f"Contención agregada por {nombre}", f"0 de {len(m)} celdas",
                    f"{len(malas)} de {len(m)} celdas", malas.empty, "ADVERTENCIA",
                    "Inconsistencia de la fuente: se documenta, no se corrige")
    det = pd.concat(detalle, ignore_index=True)
    det = det[["atributo", "anio", "codigo_opcion", "categoria", "solicitantes", "admitidos"]]
    det.to_csv(salida, index=False, encoding="utf-8-sig")

    # Un año sin registros en una hoja es "sin datos", no cero: la razón solo se calcula
    # cuando ambas hojas (solicitantes y admitidos) tienen registros para ese año y opción.
    razon = tot.reset_index().sort_values(clave_celda)
    comparable = (razon.solicitantes > 0) & (razon.admitidos > 0)
    razon["razon_adm_sol_%"] = (razon.admitidos / razon.solicitantes * 100).round(1).where(comparable)
    razon["observacion"] = comparable.map({True: "", False: "sin datos en una de las hojas"})
    return det, razon


# ==========================================================================
# Programa principal
# ==========================================================================
def main():
    p = argparse.ArgumentParser(description="ETL B · Admitidos")
    p.add_argument("--fuente", type=Path, default=RAIZ / "data/raw/Datos proyecto BI v2.xlsx")
    p.add_argument("--bd", type=Path, default=RAIZ / "data/dw/dw_ati.db")
    p.add_argument("--ddl", type=Path, default=RAIZ / "sql/ddl_modelo.sql")
    args = p.parse_args()

    lote = nuevo_lote(COMPONENTE)
    (RAIZ / "logs").mkdir(exist_ok=True)
    (RAIZ / "salidas").mkdir(exist_ok=True)
    args.bd.parent.mkdir(parents=True, exist_ok=True)
    logging.basicConfig(level=logging.INFO, format="%(asctime)s | %(levelname)-7s | %(message)s",
                        handlers=[logging.FileHandler(RAIZ / f"logs/{lote}.log", encoding="utf-8"),
                                  logging.StreamHandler(sys.stdout)])
    log.info("Inicio del lote %s · fuente=%s · destino=%s", lote, args.fuente.name, args.bd.name)

    con = sqlite3.connect(args.bd)
    con.execute("PRAGMA foreign_keys = ON")
    con.executescript(args.ddl.read_text(encoding="utf-8"))
    ctl = Control(con, lote)
    try:
        with con:  # una sola transacción: si algo falla, no queda una carga a medias
            i = ahora(); df = extraer(args.fuente, HOJAS_ADMITIDOS)
            ctl.paso("1. Extracción (2 hojas de admitidos)", i, len(df),
                     detalle=str(df.hoja_origen.value_counts().to_dict()))
            i = ahora(); validar_origen(df, ctl); ctl.paso("2. Validación de origen", i, len(df))
            i = ahora(); t = transformar(df, ctl)
            ctl.paso("3. Transformación (RT-B01..RT-B08)", i, len(t),
                     detalle=f"columnas excluidas por sensibilidad: {COLUMNAS_EXCLUIDAS}")
            validar_transformacion(t, ctl)
            i = ahora(); res = cargar(con, t, lote)
            ctl.paso("4. Carga de dimensiones", i, sum(res["creados"].values()),
                     detalle=f"miembros nuevos: {res['creados']}")
            ctl.paso("5. Carga de fact_admisiones", i, res["insertadas"],
                     detalle=f"filas reemplazadas de lotes previos: {res['borradas']}")
            i = ahora(); validar_carga(con, df, ctl); ctl.paso("6. Validaciones posteriores", i, None)
            i = ahora()
            det, razon = consistencia_agregada(args.fuente, t, ctl,
                                               RAIZ / f"salidas/consistencia_agregada_{lote}.csv")
            razon.to_csv(RAIZ / f"salidas/razon_agregada_{lote}.csv", index=False, encoding="utf-8-sig")
            ctl.paso("7. Consistencia agregada con solicitantes", i, len(det),
                     detalle="celdas con admitidos > solicitantes (ver CSV)")
            errores = [v for v in ctl.validaciones if v["estado"] == "ERROR"]
            if errores:
                raise RuntimeError(f"{len(errores)} validaciones en ERROR: se revierte la carga")
    except Exception:
        log.exception("Lote %s revertido", lote)
        con.close()
        sys.exit(1)

    pd.DataFrame(ctl.validaciones).to_csv(RAIZ / f"salidas/validaciones_{lote}.csv", index=False,
                                          encoding="utf-8-sig")
    resumen = pd.DataFrame(ctl.validaciones).estado.value_counts().to_dict()
    log.info("Fin del lote %s · validaciones: %s", lote, resumen)
    con.close()


if __name__ == "__main__":
    main()
