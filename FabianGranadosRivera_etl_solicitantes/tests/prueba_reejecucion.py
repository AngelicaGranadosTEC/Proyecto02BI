"""Prueba local: ejecutar con --fuente a la ruta del Excel oficial."""
from __future__ import annotations
import argparse
import sqlite3
import subprocess
import sys
import tempfile
from pathlib import Path

RAIZ = Path(__file__).resolve().parents[1]
SCRIPT = RAIZ / 'etl/etl_a_solicitantes.py'


def main():
    p = argparse.ArgumentParser()
    p.add_argument('--fuente', type=Path, required=True)
    args = p.parse_args()
    with tempfile.TemporaryDirectory() as d:
        bd = Path(d) / 'test.db'
        for numero in (1, 2):
            subprocess.run([sys.executable, str(SCRIPT), '--fuente', str(args.fuente), '--bd', str(bd)],
                           check=True, capture_output=True, text=True)
            con = sqlite3.connect(bd)
            total = con.execute('SELECT COUNT(*) FROM fact_solicitudes').fetchone()[0]
            duplicados = con.execute('SELECT COUNT(*) FROM (SELECT hoja_origen,fila_origen FROM fact_solicitudes '
                                     'GROUP BY hoja_origen,fila_origen HAVING COUNT(*)>1)').fetchone()[0]
            con.close()
            assert total == 4854, (numero, total)
            assert duplicados == 0, (numero, duplicados)
            print(f'Ejecución {numero}: {total} registros; {duplicados} duplicados de origen')
    print('PRUEBA OK: reejecución idempotente')


if __name__ == '__main__':
    main()
