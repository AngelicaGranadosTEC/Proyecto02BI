# Documentación del modelo dimensional — Persona 4

## 6. Diseño del modelo dimensional — componente de admisiones
El componente de admisiones corresponde a la segunda parte del modelo dimensional orientado al análisis de solicitudes y admisiones a la carrera de Administración de Tecnologías de Información. Se utiliza un esquema estrella cuyo centro es la tabla de hechos `bi.fact_admisiones`, relacionada mediante llaves subrogadas con las dimensiones de tiempo, geografía, colegio, opción, perfil del estudiante, forma de ingreso y rango de nota.

La fuente operacional corresponde al archivo institucional `Datos proyecto BI v2.xlsx`, específicamente a las hojas de admitidos de primera y segunda opción. La opción de carrera se determina a partir de la hoja de origen. La tabla de hechos conserva información de trazabilidad mediante el nombre de la hoja, el número de fila de procedencia y la fecha de carga.

El componente reutiliza las dimensiones conformadas `bi.dim_tiempo`, `bi.dim_geografia` y `bi.dim_colegio`, definidas en el componente de solicitudes. Adicionalmente, incorpora las dimensiones `bi.dim_opcion`, `bi.dim_perfil_estudiante`, `bi.dim_forma_ingreso` y `bi.dim_rango_nota`, correspondientes al componente de admisiones.

Las tablas `fact_solicitudes` y `fact_admisiones` no se relacionan directamente entre sí. Ambas comparten dimensiones conformadas para permitir análisis comparables sin asumir una correspondencia individual entre solicitantes y admitidos, ya que la fuente no contiene una llave común que permita emparejar personas.

## 6.1. Granularidad, hechos y medidas
La granularidad de `bi.fact_admisiones` es un registro por cada fila de admisión disponible en las hojas de admitidos de primera o segunda opción. Por tanto, cada fila representa un registro de admisión y no necesariamente una persona única.

La llave primaria `id_admision` es una llave subrogada técnica generada por PostgreSQL. No representa un identificador institucional de la persona.

La medida aditiva principal es `cantidad_admisiones`, con valor 1 por fila. Su suma permite contar registros de admisión bajo los filtros dimensionales seleccionados. Este resultado debe interpretarse como cantidad de registros y no como cantidad de personas únicas.

El campo `nota_admision` se conserva como medida numérica cuando su conversión es válida. Debido a que la nota no es una medida aditiva, no corresponde sumarla como indicador. Puede utilizarse para cálculos como promedio, mínimo, máximo, mediana y distribución, siempre que se documenten los criterios utilizados para valores numéricos, ceros y categorías no numéricas.

También se conserva `nota_admision_original` como texto para mantener el valor tal como aparece en la fuente y distinguir correctamente valores numéricos de categorías como `No Aplica` o `No Especificado`.

La combinación de `hoja_origen` y `fila_origen` permite identificar la ubicación del registro dentro del archivo fuente y funciona como mecanismo de trazabilidad y control de duplicación de carga.

## 6.2. Dimensiones, jerarquías y relaciones

### Dimensión de opción (`dim_opcion`)
La dimensión `dim_opcion` identifica si el registro corresponde a primera o segunda opción de carrera. Su granularidad es una fila por categoría de opción.

Atributos definidos:

- `id_opcion`: llave subrogada de la dimensión.
- `opcion`: categoría de opción de carrera, con valores `Primera` o `Segunda`.

La opción se determina a partir de la hoja de origen. Esta dimensión se comparte entre `fact_solicitudes` y `fact_admisiones`.

No se define una jerarquía adicional, ya que la fuente únicamente distingue dos categorías de opción.

### Dimensión de perfil del estudiante (`dim_perfil_estudiante`)
La dimensión `dim_perfil_estudiante` agrupa características demográficas y académicas básicas disponibles en la fuente sin identificar individualmente a una persona.

Atributos definidos:

- `id_perfil_estudiante`: llave subrogada de la dimensión.
- `rango_edad`: rango de edad registrado.
- `nacionalidad`: nacionalidad registrada.
- `tipo_estudiante`: tipo de estudiante registrado.
- `tipo_diploma_secundaria`: tipo de diploma de secundaria registrado.

La granularidad corresponde a una combinación única de `rango_edad`, `nacionalidad`, `tipo_estudiante` y `tipo_diploma_secundaria`. La combinación de estos cuatro atributos identifica un miembro dimensional.

No se establece una jerarquía entre estos atributos, ya que representan características descriptivas independientes del perfil.

### Dimensión de forma de ingreso (`dim_forma_ingreso`)
La dimensión `dim_forma_ingreso` representa la modalidad o forma de ingreso registrada en la fuente.

Atributos definidos:

- `id_forma_ingreso`: llave subrogada de la dimensión.
- `forma_ingreso`: categoría de forma de ingreso.

