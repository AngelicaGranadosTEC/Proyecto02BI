"""ETL A de solicitantes ATI 2020-2026. Reutiliza los catálogos y dimensiones del ETL B."""
from __future__ import annotations
import argparse
import logging
import os
import sys
from pathlib import Path

import pandas as pd

RAIZ = Path(__file__).resolve().parents[1]
REPO = RAIZ.parent
ETL_B = REPO / "SergioMenaCampos_etl_admitidos" / "etl"
sys.path.insert(0, str(ETL_B))
from comun import BD, Dimensiones, limpiar, normalizar_generico, normalizar_provincia, nuevo_lote  # noqa: E402
from reglas_dimensiones_b import homologar_forma_ingreso, clasificar_rango, evaluar_nota, estandarizar_perfil  # noqa: E402

HOJAS = {"Solicitantes primera opción": 1, "Solicitantes segunda opción": 2}
COLUMNAS = [
    "Año", "Modalidad del Colegio", "Tipo de Financiamiento del Colegio", "Zona de Residencia",
    "Región de Planificación", "Provincia de Procedencia", "Cantón de Procedencia",
    "Distrito de Procedencia", "Nivel de Desarrollo Social", "Zona GAM", "Rango de Edad",
    "Forma de Ingreso", "Nota de Admisión", "Nota de IV Ciclo", "Rango de Nota de Admisión",
    "Nacionalidad", "Tipo de Estudiante", "Solicitud de Adecuación", "Tipo de Diploma de Secundaria",
]
log = logging.getLogger("ETL_A")


def extraer(fuente: Path) -> pd.DataFrame:
    if not fuente.is_file():
        raise FileNotFoundError(f"No se encontró el Excel: {fuente}")
    bloques = []
    for hoja, opcion in HOJAS.items():
        df = pd.read_excel(fuente, sheet_name=hoja, dtype=str, keep_default_na=False)
        faltantes = set(COLUMNAS) - set(df.columns)
        if faltantes:
            raise ValueError(f"Faltan columnas en {hoja}: {sorted(faltantes)}")
        df = df[COLUMNAS].copy()
        df["hoja_origen"] = hoja
        df["fila_origen"] = df.index + 2
        df["codigo_opcion"] = opcion
        bloques.append(df)
    bruto = pd.concat(bloques, ignore_index=True)
    if bruto.duplicated(["hoja_origen", "fila_origen"]).any():
        raise ValueError("Existe una referencia de origen (hoja, fila) repetida")
    return bruto


def nota_iv_ciclo(valor):
    original = limpiar(valor)
    if not original or original.upper() in ("NO APLICA", "NO ESPECIFICADO"):
        return None
    try:
        return round(float(original.replace(",", ".")), 2)
    except ValueError:
        return None


def transformar(bruto: pd.DataFrame) -> pd.DataFrame:
    resultado = []
    for _, f in bruto.iterrows():
        forma = homologar_forma_ingreso(f["Forma de Ingreso"])
        rango = clasificar_rango(f["Rango de Nota de Admisión"])
        nota = evaluar_nota(f["Nota de Admisión"], forma, rango)
        perfil = estandarizar_perfil(f)
        anio = int(limpiar(f["Año"]))
        if not 2020 <= anio <= 2026:
            raise ValueError(f"Año no esperado: {anio} en {f['hoja_origen']} fila {f['fila_origen']}")
        resultado.append(dict(
            hoja_origen=f["hoja_origen"], fila_origen=int(f["fila_origen"]),
            codigo_opcion=int(f["codigo_opcion"]), anio=anio,
            provincia=normalizar_provincia(f["Provincia de Procedencia"]),
            canton=normalizar_generico(f["Cantón de Procedencia"]),
            distrito=normalizar_generico(f["Distrito de Procedencia"]),
            region_planificacion=normalizar_generico(f["Región de Planificación"]),
            zona_residencia=normalizar_generico(f["Zona de Residencia"]),
            nivel_desarrollo_social=normalizar_generico(f["Nivel de Desarrollo Social"]),
            zona_gam=normalizar_generico(f["Zona GAM"]),
            modalidad=normalizar_generico(f["Modalidad del Colegio"]),
            tipo_financiamiento=normalizar_generico(f["Tipo de Financiamiento del Colegio"]),
            nota_origen=limpiar(f["Nota de Admisión"]),
            nota_iv_origen=limpiar(f["Nota de IV Ciclo"]),
            nota_iv=nota_iv_ciclo(f["Nota de IV Ciclo"]),
            forma_origen=limpiar(f["Forma de Ingreso"]),
            **{k: v for k, v in forma.items() if k != "clasificada"},
            **rango, **nota, **perfil,
        ))
    return pd.DataFrame(resultado)


