# ETL B · Admitidos (Persona 6)

Proceso ETL del componente de **admitidos en primera y segunda opción** (742 registros) del
Proyecto 02 de TI-6900. Carga `fact_admisiones` y resuelve las siete dimensiones del modelo.

## Herramienta y requisitos
- Python 3.10 o superior, con `pandas` y `openpyxl` (`pip install -r requirements.txt`).
- Almacenamiento de referencia: SQLite (`data/dw/dw_ati.db`), sin instalación adicional.
  El DDL usa SQL estándar; si el grupo adopta PostgreSQL solo cambia la conexión.

## Estructura
```
etl/
  comun.py                  # normalización y carga idempotente de dimensiones (compartido con ETL A)
  reglas_dimensiones_b.py   # homologación de forma de ingreso, rango de nota, nota y perfil (conformadas)
  etl_b_admitidos.py        # proceso principal: extracción, transformación, carga y validaciones
sql/
  ddl_modelo.sql            # tablas que alimenta el ETL B + bitácora y validaciones
  consultas_validacion.sql  # consultas para evidenciar la carga
tests/
  prueba_reejecucion.py     # ejecuta el ETL dos veces y verifica que no duplica
dashboard/
  medidas_pagina6.dax       # medidas de la página 6 (pregunta exploratoria)
data/raw/                   # aquí se coloca el Excel de origen (NO se versiona)
logs/  salidas/             # bitácoras y reportes de cada lote (se generan al ejecutar)
```

## Ejecución
```bash
pip install -r requirements.txt
# copiar "Datos proyecto BI v2.xlsx" en data/raw/
python etl/etl_b_admitidos.py                 # usa las rutas por defecto
python tests/prueba_reejecucion.py            # prueba de idempotencia
```
Parámetros opcionales: `--fuente <ruta del Excel>`, `--bd <ruta de la base>`, `--ddl <ruta del DDL>`.

## Orden de ejecución con el ETL A
Ambos procesos usan `obtener_o_crear()` por llave natural, de modo que el orden no genera
miembros duplicados. Orden recomendado para la corrida integrada: DDL → ETL A → ETL B.

## Salidas de cada lote (`id_lote = ETL_B-AAAAMMDD-HHMMSS`)
| Archivo | Contenido |
|---|---|
| `logs/<lote>.log` | Bitácora completa de la ejecución |
| `salidas/validaciones_<lote>.csv` | Resultado de las 27 validaciones (OK / ADVERTENCIA / ERROR) |
| `salidas/consistencia_agregada_<lote>.csv` | Celdas año-opción-categoría con más admitidos que solicitantes |
| `salidas/razon_agregada_<lote>.csv` | Razón admitidos/solicitudes por año y opción (solo celdas comparables) |
| tablas `etl_bitacora` y `etl_validacion` | La misma evidencia, consultable en la base |

Si alguna validación queda en **ERROR**, la transacción se revierte y no queda una carga parcial.

## Confidencialidad
El Excel de origen y la base generada están excluidos por `.gitignore`
(memorando ati-199-2026). El atributo `Solicitud de Adecuación` no se carga al modelo.