La granularidad es una fila por categoría única de forma de ingreso. Esta dimensión se comparte entre los componentes de solicitudes y admisiones cuando el atributo se encuentra disponible.

No se define una jerarquía adicional porque la fuente presenta la forma de ingreso como una clasificación de un único nivel.

### Dimensión de rango de nota (`dim_rango_nota`)
La dimensión `dim_rango_nota` clasifica los registros según el rango de la nota de admisión informado en la fuente.

Atributos definidos:

- `id_rango_nota`: llave subrogada de la dimensión.
- `rango_nota`: categoría del rango de nota de admisión.

La granularidad es una fila por rango o categoría única de nota. Esta dimensión permite analizar distribuciones de notas sin sustituir el valor numérico almacenado en la tabla de hechos.

Las categorías `No Aplica` y `No Especificado`, cuando están presentes, se conservan como miembros diferentes. Un valor numérico de cero tampoco se equipara automáticamente con estas categorías.

No se define una jerarquía adicional porque los rangos constituyen una clasificación de un solo nivel.

### Dimensiones conformadas reutilizadas
`fact_admisiones` reutiliza las tres dimensiones conformadas definidas en el componente de solicitudes:

- `dim_tiempo`: permite analizar los registros por año disponible.
- `dim_geografia`: permite analizar la procedencia geográfica mediante los atributos definidos en el componente A.
- `dim_colegio`: permite analizar los registros según modalidad y tipo de financiamiento del colegio de procedencia.

Estas dimensiones reutilizan las mismas estructuras, llaves y reglas establecidas para el componente de solicitudes, evitando crear dimensiones paralelas o incompatibles.

## 6.3. Estructura implementada de `fact_admisiones`
La tabla de hechos fue implementada con los siguientes campos:

| Campo | Tipo | Nulo | Clave / restricción | Descripción |
|---|---|---|---|---|
| `id_admision` | BIGINT | No | PK; IDENTITY | Identificador técnico del registro de admisión en el Data Warehouse. |
| `id_tiempo` | BIGINT | No | FK → `dim_tiempo` | Referencia al año del registro. |
| `id_geografia` | BIGINT | No | FK → `dim_geografia` | Referencia al miembro geográfico. |
| `id_colegio` | BIGINT | No | FK → `dim_colegio` | Referencia al miembro de colegio. |
| `id_opcion` | BIGINT | No | FK → `dim_opcion` | Referencia a primera o segunda opción. |
| `id_perfil_estudiante` | BIGINT | No | FK → `dim_perfil_estudiante` | Referencia a la combinación de características del perfil. |
| `id_forma_ingreso` | BIGINT | No | FK → `dim_forma_ingreso` | Referencia a la forma de ingreso. |
| `id_rango_nota` | BIGINT | No | FK → `dim_rango_nota` | Referencia al rango de nota de admisión. |
| `cantidad_admisiones` | SMALLINT | No | DEFAULT 1; CHECK = 1 | Medida aditiva unitaria para contar registros de admisión. |
| `nota_admision_original` | TEXT | Sí | — | Valor original de la nota tal como aparece en la fuente. |
| `nota_admision` | NUMERIC(8,2) | Sí | — | Valor numérico de la nota cuando la conversión es válida. |
| `hoja_origen` | TEXT | No | Parte de UNIQUE compuesta | Nombre de la hoja de procedencia. |
| `fila_origen` | INTEGER | No | CHECK >= 2; parte de UNIQUE compuesta | Número de fila del archivo fuente. |
| `fecha_carga` | TIMESTAMPTZ | No | DEFAULT CURRENT_TIMESTAMP | Fecha y hora de inserción en el Data Warehouse. |

## 6.4. Reglas de negocio y decisiones técnicas
1. Se utiliza exclusivamente `Datos proyecto BI v2.xlsx` como fuente de trabajo para evitar combinar extracciones con diferente cobertura.
2. Una fila de `fact_admisiones` representa un registro de admisión disponible y no necesariamente una persona única.
3. La opción de carrera se determina a partir de la hoja de origen y se almacena mediante `dim_opcion`.
4. `cantidad_admisiones` se registra con valor 1 por fila fuente. Su suma cuenta registros de admisión y no personas únicas.
5. Se conserva el valor original de la nota de admisión como texto y se almacena una versión numérica únicamente cuando la conversión es válida.
6. Los valores numéricos de cero, `No Aplica` y `No Especificado` se mantienen diferenciados. El cero no se convierte automáticamente en nulo.
7. Los años o combinaciones de opción sin registros se interpretan como ausencia de datos y no automáticamente como un valor de cero.
8. No se eliminan automáticamente filas idénticas únicamente por coincidir en sus atributos, ya que no existe un identificador individual que permita confirmar que representan a la misma persona.
9. Se conserva la trazabilidad mediante `hoja_origen`, `fila_origen` y `fecha_carga`. La combinación de hoja y fila debe ser única dentro de la tabla de hechos.
10. No se crea una relación directa entre `fact_solicitudes` y `fact_admisiones`. La comparación entre ambos procesos se realiza mediante las dimensiones conformadas.
11. No se incorpora `Nota de IV Ciclo` a `fact_admisiones`, ya que este atributo no está disponible en las hojas de admitidos.
12. El atributo `Solicitud de Adecuación` no se incorpora al diseño dimensional de este componente debido a su carácter sensible y a que no forma parte de las dimensiones aprobadas.
13. Las dimensiones utilizan llaves subrogadas `BIGINT GENERATED ALWAYS AS IDENTITY`.
14. Los atributos categóricos se almacenan como `TEXT` para conservar las categorías disponibles en la fuente.
15. Se utilizan restricciones `UNIQUE`, `CHECK`, claves primarias y claves foráneas cuando la regla está sustentada por el diseño.

