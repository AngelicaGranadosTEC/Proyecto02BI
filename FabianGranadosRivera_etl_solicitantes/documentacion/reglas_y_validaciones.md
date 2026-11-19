# Documentación ETL A — Persona 5

## Fuente y granularidad
Fuente: `Datos proyecto BI v2.xlsx`, hojas `Solicitantes primera opción` (2.725 filas) y `Solicitantes segunda opción` (2.129 filas), total 4.854. Cada fila de salida equivale a un **registro** de solicitud original. No existe clave personal única. La trazabilidad se preserva con `(hoja_origen, fila_origen)`.

## Reglas: origen → destino

| Campo destino | Campo origen | Regla aplicada | Comentarios |
|---|---|---|---|
| fact_solicitudes.hoja_origen, fila_origen | Nombre hoja y posición fila Excel | RT-A01: preservar el origen y asignar el número de fila Excel | Soporta reejecución e identifica cada registro, aunque tenga atributos idénticos a otro |
| dim_opcion.codigo_opcion / opcion | Hoja de solicitantes | RT-A01: primera opción → 1, segunda → 2 | Miembros compartidos con ETL B |
| dim_geografia.provincia | Provincia de Procedencia | RT-A02: mayúsculas/acentos/espacios → nombre oficial desde `normalizar_provincia` | Usa funciones compartidas de Sergio |
| dim_geografia.* | Zona de Residencia, Región de Planificación, Cantón, Distrito, Nivel de Desarrollo Social, Zona GAM | RT-A02: homologar vacíos, No aplica/No especificado; conservar demás categorías | No inferir GAM ni cambiar años sin datos a cero |
| dim_colegio.modalidad, tipo_financiamiento | Modalidad del Colegio, Tipo de Financiamiento del Colegio | RT-A02: homologación de categorías especiales y espacios | Permite indicadores PN4, K07/K08 |
| dim_forma_ingreso.* | Forma de Ingreso | RT-A03: homologar vía de ingreso, clase de vía y exigencia de nota | Reutiliza `homologar_forma_ingreso` |
| dim_perfil_estudiante.* | Tipo de Estudiante, Rango de Edad, Nacionalidad, Tipo de Diploma de Secundaria | RT-A03: normalización y categorías derivadas | No cargar Solicitud de Adecuación en dimensiones |
| fact_solicitudes.nota_admision_original, nota_admision | Nota de Admisión | RT-A04: conservar texto; convertir coma/punto; `NULL` si es categoría especial; conservar cero numérico | Nota válida para promedio solo si nota >0, en rango y vía puntaje |
| dim_rango_nota.* | Rango de Nota de Admisión | RT-A05: convertir intervalo en límites numéricos, orden y tipo | Misma clasificación del ETL B |
| fact_solicitudes.nota_iv_ciclo_original, nota_iv_ciclo | Nota de IV Ciclo | RT-A07: conservar original y convertir a número cuando sea posible | Ausente en tablas de admitidos |
| fact_solicitudes.id_* (siete claves) | Atributos operacionales de tiempo, geografía, colegio, opción, perfil, forma y rango | RT-A06: buscar o crear miembro dimensional por atributos naturales | Reutiliza `Dimensiones` de Sergio y mantiene claves subrogadas |
| fact_solicitudes (filas) | Dos hojas de solicitantes | RT-A08: sustituir solamente las filas de estas hojas antes de insertar; misma transacción | Las cargas repetidas no duplican hechos; no borra las filas de admisiones |

## Resultados de prueba local (19 de noviembre de 2026)
- Python 3, SQLite con esquema `bi` adjunto, fuente Excel v2 original.
- Primera ejecución: 4.854 filas insertadas en `fact_solicitudes` (2.725 + 2.129), **12 validaciones OK**.
- Segunda ejecución: reemplazó las 4.854 filas anteriores, **sin aumentar el total**, y **no creó miembros dimensionales adicionales**.
- Nota de admisión con valor cero: **636 registros**. Nota de admisión no numérica o categórica: **166 registros**. Ambos grupos se conservan para conteos.
- Prueba de integración con el ETL B en la misma SQLite: completó su carga y reportó cuatro advertencias de consistencia agregada en los datos; no alteramos los valores originales.

## Validación adicional en PostgreSQL local (19 de noviembre de 2026)
Se creó una base de pruebas **local** `dw_proyecto02_bi_tec` y se aplicaron los SQL del repositorio en este orden:
1. `AlexandraPamelaCruzSegura_modelo_solicitudes/sql/01_crear_modelo_v1.sql`.
2. `SergioMenaCampos_etl_admitidos/sql/postgresql/ddl_componente_b.sql`.
3. `AlexandraPamelaCruzSegura_modelo_solicitudes/sql/02_ajustar_fact_solicitudes_integracion_v2.sql`.

Se ejecutó el ETL A con conexión PostgreSQL y `Datos proyecto BI v2.xlsx`. La bitácora reportó 4.854 registros insertados (2.725 de primera opción y 2.129 de segunda), 12 validaciones OK y ninguna excepción. Se identificaron 636 notas de admisión con valor cero y 166 notas no numéricas; estas se conservaron como registros y se trataron según las reglas documentadas. Posteriormente se ejecutaron consultas directas en pgAdmin para verificar los recuentos:

| Tabla | Registros |
|---|---:|
| `bi.fact_solicitudes` | 4.854 |
| `bi.dim_tiempo` | 7 |
| `bi.dim_geografia` | 445 |
| `bi.dim_colegio` | 24 |
| `bi.dim_opcion` | 2 |
| `bi.dim_perfil_estudiante` | 58 |
| `bi.dim_forma_ingreso` | 4 |
| `bi.dim_rango_nota` | 11 |

Evidencia visual: `evidencias/postgres_fact_solicitudes_4854.png` y `evidencias/postgres_siete_dimensiones.png`. Estas capturas contienen únicamente consultas y resultados, no credenciales de conexión.

## Alcance de las pruebas y pendientes
- **Completado:** SQLite local, repetición en SQLite sin duplicar hechos, carga y conteos en PostgreSQL local usando los SQL de integración.
- **Pendiente:** prueba de reejecución en PostgreSQL y prueba integrada con el ETL B de Sergio en la **misma instancia PostgreSQL**. La integración con ETL B se probó previamente en SQLite; no confundir ambas verificaciones.
- El dashboard (página 5) y sus medidas de Power BI se realizarán después.
- Los resultados de validación pertenecen al Excel recibido; si el equipo cambió de fuente, repetir pruebas.
- No publicar el Excel ni la base local en un repositorio público sin autorización de la Escuela.
