# Página 02 — Evolución histórica de solicitudes y admisiones

**Proyecto:** Inteligencia de Negocios, Escuela de ATI, TEC.  
**Responsable:**  Mirka Araya Quirós.  
**Pregunta PN1:** ¿Cómo ha evolucionado la cantidad de registros de solicitudes y admisiones a ATI según el año y la opción de carrera?

## Contenido de este aporte
- `medidas_pagina02.dax`: fórmulas de las medidas numéricas de solicitudes y admisiones, más una medida de texto utilizada opcionalmente para mostrar el total exacto en una tarjeta.
- `validaciones_pagina02.md`: controles de calidad aplicados a la página y resultados agregados que se espera observar si los ETL y filtros se mantienen iguales.
- `captura_pagina02_final.png`: captura de la página de Power BI ya terminada y validada, con nota metodológica y matriz expandida.

## Fuente y modelo
La página se desarrolló en Power BI Desktop sobre un modelo dimensional alimentado con los ETL A y B del proyecto. La carga local para Power BI provino de las nueve tablas dimensionales exportadas a CSV a partir de la ejecución conjunta de ambos ETL. Las tablas de hechos usadas son `fact_solicitudes` y `fact_admisiones`; se filtran por `dim_tiempo` y `dim_opcion`.

No se enlazan individualmente las solicitudes con las admisiones porque no existe un identificador compartido en los datos de origen. Los totales representan **registros**, no necesariamente personas únicas.

## Objetos visuales
1. Tarjeta de total de registros de solicitudes.
2. Tarjeta de total de registros de admisiones.
3. Gráfico de columnas agrupadas: solicitudes por año y opción.
4. Gráfico de columnas agrupadas: admisiones por año y opción.
5. Matriz de detalle por año y opción de carrera.
6. Segmentador de año para filtrar los anteriores.

## Reproducción
1. Obtener una **copia autorizada** del `.pbix` base (no está publicado en este repositorio por contener datos institucionales importados).
2. Comprobar las nueve tablas y sus relaciones en el modelo. Usar `dim_tiempo[anio]` para el año y `dim_opcion[codigo_opcion]` para filtrar la opción.
3. Crear las medidas numéricas a partir de `medidas_pagina02.dax` (una fórmula a la vez) si aún no existen en el `.pbix`.
4. Construir o copiar los visuales de la página 02 en un archivo con **el mismo esquema de tablas, campos y medidas**.
5. Aplicar los controles de `validaciones_pagina02.md` antes de integrar o entregar.
6. Para refrescar desde archivos CSV en otra computadora, actualizar las rutas de origen en Power Query; abrir el `.pbix` con los datos importados no requiere acceder automáticamente a la ruta original, pero la actualización sí puede requerirla.

## Confidencialidad e integración
No subir aquí el Excel institucional, la base SQLite, los CSV con registros ni el `.pbix` sin autorización expresa. Los archivos técnicos de este aporte incluyen definiciones y validaciones agregadas, no registros individuales. El `.pbix` debe compartirse mediante un medio privado con acceso solo al equipo autorizado. Para evitar conflictos de edición, conservar una versión maestra y coordinar la integración de páginas en ella.
