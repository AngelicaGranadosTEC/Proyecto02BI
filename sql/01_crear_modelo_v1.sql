-- PROYECTO 02 BI - TEC
-- Contrato dimensional v1.0 | Componente A: Solicitudes
-- Motor: PostgreSQL
--
-- Alcance:
--   * Crea las dimensiones conformadas compartidas por solicitudes y admisiones.
--   * Crea exclusivamente fact_solicitudes (responsabilidad de Persona 3).
--   * No crea fact_admisiones: corresponde al componente de Persona 4.
--
-- Fuente oficial acordada: Datos proyecto BI v2.xlsx
-- Ejecutar en pgAdmin > Query Tool, conectado a la base de datos del proyecto.
--
-- Seguridad:
--   * Este script NO elimina tablas ni datos.
--   * CREATE TABLE IF NOT EXISTS no modifica una tabla preexistente.
--   * Ejecutar primero en una base de datos de desarrollo o esquema vacío.
--   * Si ya existen tablas bi con otra estructura, detenerse y revisar antes
--     de continuar; no intentar corregirlas eliminándolas.

BEGIN;

CREATE SCHEMA IF NOT EXISTS bi;

-- ============================================================
-- 1. DIMENSIONES CONFORMADAS (compartidas)
-- ============================================================

CREATE TABLE IF NOT EXISTS bi.dim_tiempo (
    id_tiempo BIGINT GENERATED ALWAYS AS IDENTITY,
    anio SMALLINT NOT NULL,
    CONSTRAINT pk_dim_tiempo PRIMARY KEY (id_tiempo),
    CONSTRAINT uq_dim_tiempo_anio UNIQUE (anio),
    CONSTRAINT ck_dim_tiempo_anio CHECK (anio BETWEEN 1900 AND 2100)
);

COMMENT ON TABLE bi.dim_tiempo IS
'Dimensión temporal conformada para los componentes de solicitudes y admisiones. La fuente disponible aporta el año, no una fecha completa.';
COMMENT ON COLUMN bi.dim_tiempo.anio IS
'Año calendario de la observación, según el archivo oficial Datos proyecto BI v2.xlsx.';

CREATE TABLE IF NOT EXISTS bi.dim_geografia (
    id_geografia BIGINT GENERATED ALWAYS AS IDENTITY,
    zona_residencia TEXT NOT NULL,
    region_planificacion TEXT NOT NULL,
    provincia TEXT NOT NULL,
    canton TEXT NOT NULL,
    distrito TEXT NOT NULL,
    nivel_desarrollo_social TEXT NOT NULL,
    zona_gam TEXT NOT NULL,
    CONSTRAINT pk_dim_geografia PRIMARY KEY (id_geografia),
    CONSTRAINT uq_dim_geografia_atributos UNIQUE (
        zona_residencia,
        region_planificacion,
        provincia,
        canton,
        distrito,
        nivel_desarrollo_social,
        zona_gam
    )
);

COMMENT ON TABLE bi.dim_geografia IS
'Dimensión geográfica conformada. Su combinación de atributos identifica un miembro dimensional y permite análisis territoriales.';
COMMENT ON COLUMN bi.dim_geografia.zona_gam IS
'Clasificación GAM tal como aparece en la fuente; no inferirla a partir de provincia, cantón o distrito.';
COMMENT ON COLUMN bi.dim_geografia.nivel_desarrollo_social IS
'Categoría de nivel de desarrollo social disponible en la fuente. No representa un valor numérico de IDS.';

CREATE TABLE IF NOT EXISTS bi.dim_colegio (
    id_colegio BIGINT GENERATED ALWAYS AS IDENTITY,
    modalidad TEXT NOT NULL,
    tipo_financiamiento TEXT NOT NULL,
    CONSTRAINT pk_dim_colegio PRIMARY KEY (id_colegio),
    CONSTRAINT uq_dim_colegio_atributos UNIQUE (
        modalidad,
        tipo_financiamiento
    )
);

COMMENT ON TABLE bi.dim_colegio IS
'Dimensión de características del colegio conformada para solicitudes y admisiones.';
COMMENT ON COLUMN bi.dim_colegio.modalidad IS
'Modalidad del colegio según la fuente operacional.';
COMMENT ON COLUMN bi.dim_colegio.tipo_financiamiento IS
'Tipo de financiamiento del colegio según la fuente operacional.';

-- ============================================================
-- 2. TABLA DE HECHOS: SOLICITUDES (Persona 3)
-- Granularidad: una fila por registro de solicitante en la fuente.
-- No equivale necesariamente a una persona única.
-- ============================================================

