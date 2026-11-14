# Diccionario de datos y diseño dimensional — Componente A: Solicitudes

Versión 1.0. Fuente oficial: `Datos proyecto BI v2.xlsx`. Motor: PostgreSQL. Esquema: `bi`.

## Granularidad

Una fila de `fact_solicitudes` representa un registro de solicitante de primera o segunda opción; no necesariamente una persona única. La medida `cantidad_solicitudes` vale 1 por registro.

## Diagrama

```mermaid
erDiagram
    DIM_TIEMPO ||--o{ FACT_SOLICITUDES : "id_tiempo"
    DIM_GEOGRAFIA ||--o{ FACT_SOLICITUDES : "id_geografia"
    DIM_COLEGIO ||--o{ FACT_SOLICITUDES : "id_colegio"

    DIM_TIEMPO {
        bigint id_tiempo PK
        smallint anio UK
    }
    DIM_GEOGRAFIA {
        bigint id_geografia PK
        text zona_residencia
        text region_planificacion
        text provincia
        text canton
        text distrito
        text nivel_desarrollo_social
        text zona_gam
    }
    DIM_COLEGIO {
        bigint id_colegio PK
        text modalidad
        text tipo_financiamiento
    }
    FACT_SOLICITUDES {
        bigint id_solicitud PK
        bigint id_tiempo FK
        bigint id_geografia FK
        bigint id_colegio FK
        text opcion_carrera
        smallint cantidad_solicitudes
        text rango_edad
        text forma_ingreso
        text nota_admision_original
        numeric nota_admision
        text rango_nota_admision
        text nota_iv_ciclo_original
        numeric nota_iv_ciclo
        text nacionalidad
        text tipo_estudiante
        text solicitud_adecuacion
        text tipo_diploma_secundaria
        text hoja_origen
        integer fila_origen
        timestamptz fecha_carga
    }
```

## Diccionario físico

El documento DOCX contiene el diccionario completo de las 33 columnas, restricciones, reglas de negocio, alcance y limitaciones de validación.

## Estado de validación

- 4 tablas encontradas en el esquema `bi`.
- 33 columnas consultadas en `information_schema.columns`.
- 15 restricciones consultadas en `pg_constraint`.
- 3 llaves foráneas verificadas.
- 0 registros en las cuatro tablas al momento de la revisión.
- ETL y carga de datos todavía no ejecutados ni validados.
