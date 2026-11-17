# ETL B · Admitidos (Persona 6)

Proceso ETL del componente de **admitidos en primera y segunda opción** (742 registros) del
Proyecto 02 de TI-6900. Carga `bi.fact_admisiones` y resuelve las siete dimensiones del modelo,
siguiendo las convenciones del componente A: esquema `bi`, llaves `id_*` y PostgreSQL.

## Herramienta y requisitos
- Python 3.10 o superior: `pip install -r requirements.txt` (pandas, openpyxl, psycopg).
- Destino del proyecto: **PostgreSQL**, esquema `bi`.
- Alternativa para pruebas locales sin servidor: SQLite. El archivo se abre con el alias `bi`,
  de modo que el código y las consultas son los mismos.

## Estructura
```
etl/
  comun.py                  # normalización, conexión PostgreSQL/SQLite y carga idempotente de dimensiones (compartido con ETL A)
  reglas_dimensiones_b.py   # homologación de forma de ingreso, rango de nota, nota y perfil (dimensiones conformadas)
  etl_b_admitidos.py        # proceso principal: extracción, transformación, carga y validaciones
sql/
  postgresql/ddl_componente_b.sql              # dimensiones B, fact_admisiones, bitácora y validaciones
  postgresql/integrar_fk_fact_solicitudes.sql  # cierra las 4 FK pendientes de fact_solicitudes (ejecución conjunta)
  sqlite/ddl_componente_b.sql                  # misma estructura para pruebas locales
  consultas_validacion.sql                     # consultas para evidenciar la carga
tests/
  prueba_reejecucion.py     # ejecuta el ETL dos veces y verifica que no duplica
dashboard/
  medidas_pagina6.dax       # medidas K09-K12 de la página 6
data/raw/                   # aquí se coloca el Excel de origen (NO se versiona)
logs/  salidas/             # bitácoras y reportes de cada lote
```

## Ejecución
```bash
pip install -r requirements.txt
# copiar "Datos proyecto BI v2.xlsx" en data/raw/

# PostgreSQL del proyecto
export BI_DSN="postgresql://usuario:clave@host:5432/base"
python etl/etl_b_admitidos.py

# o SQLite local (si BI_DSN no está definida)
python etl/etl_b_admitidos.py --bd data/dw/dw_ati.db

python tests/prueba_reejecucion.py          # prueba de idempotencia (usa SQLite temporal)
```
Parámetros opcionales: `--fuente <ruta del Excel>`, `--bd <URL o archivo>`, `--ddl <ruta del DDL>`.

## Orden de la corrida integrada
1. DDL del componente A (Persona 3) y `sql/postgresql/ddl_componente_b.sql`.
2. ETL A y ETL B, en cualquier orden: ambos buscan cada miembro de dimensión por sus atributos
   naturales (sin distinguir tildes ni espacios) y solo insertan los que no existen.
3. `sql/postgresql/integrar_fk_fact_solicitudes.sql`, una sola vez.

## Salidas de cada lote (`id_lote = ETL_B-AAAAMMDD-HHMMSS`)
| Archivo | Contenido |
|---|---|
| `logs/<lote>.log` | Bitácora completa de la ejecución |
| `salidas/validaciones_<lote>.csv` | Resultado de las 27 validaciones (OK / ADVERTENCIA / ERROR) |
| `salidas/consistencia_agregada_<lote>.csv` | Celdas año-opción-categoría con más admitidos que solicitantes |
| `salidas/razon_agregada_<lote>.csv` | Razón admitidos/solicitudes por año y opción (solo celdas comparables) |
| tablas `bi.etl_bitacora` y `bi.etl_validacion` | La misma evidencia, consultable en la base |

Si alguna validación queda en **ERROR**, la transacción se revierte y no queda una carga parcial.

## Confidencialidad
El Excel de origen y las bases locales están excluidos por `.gitignore`
(memorando ati-199-2026). El atributo `Solicitud de Adecuación` no se carga al modelo.
Nunca suba la cadena de conexión con la contraseña: use la variable `BI_DSN`.

## Uso de IA
Este componente se desarrolló con apoyo de Claude (Anthropic) para la redacción del código y
la documentación; la ejecución, verificación y commits los realizó Sergio Mena Campos.
