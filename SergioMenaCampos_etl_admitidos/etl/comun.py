"""
Funciones comunes de los ETL A y B.

Este módulo debe ser el MISMO para ambos procesos: así las dimensiones
compartidas (bi.dim_tiempo, bi.dim_geografia, bi.dim_colegio) se resuelven
con la misma normalización y ninguna de las dos cargas crea miembros
duplicados.

Destino:
  - PostgreSQL (motor del proyecto): --bd "postgresql://usuario:clave@host:5432/base"
  - SQLite (pruebas locales):        --bd data/dw/dw_ati.db
    El archivo se adjunta con el alias «bi», de modo que las consultas usan
    bi.<tabla> en ambos motores.
"""
from __future__ import annotations

import re
import sqlite3
import unicodedata
from datetime import datetime

# --------------------------------------------------------------------------
# Normalización de texto
# --------------------------------------------------------------------------
VALORES_NO_ESPECIFICADO = {"NO ESPECIFICADO", "NO ESPECIFICADA", "N/E", "NE", ""}
VALORES_NO_APLICA = {"NO APLICA", "N/A", "NA"}


def limpiar(valor) -> str:
    """Quita espacios al inicio/final y colapsa espacios internos repetidos."""
    if valor is None:
        return ""
    texto = str(valor).replace(" ", " ")
    return re.sub(r"\s+", " ", texto).strip()


def clave(valor) -> str:
    """Forma canónica para comparar: mayúsculas, sin tildes y espacios colapsados."""
    texto = unicodedata.normalize("NFKD", limpiar(valor))
    texto = "".join(c for c in texto if not unicodedata.combining(c))
    return texto.upper()


def categoria_especial(valor) -> str | None:
    """Devuelve 'No especificado' o 'No aplica' si el valor es una categoría especial."""
    k = clave(valor)
    if k in VALORES_NO_ESPECIFICADO:
        return "No especificado"
    if k in VALORES_NO_APLICA:
        return "No aplica"
    return None


PROVINCIAS = {
    "SAN JOSE": "San José", "ALAJUELA": "Alajuela", "CARTAGO": "Cartago",
    "HEREDIA": "Heredia", "GUANACASTE": "Guanacaste", "PUNTARENAS": "Puntarenas",
    "LIMON": "Limón",
}


def normalizar_provincia(valor) -> str:
    return categoria_especial(valor) or PROVINCIAS.get(clave(valor), limpiar(valor))


def normalizar_generico(valor) -> str:
    """Conserva la escritura de origen, pero uniforma las categorías especiales."""
    return categoria_especial(valor) or limpiar(valor)


# --------------------------------------------------------------------------
# Conexión: PostgreSQL o SQLite con la misma interfaz
# --------------------------------------------------------------------------
class BD:
    def __init__(self, destino: str):
        self.destino = str(destino)
        if self.destino.startswith(("postgresql://", "postgres://")):
            import psycopg  # se instala con requirements.txt
            self.motor = "postgresql"
            self.con = psycopg.connect(self.destino)
        else:
            self.motor = "sqlite"
            self.con = sqlite3.connect(":memory:")
            self.con.execute("ATTACH DATABASE ? AS bi", (self.destino,))
            self.con.execute("PRAGMA foreign_keys = ON")

    def _sql(self, sql: str) -> str:
        return sql.replace("?", "%s") if self.motor == "postgresql" else sql

    def ejecutar(self, sql: str, params=()):
        cur = self.con.cursor()
        cur.execute(self._sql(sql), params)
        return cur

    def muchos(self, sql: str, filas):
        cur = self.con.cursor()
        cur.executemany(self._sql(sql), filas)
        return cur

    def script(self, texto: str):
        if self.motor == "sqlite":
            self.con.executescript(texto)
        else:
            self.con.execute(texto)
            self.con.commit()

    def commit(self):
        self.con.commit()

    def rollback(self):
        self.con.rollback()

    def cerrar(self):
        self.con.close()

    def nombre(self) -> str:
        return "PostgreSQL" if self.motor == "postgresql" else f"SQLite ({self.destino})"


# --------------------------------------------------------------------------
# Dimensiones: búsqueda o creación idempotente por atributos naturales
# --------------------------------------------------------------------------
class Dimensiones:
    """
    Resuelve llaves subrogadas sin duplicar miembros.

    Al primer uso de cada dimensión carga sus miembros existentes y los indexa
    por la forma canónica (clave) de sus atributos naturales. Así, un miembro
    cargado por el ETL A como «San Jose» y uno del ETL B como «San José» se
    reconocen como el mismo. Solo se inserta lo que no existe.
    """

    def __init__(self, bd: BD):
        self.bd = bd
        self.indices: dict[str, dict] = {}
        self.creados: dict[str, int] = {}

    def _indice(self, tabla, col_id, naturales):
        if tabla not in self.indices:
            filas = self.bd.ejecutar(
                f"SELECT {col_id}, {', '.join(naturales)} FROM bi.{tabla}").fetchall()
            self.indices[tabla] = {tuple(clave(v) for v in f[1:]): f[0] for f in filas}
            self.creados.setdefault(tabla, 0)
        return self.indices[tabla]

    def id(self, tabla: str, col_id: str, natural: dict, atributos: dict | None = None) -> int:
        idx = self._indice(tabla, col_id, list(natural))
        k = tuple(clave(v) for v in natural.values())
        if k in idx:
            return idx[k]
        columnas = {**natural, **(atributos or {})}
        marcadores = ", ".join("?" for _ in columnas)
        nuevo = self.bd.ejecutar(
            f"INSERT INTO bi.{tabla} ({', '.join(columnas)}) VALUES ({marcadores}) "
            f"RETURNING {col_id}", tuple(columnas.values())).fetchone()[0]
        idx[k] = nuevo
        self.creados[tabla] += 1
        return nuevo


# --------------------------------------------------------------------------
# Bitácora
# --------------------------------------------------------------------------
def ahora() -> str:
    return datetime.now().strftime("%Y-%m-%d %H:%M:%S")


def nuevo_lote(componente: str) -> str:
    return f"{componente}-{datetime.now().strftime('%Y%m%d-%H%M%S')}"