## 6.5. Integración con el componente de solicitudes
Las dimensiones `dim_tiempo`, `dim_geografia` y `dim_colegio` se reutilizan directamente desde el componente A.

Las dimensiones `dim_opcion`, `dim_perfil_estudiante`, `dim_forma_ingreso` y `dim_rango_nota` también se encuentran integradas con ambas tablas de hechos. `fact_solicitudes` contiene las llaves foráneas `id_opcion`, `id_perfil_estudiante`, `id_forma_ingreso` e `id_rango_nota`, relacionadas físicamente con las dimensiones correspondientes.

De esta forma, `fact_solicitudes` y `fact_admisiones` poseen relaciones con las mismas siete dimensiones del modelo, manteniendo nombres y tipos de datos compatibles para las llaves foráneas y evitando duplicar dimensiones con el mismo significado.

La integración no establece una relación directa entre ambas tablas de hechos. Los análisis comparativos deben realizarse mediante las dimensiones conformadas compartidas.

## 6.6. Estado de implementación y validación física
El componente dimensional de admisiones fue implementado físicamente en PostgreSQL dentro del esquema `bi`.

Mediante el script `03_crear_modelo_admisiones_v1.sql` se crearon las dimensiones `dim_opcion`, `dim_perfil_estudiante`, `dim_forma_ingreso` y `dim_rango_nota`, además de la tabla de hechos `fact_admisiones`, sus restricciones, índices y relaciones con las dimensiones del modelo.

Posteriormente, mediante el script `04_integrar_fact_solicitudes_fks_v1.sql`, se completaron las relaciones físicas pendientes entre `fact_solicitudes` y las cuatro dimensiones incorporadas por el componente de admisiones.

La validación realizada en PostgreSQL confirmó la existencia de nueve tablas dentro del esquema `bi`:

- `dim_colegio`
- `dim_forma_ingreso`
- `dim_geografia`
- `dim_opcion`
- `dim_perfil_estudiante`
- `dim_rango_nota`
- `dim_tiempo`
- `fact_admisiones`
- `fact_solicitudes`

También se verificaron catorce restricciones de llave foránea en total. `fact_admisiones` posee siete relaciones hacia las siete dimensiones del modelo y `fact_solicitudes` posee igualmente siete relaciones hacia las mismas dimensiones.

Al momento de realizar la validación estructural, `dim_opcion`, `dim_perfil_estudiante`, `dim_forma_ingreso`, `dim_rango_nota` y `fact_admisiones` presentaban cero registros. Este resultado es esperado, ya que la carga de los datos mediante el proceso ETL corresponde al componente responsable del ETL de admitidos y no forma parte de la implementación física realizada en esta sección.

Por tanto, la validación efectuada comprueba la creación y consistencia estructural del modelo dimensional, pero no constituye evidencia de ejecución del proceso ETL ni de carga de los 742 registros de admitidos.

## 6.7. Evidencias de implementación
Como evidencia de la implementación física del componente se conservan los scripts SQL utilizados y los resultados obtenidos durante las consultas de validación.

Las evidencias principales corresponden a:

1. Ejecución satisfactoria de `03_crear_modelo_admisiones_v1.sql`, con creación de las cuatro dimensiones, `fact_admisiones`, restricciones e índices.
2. Consulta de `information_schema.tables` que confirma la existencia de las nueve tablas del esquema `bi`.
3. Consulta de `pg_constraint` que confirma las siete llaves foráneas de `fact_admisiones`.
4. Ejecución satisfactoria de `04_integrar_fact_solicitudes_fks_v1.sql`.
5. Consulta final de `pg_constraint` que confirma un total de catorce llaves foráneas: siete en `fact_admisiones` y siete en `fact_solicitudes`.
6. Consulta de conteos que confirma que las tablas correspondientes al componente de admisiones se encuentran inicialmente vacías antes de la ejecución del proceso ETL.

El diagrama dimensional del componente se mantiene en un archivo Mermaid independiente para facilitar su visualización y actualización junto con los demás artefactos técnicos del repositorio.