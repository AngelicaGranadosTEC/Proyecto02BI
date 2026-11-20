-- Proyecto 02 - Inteligencia de Negocios
-- Componente B: admisiones
-- Persona 4
-- Archivo: 03_crear_modelo_admisiones_v1.sql
--
-- Objetivo:
--   Crear las cuatro dimensiones bajo responsabilidad del componente B
--   y la tabla de hechos bi.fact_admisiones.
--
-- Dependencias:
--   Deben existir previamente:
--     bi.dim_tiempo
--     bi.dim_geografia
--     bi.dim_colegio
--
-- Fuente oficial:
--   Datos proyecto BI v2.xlsx

BEGIN;

CREATE SCHEMA IF NOT EXISTS bi;

-- =========================================================
-- 1. DIMENSION: OPCION
-- =========================================================

CREATE TABLE bi.dim_opcion (
    id_opcion BIGINT GENERATED ALWAYS AS IDENTITY,
    opcion TEXT NOT NULL,

    CONSTRAINT pk_dim_opcion
        PRIMARY KEY (id_opcion),

    CONSTRAINT uq_dim_opcion_opcion
        UNIQUE (opcion),

    CONSTRAINT ck_dim_opcion_opcion
        CHECK (opcion IN ('Primera', 'Segunda'))
);

COMMENT ON TABLE bi.dim_opcion IS
'Clasifica los registros según primera o segunda opción de carrera.';

COMMENT ON COLUMN bi.dim_opcion.id_opcion IS
'Llave subrogada de la dimensión de opción.';

COMMENT ON COLUMN bi.dim_opcion.opcion IS
'Categoría de opción de carrera derivada de la hoja de origen: Primera o Segunda.';


-- =========================================================
-- 2. DIMENSION: PERFIL DEL ESTUDIANTE
-- =========================================================

CREATE TABLE bi.dim_perfil_estudiante (
    id_perfil_estudiante BIGINT GENERATED ALWAYS AS IDENTITY,
    rango_edad TEXT NOT NULL,
    nacionalidad TEXT NOT NULL,
    tipo_estudiante TEXT NOT NULL,
    tipo_diploma_secundaria TEXT NOT NULL,

    CONSTRAINT pk_dim_perfil_estudiante
        PRIMARY KEY (id_perfil_estudiante),

    CONSTRAINT uq_dim_perfil_estudiante_atributos
        UNIQUE (
            rango_edad,
            nacionalidad,
            tipo_estudiante,
            tipo_diploma_secundaria
        )
);

COMMENT ON TABLE bi.dim_perfil_estudiante IS
'Agrupa características demográficas y académicas del perfil del estudiante sin identificar personas individuales.';

COMMENT ON COLUMN bi.dim_perfil_estudiante.id_perfil_estudiante IS
'Llave subrogada de la combinación de atributos del perfil.';

COMMENT ON COLUMN bi.dim_perfil_estudiante.rango_edad IS
'Rango de edad registrado en la fuente.';

COMMENT ON COLUMN bi.dim_perfil_estudiante.nacionalidad IS
'Nacionalidad registrada en la fuente.';

COMMENT ON COLUMN bi.dim_perfil_estudiante.tipo_estudiante IS
'Tipo de estudiante registrado en la fuente.';

COMMENT ON COLUMN bi.dim_perfil_estudiante.tipo_diploma_secundaria IS
'Tipo de diploma de secundaria registrado en la fuente.';


-- =========================================================
-- 3. DIMENSION: FORMA DE INGRESO
-- =========================================================

CREATE TABLE bi.dim_forma_ingreso (
    id_forma_ingreso BIGINT GENERATED ALWAYS AS IDENTITY,
    forma_ingreso TEXT NOT NULL,

    CONSTRAINT pk_dim_forma_ingreso
        PRIMARY KEY (id_forma_ingreso),

    CONSTRAINT uq_dim_forma_ingreso_forma
        UNIQUE (forma_ingreso)
);

COMMENT ON TABLE bi.dim_forma_ingreso IS
'Clasifica los registros según la forma o modalidad de ingreso registrada en la fuente.';

COMMENT ON COLUMN bi.dim_forma_ingreso.id_forma_ingreso IS
'Llave subrogada de la dimensión de forma de ingreso.';

COMMENT ON COLUMN bi.dim_forma_ingreso.forma_ingreso IS
'Forma o modalidad de ingreso registrada en la fuente.';


-- =========================================================
-- 4. DIMENSION: RANGO DE NOTA
-- =========================================================

CREATE TABLE bi.dim_rango_nota (
    id_rango_nota BIGINT GENERATED ALWAYS AS IDENTITY,
    rango_nota TEXT NOT NULL,

    CONSTRAINT pk_dim_rango_nota
        PRIMARY KEY (id_rango_nota),

    CONSTRAINT uq_dim_rango_nota_rango
        UNIQUE (rango_nota)
);

COMMENT ON TABLE bi.dim_rango_nota IS
'Clasifica los registros según el rango de nota de admisión informado en la fuente.';

