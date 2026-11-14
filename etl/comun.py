"""
Funciones comunes de los ETL A y B.

Este módulo debe ser el MISMO para ambos procesos: así las dimensiones
compartidas (dim_tiempo, dim_geografia, dim_colegio) se resuelven con la misma
llave natural y ninguna de las dos cargas crea miembros duplicados.
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
# Dimensiones: búsqueda o creación idempotente por llave natural
# --------------------------------------------------------------------------
def obtener_o_crear(con: sqlite3.Connection, tabla: str, columna_sk: str,
                    natural: dict, atributos: dict, cache: dict) -> tuple[int, bool]:
    """
    Devuelve (llave subrogada, creada?). Busca el miembro por su llave natural
    y solo lo inserta si no existe. Así, ejecutar el ETL dos veces —o ejecutar
    primero A y luego B— nunca duplica miembros de una dimensión.
    """
    llave_cache = (tabla, tuple(natural.items()))
    if llave_cache in cache:
        return cache[llave_cache], False
    where = " AND ".join(f"{c} = ?" for c in natural)
    fila = con.execute(f"SELECT {columna_sk} FROM {tabla} WHERE {where}",
                       tuple(natural.values())).fetchone()
    if fila:
        cache[llave_cache] = fila[0]
        return fila[0], False
    columnas = {**natural, **atributos}
    marcadores = ", ".join("?" for _ in columnas)
    cur = con.execute(
        f"INSERT INTO {tabla} ({', '.join(columnas)}) VALUES ({marcadores})",
        tuple(columnas.values()))
    cache[llave_cache] = cur.lastrowid
    return cur.lastrowid, True


# --------------------------------------------------------------------------
# Bitácora
# --------------------------------------------------------------------------
def ahora() -> str:
    return datetime.now().strftime("%Y-%m-%d %H:%M:%S")


def nuevo_lote(componente: str) -> str:
    return f"{componente}-{datetime.now().strftime('%Y%m%d-%H%M%S')}"
