# Proyecto 02 | Inteligencia de Negocios para la Escuela de ATI

**TI-6900 — Inteligencia de Negocios · Tecnológico de Costa Rica · II semestre de 2026**

[**Dashboard en Power BI**](https://app.powerbi.com/groups/me/reports/1d1e974b-e354-4193-aee4-f7bd01f582bf?ctid=bfcf1d9d-93ea-43b1-b902-1daa68a64248&pbi_source=linkShare) · [**Repositorio GitHub**](https://github.com/AngelicaGranadosTEC/Proyecto02BI)

## Descripción

Este proyecto desarrolla una solución integral de **Inteligencia de Negocios (BI)** para la **Escuela de Administración de Tecnologías de Información (ATI)** del Tecnológico de Costa Rica. Su propósito es transformar los datos históricos de solicitudes y admisiones a la carrera en información organizada, trazable y útil para el seguimiento de indicadores y la toma de decisiones.

La solución abarca el análisis de las fuentes operacionales, la evaluación de su calidad, el diseño e implementación de un modelo dimensional, dos procesos ETL reproducibles y un dashboard interactivo en Power BI.

### Alcance de los datos

| Característica | Descripción |
|---|---|
| Organización | Escuela de Administración de Tecnologías de Información, TEC |
| Periodo analizado | Años con datos disponibles entre **2020 y 2026** |
| Fuente de origen | Exportación institucional de **Saiku OLAP**, obtenida con apoyo de la Oficina de Planificación Institucional (OPI) |
| Archivo de referencia | `Datos proyecto BI v2.xlsx` |
| Conjuntos operacionales | Solicitantes de primera opción, solicitantes de segunda opción, admitidos de primera opción y admitidos de segunda opción |
| Registros de solicitudes | **4.854** (2.725 de primera opción y 2.129 de segunda opción) |
| Registros de admisiones | **742** (659 de primera opción y 83 de segunda opción) |
| Total | **5.596 registros** |

Los conteos se refieren a **registros**, no a personas únicas. La fuente no proporciona una llave común que permita vincular individualmente a una persona solicitante con su posterior admisión. La cobertura de segunda opción tampoco es homogénea en todos los años, es importante aclarar que una combinación sin registros disponibles no equivale necesariamente a cero.

## Objetivos y preguntas de negocio

El objetivo general es integrar la información institucional de solicitudes y admisiones mediante una arquitectura analítica que permita examinar tendencias históricas, características académicas y procedencia de las poblaciones registradas.

La solución responde cinco preguntas de negocio:

1. **Evolución histórica (PN1):** ¿cómo cambian las solicitudes y admisiones según el año y la opción de carrera?
2. **Procedencia geográfica (PN2):** ¿cómo se distribuyen según provincia, región y características territoriales?
3. **Notas y rangos de admisión (PN3):** ¿qué distribuciones de notas presentan las poblaciones solicitantes y admitidas?
4. **Colegios de procedencia (PN4):** ¿qué modalidades y tipos de financiamiento predominan?
5. **Vías de ingreso (PN5, exploratoria):** ¿cómo difieren la forma de ingreso y la condición académica entre ambas poblaciones?

## Arquitectura de la solución

```text
Fuente institucional: Datos proyecto BI v2.xlsx
                     │
          ┌──────────┴──────────┐
          ▼                     ▼
  ETL A — Solicitudes    ETL B — Admisiones
         (Python)              (Python)
          └──────────┬──────────┘
                     ▼
           Modelo dimensional
          ┌───────────────────┐
          │ fact_solicitudes  │
          │ fact_admisiones   │
          │ 7 dimensiones     │
          └───────────────────┘
                     │
                     ▼
           Power BI — 6 páginas
```

El modelo contempla dos tablas de hechos, `fact_solicitudes` y `fact_admisiones`, relacionadas mediante dimensiones analíticas compartidas:

- `dim_tiempo`
- `dim_geografia`
- `dim_colegio`
- `dim_opcion`
- `dim_perfil_estudiante`
- `dim_forma_ingreso`
- `dim_rango_nota`

Se utiliza una **dimensión de tiempo** para el análisis anual y se evitan relaciones directas entre las tablas de hechos a nivel de persona. El proyecto documenta **14 indicadores** para dar respuesta a las preguntas de negocio y al resumen ejecutivo.

### Tecnologías

| Área | Herramienta |
|---|---|
| Datos de origen | Excel y Saiku OLAP |
| Procesamiento ETL | Python, `pandas` y `openpyxl` |
| Base de datos | PostgreSQL; SQLite para pruebas locales reproducibles |
| Definición del modelo | SQL y documentación dimensional |
| Visualización | Power BI Desktop y Power BI Service |
| Diagramación y documentación | Mermaid, draw.io y archivos Markdown |
| Control de versiones y colaboración | GitHub, mediante una adaptación de Scrum |

## Equipo de trabajo

| Integrante | Responsabilidad principal | Página del dashboard |
|---|---|---|
| Sharon Sánchez Céspedes | Análisis del negocio, requerimientos y acta constitutiva | 01 — Resumen ejecutivo |
| Mirka Araya Quirós | Fuente operacional, calidad de datos y trazabilidad | 02 — Evolución histórica |
| Alexandra Pamela Cruz Segura | Modelo dimensional de solicitudes | 03 — Distribución geográfica |
| Angélica Granados Rivera | Modelo dimensional de admisiones | 04 — Notas y rangos de admisión |
| Fabián Granados Rivera | ETL de solicitudes | 05 — Colegios de procedencia |
| Sergio Mena Campos | ETL de admisiones y análisis exploratorio | 06 — Vías de ingreso |

El equipo desarrolló de manera colaborativa las actividades de integración, documentación, pruebas, gestión del repositorio y presentación de resultados.

## Organización del repositorio

```text
Proyecto02BI/
├── README.md
├── SharonSanchezCespedes_requerimientos_resumen/
│   ├── documentacion/
│   └── dashboard/
├── MirkaArayaQuiros_fuente_operacional/
│   ├── diagramas/
│   ├── evidencias/
│   └── dashboard/
├── AlexandraPamelaCruzSegura_modelo_solicitudes/
│   ├── documentacion/
│   ├── integracion/
│   ├── sql/
│   └── evidencias/
├── AngelicaGranadosRivera_modelo_admisiones/
│   ├── docs/
│   └── sql/
├── FabianGranadosRivera_etl_solicitantes/
│   ├── etl/
│   ├── sql/
│   ├── tests/
│   ├── documentacion/
│   └── evidencias/
└── SergioMenaCampos_etl_admitidos/
    ├── etl/
    ├── sql/
    ├── tests/
    ├── dashboard/
    ├── logs/
    └── salidas/
```

### Componentes y documentación técnica

- **Requerimientos y resumen ejecutivo:** [`SharonSanchezCespedes_requerimientos_resumen/`](SharonSanchezCespedes_requerimientos_resumen/)
- **Fuentes, calidad y trazabilidad:** [`MirkaArayaQuiros_fuente_operacional/`](MirkaArayaQuiros_fuente_operacional/)
- **Modelo dimensional de solicitudes:** [`AlexandraPamelaCruzSegura_modelo_solicitudes/`](AlexandraPamelaCruzSegura_modelo_solicitudes/)
- **Modelo dimensional de admisiones:** [`AngelicaGranadosRivera_modelo_admisiones/`](AngelicaGranadosRivera_modelo_admisiones/)
- **ETL A — Solicitudes:** [`FabianGranadosRivera_etl_solicitantes/README_ETL_A.md`](FabianGranadosRivera_etl_solicitantes/README_ETL_A.md)
- **ETL B — Admisiones:** [`SergioMenaCampos_etl_admitidos/README_ETL_B.md`](SergioMenaCampos_etl_admitidos/README_ETL_B.md)

Las carpetas reúnen código, definiciones SQL, diagramas, reglas de transformación, consultas, evidencias y medidas DAX, según el componente desarrollado por cada integrante.

## Reproducción local de los ETL

Los procesos ETL utilizan el archivo institucional `Datos proyecto BI v2.xlsx`. Por las condiciones de confidencialidad de la información, **este archivo se obtiene a través de la Escuela de ATI y no se distribuye públicamente en GitHub**.

### Requisitos

- Python **3.11 o posterior**, con `pip`.
- Acceso autorizado al Excel de origen.
- SQLite para la reproducción local sin servidor (incluido en la biblioteca estándar de Python).
- PostgreSQL para ejecutar el modelo en una base de datos de servidor.
- Power BI Desktop para trabajar con la versión editable del reporte.

### 1. Descargar el repositorio

En una terminal de Windows (PowerShell):

```powershell
git clone https://github.com/AngelicaGranadosTEC/Proyecto02BI.git
cd Proyecto02BI
python -m venv .venv
.\.venv\Scripts\python.exe -m pip install -r .\SergioMenaCampos_etl_admitidos\requirements.txt
```

También es posible obtener los archivos mediante **Code → Download ZIP** en GitHub y abrir una terminal en la carpeta extraída. Las instrucciones siguientes se ejecutan desde la carpeta principal del proyecto.

### 2. Ejecutar los ETL en SQLite

Esta alternativa permite cargar las dos poblaciones en **una misma base dimensional local**, sin configurar PostgreSQL. Los comandos usan como destino `dw_ati.db` en la carpeta de trabajo local.

Sustituya `C:\RUTA\Datos proyecto BI v2.xlsx` por la ruta del Excel institucional en su equipo:

```powershell
.\.venv\Scripts\python.exe .\FabianGranadosRivera_etl_solicitantes\etl\etl_a_solicitantes.py --fuente "C:\RUTA\Datos proyecto BI v2.xlsx" --bd ".\dw_ati.db"

.\.venv\Scripts\python.exe .\SergioMenaCampos_etl_admitidos\etl\etl_b_admitidos.py --fuente "C:\RUTA\Datos proyecto BI v2.xlsx" --bd ".\dw_ati.db"
```

El **ETL A** consolida las solicitudes y el **ETL B** carga las admisiones. Ambos emplean reglas compartidas de normalización y dimensiones conformadas. Los scripts generan registros de ejecución y resultados de validación en sus directorios `logs/` y `salidas/`. La carga está diseñada para permitir reejecuciones sin duplicar los registros de origen.

### 3. Ejecutar el modelo en PostgreSQL

La implementación en PostgreSQL utiliza el esquema `bi`. En una base de datos nueva, los scripts de estructura se aplican en este orden:

1. `AlexandraPamelaCruzSegura_modelo_solicitudes/sql/01_crear_modelo_v1.sql`
2. `SergioMenaCampos_etl_admitidos/sql/postgresql/ddl_componente_b.sql`
3. `AlexandraPamelaCruzSegura_modelo_solicitudes/sql/02_ajustar_fact_solicitudes_integracion_v2.sql`

Con la estructura creada, los ETL se ejecutan apuntando a la misma base:

```powershell
.\.venv\Scripts\python.exe .\FabianGranadosRivera_etl_solicitantes\etl\etl_a_solicitantes.py --fuente "C:\RUTA\Datos proyecto BI v2.xlsx" --bd "postgresql://USUARIO:CLAVE@SERVIDOR:5432/BASE"

.\.venv\Scripts\python.exe .\SergioMenaCampos_etl_admitidos\etl\etl_b_admitidos.py --fuente "C:\RUTA\Datos proyecto BI v2.xlsx" --bd "postgresql://USUARIO:CLAVE@SERVIDOR:5432/BASE"
```

Finalmente, se aplica una vez el script `SergioMenaCampos_etl_admitidos/sql/postgresql/integrar_fk_fact_solicitudes.sql`, que completa las claves foráneas de integración de las solicitudes.

Para este flujo se utiliza el DDL operativo del componente B incluido en la carpeta de Sergio, compatible con las convenciones de los ETL integrados. La documentación del modelo conceptual de admisiones y su variante SQL original se conservan en la carpeta de Angélica como parte de los entregables de diseño dimensional.

**Seguridad:** los ejemplos de conexión utilizan valores ilustrativos. Las contraseñas reales deben manejarse fuera del repositorio, preferiblemente mediante variables de entorno o un administrador de secretos.

### 4. Validar la carga

Los conteos de referencia del conjunto de datos v2 son:

| Resultado | Registros |
|---|---:|
| `fact_solicitudes` — primera opción | 2.725 |
| `fact_solicitudes` — segunda opción | 2.129 |
| **Total de solicitudes** | **4.854** |
| `fact_admisiones` — primera opción | 659 |
| `fact_admisiones` — segunda opción | 83 |
| **Total de admisiones** | **742** |

Los ETL incluyen controles de cantidad de registros, integridad de claves, calidad y reejecución. Los resultados se documentan en las bitácoras y archivos de validación generados por cada ejecución.

## Dashboard interactivo

**[Acceder al dashboard publicado en Power BI Service](https://app.powerbi.com/groups/me/reports/1d1e974b-e354-4193-aee4-f7bd01f582bf?ctid=bfcf1d9d-93ea-43b1-b902-1daa68a64248&pbi_source=linkShare)**

El reporte reúne seis vistas:

1. **Resumen ejecutivo:** indicadores generales de solicitudes y admisiones.
2. **Evolución histórica:** tendencias por año y primera o segunda opción.
3. **Distribución geográfica:** procedencia territorial de ambas poblaciones.
4. **Notas y rangos de admisión:** comparación de calificaciones y sus distribuciones.
5. **Colegios de procedencia:** modalidad y tipo de financiamiento del colegio.
6. **Vías de ingreso:** análisis exploratorio según forma de ingreso y condición académica.

El dashboard permite aplicar filtros, examinar indicadores y contrastar resultados de forma agregada. El enlace de Power BI Service requiere autenticación y los permisos correspondientes. La edición del modelo y de las páginas se realiza con Power BI Desktop mediante el archivo del proyecto compartido por el equipo a través de los canales autorizados.

## Calidad de datos y criterios de interpretación

- Los valores de nota `0.00`, `No aplica` y `No especificado` se identifican por separado; no se consideran automáticamente equivalentes.
- En segunda opción existen años sin registros en la exportación. Estos se interpretan como **sin datos**, no como ceros confirmados.
- Los recuentos no representan personas únicas y no se calcula una tasa de conversión individual entre solicitudes y admisiones.
- Los procesos ETL conservan el linaje mediante los campos `hoja_origen` y `fila_origen`.
- La variable sensible **Solicitud de Adecuación** se excluye del modelo analítico publicado.
- Las comparaciones agregadas se interpretan dentro de las restricciones de cobertura, granularidad y calidad documentadas en el informe del proyecto.

## Confidencialidad

Los archivos institucionales, bases de datos con registros, credenciales, exportaciones individuales y otros insumos sujetos a autorización **no se publican en este repositorio**. Su utilización se rige por los términos de acceso concedidos por la Escuela de ATI y por el memorando institucional `ati-199-2026`.

El repositorio contiene los recursos de implementación y documentación reproducible; el acceso al reporte publicado está limitado por los permisos asignados en Power BI Service.

---

**Proyecto académico desarrollado por seis integrantes del curso TI-6900 Inteligencia de Negocios del Tecnológico de Costa Rica, II semestre de 2026.**