COMMENT ON COLUMN bi.dim_rango_nota.id_rango_nota IS
'Llave subrogada de la dimensión de rango de nota.';

COMMENT ON COLUMN bi.dim_rango_nota.rango_nota IS
'Rango o categoría de nota de admisión; No Aplica y No Especificado deben conservarse como categorías diferentes cuando correspondan.';


-- =========================================================
-- 5. TABLA DE HECHOS: ADMISIONES
-- =========================================================

CREATE TABLE bi.fact_admisiones (
    id_admision BIGINT GENERATED ALWAYS AS IDENTITY,

    id_tiempo BIGINT NOT NULL,
    id_geografia BIGINT NOT NULL,
    id_colegio BIGINT NOT NULL,
    id_opcion BIGINT NOT NULL,
    id_perfil_estudiante BIGINT NOT NULL,
    id_forma_ingreso BIGINT NOT NULL,
    id_rango_nota BIGINT NOT NULL,

    cantidad_admisiones SMALLINT NOT NULL DEFAULT 1,

    nota_admision_original TEXT,
    nota_admision NUMERIC(8,2),

    hoja_origen TEXT NOT NULL,
    fila_origen INTEGER NOT NULL,
    fecha_carga TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT pk_fact_admisiones
        PRIMARY KEY (id_admision),

    CONSTRAINT fk_fact_admisiones_tiempo
        FOREIGN KEY (id_tiempo)
        REFERENCES bi.dim_tiempo (id_tiempo),

    CONSTRAINT fk_fact_admisiones_geografia
        FOREIGN KEY (id_geografia)
        REFERENCES bi.dim_geografia (id_geografia),

    CONSTRAINT fk_fact_admisiones_colegio
        FOREIGN KEY (id_colegio)
        REFERENCES bi.dim_colegio (id_colegio),

    CONSTRAINT fk_fact_admisiones_opcion
        FOREIGN KEY (id_opcion)
        REFERENCES bi.dim_opcion (id_opcion),

    CONSTRAINT fk_fact_admisiones_perfil_estudiante
        FOREIGN KEY (id_perfil_estudiante)
        REFERENCES bi.dim_perfil_estudiante (id_perfil_estudiante),

    CONSTRAINT fk_fact_admisiones_forma_ingreso
        FOREIGN KEY (id_forma_ingreso)
        REFERENCES bi.dim_forma_ingreso (id_forma_ingreso),

    CONSTRAINT fk_fact_admisiones_rango_nota
        FOREIGN KEY (id_rango_nota)
        REFERENCES bi.dim_rango_nota (id_rango_nota),

    CONSTRAINT ck_fact_admisiones_cantidad
        CHECK (cantidad_admisiones = 1),

    CONSTRAINT ck_fact_admisiones_fila_origen
        CHECK (fila_origen >= 2),

    CONSTRAINT uq_fact_admisiones_origen
        UNIQUE (hoja_origen, fila_origen)
);

COMMENT ON TABLE bi.fact_admisiones IS
'Tabla de hechos del proceso de admisiones. Una fila representa un registro de admisión disponible en la fuente y no necesariamente una persona única.';

COMMENT ON COLUMN bi.fact_admisiones.id_admision IS
'Llave subrogada técnica del registro de admisión; no identifica a una persona.';

COMMENT ON COLUMN bi.fact_admisiones.cantidad_admisiones IS
'Medida aditiva unitaria. Cada registro aporta exactamente una admisión.';

COMMENT ON COLUMN bi.fact_admisiones.nota_admision_original IS
'Valor original de Nota de Admisión conservado como texto para trazabilidad.';

COMMENT ON COLUMN bi.fact_admisiones.nota_admision IS
'Valor numérico de Nota de Admisión cuando la conversión es válida.';

COMMENT ON COLUMN bi.fact_admisiones.hoja_origen IS
'Nombre de la hoja del archivo Excel de procedencia.';

COMMENT ON COLUMN bi.fact_admisiones.fila_origen IS
'Número de fila de procedencia en el archivo Excel, incluyendo el encabezado.';

COMMENT ON COLUMN bi.fact_admisiones.fecha_carga IS
'Fecha y hora de inserción del registro en el Data Warehouse.';


-- =========================================================
-- 6. INDICES DE APOYO PARA LAS LLAVES FORANEAS
-- =========================================================

CREATE INDEX idx_fact_admisiones_tiempo
    ON bi.fact_admisiones (id_tiempo);

CREATE INDEX idx_fact_admisiones_geografia
    ON bi.fact_admisiones (id_geografia);

CREATE INDEX idx_fact_admisiones_colegio
    ON bi.fact_admisiones (id_colegio);

CREATE INDEX idx_fact_admisiones_opcion
    ON bi.fact_admisiones (id_opcion);

CREATE INDEX idx_fact_admisiones_perfil_estudiante
    ON bi.fact_admisiones (id_perfil_estudiante);

CREATE INDEX idx_fact_admisiones_forma_ingreso
    ON bi.fact_admisiones (id_forma_ingreso);

CREATE INDEX idx_fact_admisiones_rango_nota
    ON bi.fact_admisiones (id_rango_nota);

COMMIT;