def cargar(bd: BD, transformado: pd.DataFrame) -> dict:
    dims = Dimensiones(bd)
    datos = []
    for r in transformado.itertuples(index=False):
        ids = [
            dims.id("dim_tiempo", "id_tiempo", {"anio": int(r.anio)}),
            dims.id("dim_geografia", "id_geografia", dict(
                zona_residencia=r.zona_residencia, region_planificacion=r.region_planificacion,
                provincia=r.provincia, canton=r.canton, distrito=r.distrito,
                nivel_desarrollo_social=r.nivel_desarrollo_social, zona_gam=r.zona_gam)),
            dims.id("dim_colegio", "id_colegio", dict(
                modalidad=r.modalidad, tipo_financiamiento=r.tipo_financiamiento)),
            dims.id("dim_opcion", "id_opcion", {"codigo_opcion": int(r.codigo_opcion)},
                    {"opcion": "Primera opción" if r.codigo_opcion == 1 else "Segunda opción"}),
            dims.id("dim_perfil_estudiante", "id_perfil_estudiante", dict(
                condicion_academica=r.condicion_academica, rango_edad=r.rango_edad,
                nacionalidad=r.nacionalidad, tipo_diploma=r.tipo_diploma),
                    {"orden_rango_edad": int(r.orden_rango_edad), "grupo_nacionalidad": r.grupo_nacionalidad}),
            dims.id("dim_forma_ingreso", "id_forma_ingreso", {"forma_ingreso": r.forma_ingreso},
                    dict(valor_origen=r.forma_origen, tipo_via=r.tipo_via,
                         exige_nota=bool(r.exige_nota))),
            dims.id("dim_rango_nota", "id_rango_nota", {"rango_nota": r.rango_nota},
                    dict(limite_inferior=None if pd.isna(r.limite_inferior) else float(r.limite_inferior),
                         limite_superior=None if pd.isna(r.limite_superior) else float(r.limite_superior),
                         orden=int(r.orden), tipo_rango=r.tipo_rango)),
        ]
        nota = None if pd.isna(r.nota_admision) else float(r.nota_admision)
        datos.append((*ids, r.nota_origen, nota, r.nota_iv_origen, r.nota_iv,
                      r.hoja_origen, int(r.fila_origen)))
    hojas = tuple(HOJAS)
    borrados = bd.ejecutar("DELETE FROM bi.fact_solicitudes WHERE hoja_origen IN (?,?)", hojas).rowcount
    bd.muchos("INSERT INTO bi.fact_solicitudes (id_tiempo, id_geografia, id_colegio,"
              " id_opcion, id_perfil_estudiante, id_forma_ingreso, id_rango_nota,"
              " nota_admision_original, nota_admision, nota_iv_ciclo_original, nota_iv_ciclo,"
              " hoja_origen, fila_origen) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?)", datos)
    return dict(insertados=len(datos), reemplazados=borrados, dimensiones_nuevas=dims.creados)


