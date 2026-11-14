# Documentación del modelo dimensional — Persona 3

## 6. Diseño del modelo dimensional — componente de solicitudes

El componente de solicitudes se diseñó como parte de un modelo dimensional orientado al análisis histórico de la demanda de ingreso a la carrera de Administración de Tecnologías de Información. Se utiliza un esquema estrella cuyo centro es la tabla de hechos bi.fact_solicitudes, relacionada mediante llaves subrogadas con las dimensiones de tiempo, geografía, colegio, opción, perfil del estudiante, forma de ingreso y rango de nota.

La fuente operacional seleccionada para este componente es el archivo institucional “Datos proyecto BI v2.xlsx”, específicamente las hojas de solicitantes de primera y segunda opción. La opción de carrera se deriva del nombre de la hoja de origen. La tabla de hechos conserva la trazabilidad mediante el nombre de la hoja y el número de fila del archivo fuente.

La implementación física realizada por Persona 3 comprende las dimensiones bi.dim_tiempo, bi.dim_geografia y bi.dim_colegio, además de la tabla bi.fact_solicitudes. Las dimensiones dim_opcion, dim_perfil_estudiante, dim_forma_ingreso y dim_rango_nota corresponden al componente de Persona 4. Sus claves se encuentran previstas en fact_solicitudes, pero sus restricciones FOREIGN KEY se incorporarán cuando las tablas dimensionales respectivas existan físicamente.

Las dimensiones de tiempo, geografía y colegio se diseñaron como dimensiones conformadas, de modo que puedan ser reutilizadas por los componentes de solicitudes y admisiones. No se establece una relación individual entre solicitudes y admisiones, debido a que la fuente no contiene un identificador común que permita emparejar personas entre ambos conjuntos.

## 6.1. Granularidad, hechos y medidas

La granularidad de bi.fact_solicitudes es un registro por cada fila de solicitud disponible en las hojas de solicitantes de primera o segunda opción del archivo fuente. Por tanto, cada fila representa un registro de solicitud y no necesariamente una persona única. La llave primaria id_solicitud es una llave subrogada técnica generada por PostgreSQL; no representa un identificador institucional de la persona.

La medida aditiva principal es cantidad_solicitudes, cuyo valor es 1 por fila. La suma de esta medida permite contar registros de solicitud bajo los filtros dimensionales seleccionados. No debe interpretarse como un conteo de personas únicas.

Los campos nota_admision y nota_iv_ciclo se conservan como medidas numéricas cuando su conversión es válida. La nota_iv_ciclo solo está disponible en las hojas de solicitantes. Para ambas notas se conserva también el valor original como texto, con el fin de mantener la trazabilidad y distinguir valores numéricos de categorías como “No Aplica” o “No Especificado”. Las notas son medidas no aditivas: no corresponde sumarlas para obtener un indicador. Los promedios, medianas y distribuciones deben definirse con reglas de inclusión documentadas, especialmente para los valores cero y las categorías no numéricas.

La combinación hoja_origen y fila_origen identifica la ubicación del registro dentro del archivo de entrada y está protegida mediante una restricción UNIQUE compuesta. fila_origen debe ser igual o mayor que 2, considerando que la primera fila contiene encabezados.

## 6.2. Dimensiones, jerarquías y relaciones

Dimensión de tiempo (dim_tiempo). Contiene el año calendario de la observación. La fuente seleccionada aporta el año, pero no una fecha completa ni atributos de mes, trimestre o día. Por esta razón, la dimensión se mantiene al nivel anual y no se inventan niveles temporales que la fuente no proporciona. El atributo anio es único y se valida dentro del intervalo técnico definido en la base de datos.

Dimensión geográfica (dim_geografia). Integra zona de residencia, región de planificación, provincia, cantón, distrito, nivel de desarrollo social y zona GAM. Estos atributos permiten analizar la distribución territorial de las solicitudes. Como ruta de exploración analítica se puede utilizar región de planificación, provincia, cantón y distrito; esta ruta es descriptiva y debe validarse con catálogos institucionales antes de asumir que todas las relaciones territoriales son jerárquicamente consistentes. La combinación de los siete atributos identifica un miembro de la dimensión. No se infiere la zona GAM a partir de provincia, cantón o distrito, ni se calcula un índice numérico de desarrollo social que no esté presente en la fuente.