CREATE TABLE IF NOT EXISTS bi.fact_solicitudes (
    id_solicitud BIGINT GENERATED ALWAYS AS IDENTITY,
    id_tiempo BIGINT NOT NULL,
    id_geografia BIGINT NOT NULL,
    id_colegio BIGINT NOT NULL,

    opcion_carrera TEXT NOT NULL,
    cantidad_solicitudes SMALLINT NOT NULL DEFAULT 1,

    -- Atributos del registro de solicitud que no pertenecen a las
    -- tres dimensiones asignadas a este componente.
    rango_edad TEXT,
    forma_ingreso TEXT,
    nota_admision_original TEXT,
    nota_admision NUMERIC(8,2),
    rango_nota_admision TEXT,
    nota_iv_ciclo_original TEXT,
    nota_iv_ciclo NUMERIC(8,2),
    nacionalidad TEXT,
    tipo_estudiante TEXT,
    solicitud_adecuacion TEXT,
    tipo_diploma_secundaria TEXT,

    -- Trazabilidad del registro fuente.
    hoja_origen TEXT NOT NULL,
    fila_origen INTEGER NOT NULL,
    fecha_carga TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT pk_fact_solicitudes PRIMARY KEY (id_solicitud),
    CONSTRAINT fk_fact_solicitudes_tiempo
        FOREIGN KEY (id_tiempo)
        REFERENCES bi.dim_tiempo (id_tiempo),
    CONSTRAINT fk_fact_solicitudes_geografia
        FOREIGN KEY (id_geografia)
        REFERENCES bi.dim_geografia (id_geografia),
    CONSTRAINT fk_fact_solicitudes_colegio
        FOREIGN KEY (id_colegio)
        REFERENCES bi.dim_colegio (id_colegio),
    CONSTRAINT ck_fact_solicitudes_opcion
        CHECK (opcion_carrera IN ('Primera', 'Segunda')),
    CONSTRAINT ck_fact_solicitudes_cantidad
        CHECK (cantidad_solicitudes = 1),
    CONSTRAINT ck_fact_solicitudes_fila_origen
        CHECK (fila_origen >= 2),
    CONSTRAINT uq_fact_solicitudes_origen
        UNIQUE (hoja_origen, fila_origen)
);

COMMENT ON TABLE bi.fact_solicitudes IS
'Tabla de hechos del componente A. Una fila representa un registro de solicitante de las hojas de primera o segunda opción; no necesariamente una persona única.';
COMMENT ON COLUMN bi.fact_solicitudes.cantidad_solicitudes IS
'Medida aditiva unitaria. SUM(cantidad_solicitudes) cuenta registros de solicitud, no personas únicas.';
COMMENT ON COLUMN bi.fact_solicitudes.opcion_carrera IS
'Indica si el registro proviene de la hoja de solicitantes de primera o segunda opción.';
COMMENT ON COLUMN bi.fact_solicitudes.nota_admision_original IS
'Valor original de Nota de Admisión conservado como texto para no perder categorías ni formato.';
COMMENT ON COLUMN bi.fact_solicitudes.nota_admision IS
'Versión numérica de Nota de Admisión cuando la conversión es válida. Las categorías no numéricas quedan NULL; el cero se conserva como cero.';
COMMENT ON COLUMN bi.fact_solicitudes.nota_iv_ciclo_original IS
'Valor original de Nota de IV Ciclo, disponible únicamente en las hojas de solicitantes que contienen ese atributo.';
COMMENT ON COLUMN bi.fact_solicitudes.solicitud_adecuacion IS
'Atributo potencialmente sensible. No exponer en visualizaciones ni segmentaciones sin autorización y justificación.';
COMMENT ON COLUMN bi.fact_solicitudes.hoja_origen IS
'Nombre exacto de la hoja del archivo Excel de origen.';
COMMENT ON COLUMN bi.fact_solicitudes.fila_origen IS
'Número de fila de Excel (incluido encabezado) que permite rastrear el registro. No identifica a una persona.';
COMMENT ON COLUMN bi.fact_solicitudes.fecha_carga IS
'Fecha y hora con zona horaria en que se insertó el registro en el Data Warehouse.';

-- ============================================================
-- 3. ÍNDICES PARA CONSULTAS Y RELACIONES
-- ============================================================

CREATE INDEX IF NOT EXISTS ix_fact_solicitudes_tiempo
    ON bi.fact_solicitudes (id_tiempo);

CREATE INDEX IF NOT EXISTS ix_fact_solicitudes_geografia
    ON bi.fact_solicitudes (id_geografia);

CREATE INDEX IF NOT EXISTS ix_fact_solicitudes_colegio
    ON bi.fact_solicitudes (id_colegio);

CREATE INDEX IF NOT EXISTS ix_fact_solicitudes_opcion
    ON bi.fact_solicitudes (opcion_carrera);

CREATE INDEX IF NOT EXISTS ix_fact_solicitudes_tiempo_geografia
    ON bi.fact_solicitudes (id_tiempo, id_geografia);

COMMIT;

-- ============================================================
-- 4. CONSULTAS DE VERIFICACIÓN (ejecutar después del script)
-- ============================================================
-- SELECT table_schema, table_name
-- FROM information_schema.tables
-- WHERE table_schema = 'bi'
-- ORDER BY table_name;
--
-- SELECT column_name, data_type, is_nullable
-- FROM information_schema.columns
-- WHERE table_schema = 'bi' AND table_name = 'fact_solicitudes'
-- ORDER BY ordinal_position;
--
-- SELECT conname, contype
-- FROM pg_constraint
-- WHERE connamespace = 'bi'::regnamespace
-- ORDER BY conname;