def validar(bd: BD, bruto: pd.DataFrame, t: pd.DataFrame) -> list[dict]:
    pruebas = []
    def prueba(codigo, nombre, esperado, obtenido, ok):
        pruebas.append(dict(codigo=codigo, prueba=nombre, esperado=str(esperado),
                            obtenido=str(obtenido), estado="OK" if ok else "ERROR"))
    for hoja in HOJAS:
        esperado = int((bruto.hoja_origen == hoja).sum())
        obtenido = bd.ejecutar("SELECT COUNT(*) FROM bi.fact_solicitudes WHERE hoja_origen=?", (hoja,)).fetchone()[0]
        prueba("VC-A01", f"Conteo de {hoja}", esperado, obtenido, esperado == obtenido)
    total = bd.ejecutar("SELECT COUNT(*) FROM bi.fact_solicitudes WHERE hoja_origen IN (?,?)", tuple(HOJAS)).fetchone()[0]
    prueba("VC-A02", "Total de solicitantes", len(bruto), total, total == len(bruto))
    dup = bd.ejecutar("SELECT COUNT(*) FROM (SELECT hoja_origen, fila_origen FROM bi.fact_solicitudes"
                     " GROUP BY hoja_origen,fila_origen HAVING COUNT(*) > 1) x").fetchone()[0]
    prueba("VC-A03", "Sin duplicación por hoja y fila", 0, dup, dup == 0)
    for campo, tabla in [("id_tiempo", "dim_tiempo"), ("id_geografia", "dim_geografia"),
                         ("id_colegio", "dim_colegio"), ("id_opcion", "dim_opcion"),
                         ("id_perfil_estudiante", "dim_perfil_estudiante"),
                         ("id_forma_ingreso", "dim_forma_ingreso"), ("id_rango_nota", "dim_rango_nota")]:
        h = bd.ejecutar(f"SELECT COUNT(*) FROM bi.fact_solicitudes f LEFT JOIN bi.{tabla} d "
                       f"ON f.{campo}=d.{campo} WHERE d.{campo} IS NULL").fetchone()[0]
        prueba("VC-A04", f"Sin huérfanos: {tabla}", 0, h, h == 0)
    origen = {int(k): int(v) for k,v in bruto.groupby("Año").size().items()}
    destino = {int(a): int(n) for a,n in bd.ejecutar(
        "SELECT t.anio, COUNT(*) FROM bi.fact_solicitudes f JOIN bi.dim_tiempo t "
        "ON f.id_tiempo=t.id_tiempo GROUP BY t.anio").fetchall()}
    prueba("VC-A05", "Conteos por año", origen, destino, origen == destino)
    return pruebas


def main():
    parser = argparse.ArgumentParser(description="ETL A · Solicitantes de ATI")
    parser.add_argument("--fuente", type=Path, required=True, help="Ruta al Excel Datos proyecto BI v2.xlsx")
    parser.add_argument("--bd", default=os.environ.get("BI_DSN", str(RAIZ / "data/dw/dw_ati.db")))
    args = parser.parse_args()
    lote = nuevo_lote("ETL_A")
    for carpeta in ("logs", "salidas"):
        (RAIZ / carpeta).mkdir(exist_ok=True)
    logging.basicConfig(level=logging.INFO, format="%(asctime)s | %(levelname)s | %(message)s",
                        handlers=[logging.StreamHandler(sys.stdout),
                                  logging.FileHandler(RAIZ / f"logs/{lote}.log", encoding="utf-8")])
    log.info("Inicia %s · fuente=%s", lote, args.fuente)
    bd = None
    try:
        bruto = extraer(args.fuente)
        log.info("Extraídos %s registros: %s", len(bruto), bruto.hoja_origen.value_counts().to_dict())
        t = transformar(bruto)
        log.info("Transformados %s · notas cero=%s · no numéricas=%s", len(t),
                 int((t.estado_nota == "Cero").sum()), int(t.nota_admision.isna().sum()))
        if not args.bd.startswith(("postgresql://", "postgres://")):
            Path(args.bd).parent.mkdir(parents=True, exist_ok=True)
        bd = BD(args.bd)
        if bd.motor == "sqlite":
            ddl_b = REPO / "SergioMenaCampos_etl_admitidos/sql/sqlite/ddl_componente_b.sql"
            bd.script(ddl_b.read_text(encoding="utf-8"))
            bd.script((RAIZ / "sql/ddl_fact_solicitudes_sqlite.sql").read_text(encoding="utf-8"))
        # PostgreSQL: aplicar previamente SQL de Pamela (v1 y ajuste v2) y DDL de Sergio.
        carga = cargar(bd, t)
        log.info("Carga: %s", carga)
        resultados = validar(bd, bruto, t)
        if any(r["estado"] == "ERROR" for r in resultados):
            raise RuntimeError("Fallaron validaciones de carga: " +
                               "; ".join(r["prueba"] for r in resultados if r["estado"] == "ERROR"))
        bd.commit()
        pd.DataFrame(resultados).to_csv(RAIZ / f"salidas/validaciones_{lote}.csv", index=False,
                                        encoding="utf-8-sig")
        log.info("ETL A completado · %s pruebas OK · registros=%s", len(resultados), len(bruto))
    except Exception:
        if bd is not None:
            bd.rollback()
        log.exception("Falló ETL A; cambios revertidos")
        sys.exit(1)
    finally:
        if bd is not None:
            bd.cerrar()


if __name__ == "__main__":
    main()