Dimensión de colegio (dim_colegio). Describe el colegio de procedencia mediante modalidad y tipo de financiamiento. La combinación de ambos atributos identifica un miembro dimensional. No se agrega una jerarquía adicional porque la fuente disponible no aporta niveles organizativos superiores para esta clasificación.

Relaciones. Cada registro de fact_solicitudes referencia un miembro de dim_tiempo, dim_geografia y dim_colegio. El diseño integrado contempla además una referencia a cada una de las cuatro dimensiones asignadas a Persona 4: dim_opcion, dim_perfil_estudiante, dim_forma_ingreso y dim_rango_nota. En la base de datos verificada están implementadas las tres primeras relaciones físicas mencionadas; las cuatro restantes están representadas por columnas BIGINT NOT NULL e índices, pero sus restricciones FOREIGN KEY quedan pendientes de la creación física de las dimensiones correspondientes.

## 6.3. Reglas de negocio y decisiones técnicas

1. Se utiliza exclusivamente “Datos proyecto BI v2.xlsx” como fuente de trabajo para evitar combinar extracciones de diferente cobertura.
2. La opción de carrera se deriva de la hoja de origen y se almacena en la dimensión dim_opcion; no se conserva como atributo descriptivo en la tabla de hechos.
3. La cantidad_solicitudes se registra como 1 por fila fuente. Su suma cuenta registros y no personas únicas.
4. Se conserva el valor original de las notas como texto y se almacena una versión numérica únicamente cuando la conversión es válida.
5. Los valores 0.00, “No Aplica” y “No Especificado” se mantienen diferenciados. El cero no se convierte automáticamente en nulo ni se elimina el registro.
6. Los años o combinaciones de opción sin registros se interpretan como ausencia de datos, no como un valor de cero.
7. No se eliminan filas idénticas únicamente por coincidir en todos sus campos, ya que la fuente no incluye un identificador individual que permita confirmar duplicados de personas.
8. Se conserva la trazabilidad mediante hoja_origen y fila_origen. La combinación de ambos campos debe ser única.
9. No se crean relaciones individuales entre solicitudes y admisiones.
10. El atributo “Solicitud de Adecuación” no se incorpora a la tabla de hechos implementada. La decisión responde a que no forma parte del mapeo dimensional aprobado y a las precauciones de confidencialidad señaladas en el informe. El valor original permanece en la fuente entregada y no debe divulgarse sin autorización específica.

Como decisiones de implementación, se utilizan llaves subrogadas BIGINT generadas por identidad en las dimensiones y en la tabla de hechos. Los atributos categóricos se almacenan como TEXT para preservar las categorías de la fuente. Las restricciones UNIQUE evitan duplicar miembros dimensionales según sus atributos naturales definidos; las claves foráneas garantizan la integridad referencial de las tres dimensiones físicamente creadas.

## 6.4. Estado de implementación y alcance de la verificación

Al momento de documentar este componente, PostgreSQL contiene las tablas bi.dim_tiempo, bi.dim_geografia, bi.dim_colegio y bi.fact_solicitudes. Se verificaron sus columnas, claves primarias, restricciones UNIQUE y CHECK, así como las tres claves foráneas desde fact_solicitudes hacia las dimensiones implementadas. También se verificó que las cuatro tablas contienen cero registros; por tanto, la estructura está creada, pero la carga ETL y las pruebas con datos reales siguen pendientes.

Las columnas id_opcion, id_perfil_estudiante, id_forma_ingreso e id_rango_nota están creadas como BIGINT NOT NULL y cuentan con índices. No se declaran todavía como claves foráneas físicas porque las dimensiones destino no han sido creadas. Esta condición debe cerrarse durante la integración con el componente de Persona 4.

La verificación de restricciones no demuestra todavía la calidad de una carga ni la validez de los resultados analíticos. Esas comprobaciones se realizarán después de implementar y ejecutar el ETL.

## Diccionario de datos

### dim_tiempo

| Campo | Tipo | Nulo | Clave / restricción | Descripción |
|---|---|---|---|---|
| id_tiempo | BIGINT | No | PK; identidad | Llave subrogada generada automáticamente para identificar cada año. |
| anio | SMALLINT | No | UNIQUE; CHECK 1900–2100 | Año calendario de la observación según la fuente. |

### dim_geografia

