"""
Prueba de reejecución del ETL B: ejecuta el proceso dos veces sobre una base
temporal y comprueba que la segunda corrida no duplica hechos ni miembros de
dimensión.

Uso:  python tests/prueba_reejecucion.py --fuente "data/raw/Datos proyecto BI v2.xlsx"
"""
import argparse
import sqlite3
import subprocess
import sys
import tempfile
from pathlib import Path

RAIZ = Path(__file__).resolve().parents[1]
TABLAS = ["fact_admisiones", "dim_tiempo", "dim_geografia", "dim_colegio", "dim_opcion",
          "dim_forma_ingreso", "dim_rango_nota", "dim_perfil_estudiante"]


def conteos(bd: Path) -> dict:
    with sqlite3.connect(bd) as con:
        return {t: con.execute(f"SELECT COUNT(*) FROM {t}").fetchone()[0] for t in TABLAS}


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--fuente", default=str(RAIZ / "data/raw/Datos proyecto BI v2.xlsx"))
    args = p.parse_args()
    with tempfile.TemporaryDirectory() as tmp:
        bd = Path(tmp) / "prueba.db"
        cmd = [sys.executable, str(RAIZ / "etl/etl_b_admitidos.py"), "--fuente", args.fuente,
               "--bd", str(bd)]
        resultados = []
        for corrida in (1, 2):
            subprocess.run(cmd, check=True, capture_output=True)
            resultados.append(conteos(bd))
            print(f"Corrida {corrida}: {resultados[-1]}")
        assert resultados[0] == resultados[1], "La segunda corrida cambió los conteos"
        assert resultados[0]["fact_admisiones"] == 742, "fact_admisiones debe tener 742 registros"
        print("OK · la reejecución no duplica hechos ni dimensiones")


if __name__ == "__main__":
    main()
