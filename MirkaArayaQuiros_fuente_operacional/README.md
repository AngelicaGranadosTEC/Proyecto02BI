# Persona 2 — Fuente operacional y calidad de datos

**Proyecto 02 de BI — Escuela ATI (TEC)**

Esta carpeta reúne los artefactos técnicos de la parte realizada por la estudiante que son distintos del informe maestro del grupo

## Archivos
- `diagramas/01_diagrama_fuentes.png`: El diagrama describe las fuentes disponibles, no el esquema ER original de la OPI
- `diagramas/02_trazabilidad_propuesta.png`: flujo conceptual entre fuentes, ETL A/B y hechos dimensionales. Es una propuesta preliminar; no equivale a una prueba de ejecución ni a una certificación de integración.
- `evidencias/inventario_campos_P2.csv`: campos y tipos inferidos del Excel v2 (metadatos, sin registros individuales)
- `evidencias/resumen_calidad_P2.csv`: recuentos agregados de valores especiales y filas idénticas en las cuatro hojas (no identifica personas únicas)

## Fuente usada
`Datos proyecto BI v2.xlsx` — años disponibles de 2020 a 2026

## Relación con el informe
Los diagramas y hallazgos se describen en "Descripción de la fuente operacional" y "Diagrama del modelo operacional o transaccional de origen" del informe grupal.

**Precauciones:** no deduplicar registros sin identificador que lo pruebe; los años no presentes deben visualizarse como «sin datos» y no como conteo 0; solicitantes y admitidos no tienen una llave individual compartida.
