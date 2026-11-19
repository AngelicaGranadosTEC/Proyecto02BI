# Persona 5 — ETL A: solicitudes ATI

## Objetivo
Extraer y consolidar las hojas `Solicitantes primera opción` y `Solicitantes segunda opción` del archivo oficial **Datos proyecto BI v2.xlsx**, transformar 4.854 registros y cargar `bi.fact_solicitudes` con siete claves dimensionales conformadas.

## Requisitos
- Python 3.11 o posterior.
- Dependencias: `python -m pip install -r SergioMenaCampos_etl_admitidos/requirements.txt` (ejecutar desde la raíz del repositorio).
- Deben existir en el repositorio las carpetas de Sergio y Pamela (se reutilizan sus módulos, sin copiar ni editar `comun.py`).
- Archivo Excel obtenido de la Escuela, **fuera de GitHub**; no subir datos sin autorización.

## Ejecución rápida: SQLite (recomendada para probar)
Desde la **raíz del repositorio** y con PowerShell:

```powershell
python -m pip install -r .\SergioMenaCampos_etl_admitidos\requirements.txt
python .\FabianGranadosRivera_etl_solicitantes\etl\etl_a_solicitantes.py --fuente "C:\RUTA\Datos proyecto BI v2.xlsx"
```

El comando genera automáticamente una base SQLite local en `FabianGranadosRivera_etl_solicitantes/data/dw/dw_ati.db`, junto con `logs/` y `salidas/`. SQLite reutiliza el DDL compartido de Sergio y un DDL de prueba específico de solicitudes. **No se modifica PostgreSQL** al hacer esta prueba.

Reejecutar el mismo comando verifica que las 4.854 solicitudes se reemplazan y **no se duplican**. No confundir igualdad de filas originales con duplicación de cargas: cada registro está identificado por `(hoja_origen, fila_origen)`.

## Ejecución integrada: PostgreSQL
La base del grupo debe tener ejecutados, en orden:
1. `AlexandraPamelaCruzSegura_modelo_solicitudes/sql/01_crear_modelo_v1.sql`.
2. `SergioMenaCampos_etl_admitidos/sql/postgresql/ddl_componente_b.sql` (dimensiones de Persona 4, etc.).
3. `AlexandraPamelaCruzSegura_modelo_solicitudes/sql/02_ajustar_fact_solicitudes_integracion_v2.sql` (exige `fact_solicitudes` vacía). 
4. Verificar los ajustes de claves foráneas que haya aplicado el equipo; este ETL usa las siete dimensiones.

**No ejecutar scripts DDL sobre una base compartida sin confirmar con el grupo**. El ETL no altera el esquema en PostgreSQL: espera que las tablas ya existan.

```powershell
python .\FabianGranadosRivera_etl_solicitantes\etl\etl_a_solicitantes.py --fuente "C:\RUTA\Datos proyecto BI v2.xlsx" --bd "postgresql://USUARIO:CLAVE@SERVIDOR:5432/BASE"
```

También admite `BI_DSN` como variable de entorno. No guardar credenciales en el repositorio ni en capturas.

## Reglas de transformación
- RT-A01: consolidación de ambas hojas, preservando opción, hoja y número de fila.
- RT-A02: normalización compartida de provincia y otras categorías (incluida GAM, sin inferencias geográficas); normalización de modalidad y financiamiento.
- RT-A03: homologación de forma de ingreso y perfiles según los catálogos de Sergio.
- RT-A04: conversión y clasificación de notas de admisión; conservar nota cero, no numéricos y valores especiales; excluir notas no válidas solo de promedios, **no de los hechos**.
- RT-A05: construcción de rangos de nota y orden mediante el catálogo compartido.
- RT-A06: claves subrogadas consistentes en siete dimensiones, sin crear miembros duplicados en reejecuciones.
- RT-A07: limpieza de Nota de IV Ciclo conservando el valor original; `NULL` para categorías no numéricas.
- RT-A08: carga idempotente por hoja de origen, manteniendo la granularidad de cada fila de solicitud.

## Validaciones
Dos controles por hoja, total de hechos, no duplicación por linaje, integridad de las siete claves y distribución por año. Genera un CSV de validaciones y un log por lote. Si una validación crítica falla, revierte la transacción.

Las dos hojas tienen, en la fuente oficial: primera opción = **2.725** filas; segunda opción = **2.129** filas; total = **4.854**.

## Notas de diseño
- No se intenta identificar estudiantes únicos; se cuentan registros de solicitud.
- Los años ausentes en una de las hojas no equivalen a cero solicitudes.
- No se publica `Solicitud de Adecuación`, por confidencialidad; se lee en el origen solo para el control de esquema.
- Se usan las mismas funciones `comun.py` y `reglas_dimensiones_b.py` que el ETL B para mantener consistencia dimensional.
- El ETL A carga `nota_admision_original`, `nota_admision`, `nota_iv_ciclo_original` y `nota_iv_ciclo` disponibles en el modelo de Pamela. La validez y el estado de la nota se calculan en el proceso para validación, pero no se almacenan en nuevas columnas de `fact_solicitudes` porque el SQL de Pamela no las define.

## Entregables
- `etl/etl_a_solicitantes.py`: código ejecutable.
- `sql/ddl_fact_solicitudes_sqlite.sql`: esquema SQLite de prueba.
- `documentacion/reglas_y_validaciones.md`: mapeos, reglas, resultados y límites.
- `tests/prueba_reejecucion.py`: prueba automática local.
- `logs/` y `salidas/` se crean al ejecutar, no se versionan automáticamente.

## Evidencia de carga en PostgreSQL local (19/11/2026)
Con los tres scripts SQL del modelo ya aplicados, se ejecutó ETL A con PostgreSQL local y la fuente v2. El proceso reportó **4.854 hechos**, **12 validaciones OK** y no se observaron errores. Las consultas directas confirmaron **4.854 registros en `bi.fact_solicitudes`** y las **siete dimensiones pobladas**. Consultar `documentacion/reglas_y_validaciones.md` y los PNG de `evidencias/`. Esto no equivale a una prueba de integración PostgreSQL con ETL B ni a validación de reejecución sobre PostgreSQL.