| Campo | Tipo | Nulo | Clave / restricción | Descripción |
|---|---|---|---|---|
| id_geografia | BIGINT | No | PK; identidad | Llave subrogada de la combinación geográfica. |
| zona_residencia | TEXT | No | Parte de UNIQUE compuesta | Categoría de zona de residencia registrada en la fuente. |
| region_planificacion | TEXT | No | Parte de UNIQUE compuesta | Región de planificación registrada en la fuente. |
| provincia | TEXT | No | Parte de UNIQUE compuesta | Provincia de procedencia registrada. |
| canton | TEXT | No | Parte de UNIQUE compuesta | Cantón de procedencia registrado. |
| distrito | TEXT | No | Parte de UNIQUE compuesta | Distrito de procedencia registrado. |
| nivel_desarrollo_social | TEXT | No | Parte de UNIQUE compuesta | Categoría de nivel de desarrollo social disponible en la fuente; no equivale a un valor numérico de IDS. |
| zona_gam | TEXT | No | Parte de UNIQUE compuesta | Clasificación GAM registrada en la fuente; no debe inferirse si no está informada. |

### dim_colegio

| Campo | Tipo | Nulo | Clave / restricción | Descripción |
|---|---|---|---|---|
| id_colegio | BIGINT | No | PK; identidad | Llave subrogada para cada combinación de atributos del colegio. |
| modalidad | TEXT | No | Parte de UNIQUE compuesta | Modalidad del colegio de procedencia según la fuente. |
| tipo_financiamiento | TEXT | No | Parte de UNIQUE compuesta | Tipo de financiamiento del colegio según la fuente. |

### fact_solicitudes

| Campo | Tipo | Nulo | Clave / restricción | Descripción |
|---|---|---|---|---|
| id_solicitud | BIGINT | No | PK; identidad | Identificador técnico del registro en el Data Warehouse; no identifica a una persona. |
| id_tiempo | BIGINT | No | FK → dim_tiempo.id_tiempo | Referencia al año de la solicitud. |
| id_geografia | BIGINT | No | FK → dim_geografia.id_geografia | Referencia al miembro geográfico. |
| id_colegio | BIGINT | No | FK → dim_colegio.id_colegio | Referencia a la combinación de modalidad y financiamiento del colegio. |
| cantidad_solicitudes | SMALLINT | No | DEFAULT 1; CHECK = 1 | Medida aditiva unitaria; sumar para contar registros de solicitud. |
| nota_admision_original | TEXT | Sí | — | Valor de Nota de Admisión conservado tal como aparece en la fuente. |
| nota_admision | NUMERIC(8,2) | Sí | — | Valor numérico de Nota de Admisión cuando la conversión es válida; categorías no numéricas quedan fuera de esta columna. |
| nota_iv_ciclo_original | TEXT | Sí | — | Valor original de Nota de IV Ciclo; disponible únicamente en las hojas de solicitantes. |
| nota_iv_ciclo | NUMERIC(8,2) | Sí | — | Valor numérico de Nota de IV Ciclo cuando la conversión es válida. |
| hoja_origen | TEXT | No | Parte de UNIQUE compuesta | Nombre de la hoja del Excel desde la cual se obtuvo el registro. |
| fila_origen | INTEGER | No | CHECK >= 2; parte de UNIQUE compuesta | Número de fila en el Excel, incluyendo encabezado; permite rastrear el registro. |
| fecha_carga | TIMESTAMPTZ | No | DEFAULT CURRENT_TIMESTAMP | Fecha y hora de inserción en el Data Warehouse, con zona horaria. |
| id_opcion | BIGINT | No | FK lógica pendiente; índice | Referencia prevista a bi.dim_opcion(id_opcion), dimensión a cargo de Persona 4. |
| id_perfil_estudiante | BIGINT | No | FK lógica pendiente; índice | Referencia prevista a bi.dim_perfil_estudiante(id_perfil_estudiante), dimensión a cargo de Persona 4. |
| id_forma_ingreso | BIGINT | No | FK lógica pendiente; índice | Referencia prevista a bi.dim_forma_ingreso(id_forma_ingreso), dimensión a cargo de Persona 4. |
| id_rango_nota | BIGINT | No | FK lógica pendiente; índice | Referencia prevista a bi.dim_rango_nota(id_rango_nota), dimensión a cargo de Persona 4. |

## Diagrama dimensional

El archivo Mermaid asociado representa las tres dimensiones implementadas y las cuatro dimensiones cuya creación física corresponde a Persona 4. Las líneas discontinuas representan relaciones lógicas pendientes de restricción física.
