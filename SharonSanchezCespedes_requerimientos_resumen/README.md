# Análisis del negocio, requerimientos, acta constitutiva y resumen ejecutivo

Responsable: Sharon María Sánchez Céspedes

## Contenido

| Carpeta o archivo | Descripción |
|---|---|
| `documentacion/Analisis_negocio_requerimientos_acta.docx` | Descripción de la organización, problema, justificación, usuarios de la información, acta constitutiva, objetivos, preguntas de negocio, indicadores K01 a K14, matriz de requerimientos, metodología Scrum y evidencias del levantamiento de requerimientos y de la carta de aceptación. |
| `documentacion/Pagina1_Resumen_ejecutivo.docx` | Documentación de la página 1 del dashboard: objetos visuales, medidas propias, análisis, recomendaciones y limitaciones. |
| `dashboard/medidas_pagina1.dax` | Expresiones DAX de las medidas K13 y K14, con sus valores de referencia. |

## Página 1 del dashboard: Resumen ejecutivo

- 4 tarjetas: total de registros de solicitudes, total de registros de admisiones, K13 y K14.
- 3 gráficos: solicitudes y admisiones por año (columnas y línea), admisiones por opción de carrera (anillo) y solicitudes y admisiones por región de planificación (barras).
- 2 segmentadores: Año y Opción.

La página está integrada en el archivo PBIP del grupo (`Proyecto02BI.pbip`).

## Medidas propias

| Medida | Tabla | Descripción |
|---|---|---|
| K13 Variación interanual solicitudes primera opción | fact_solicitudes | Cambio porcentual de las solicitudes en primera opción frente al año anterior. |
| K14 Variación interanual admisiones primera opción | fact_admisiones | Cambio porcentual de las admisiones en primera opción frente al año anterior. |

Ambas se calculan solo para la primera opción porque la segunda no tiene registros en todos los años. Las comparaciones son agregadas y no relacionan registros individuales.

## Confidencialidad

Esta carpeta no contiene datos de la Escuela. Los archivos de origen y los CSV no se suben al repositorio.
