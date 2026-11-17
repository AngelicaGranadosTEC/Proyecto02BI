-- =====================================================================
-- Proyecto 02 · TI-6900 Inteligencia de Negocios · Escuela de ATI (TEC)
-- DDL del componente B (admisiones) · PostgreSQL · esquema bi
--
-- Sigue las convenciones del componente A ya implementado (Persona 3):
-- llaves subrogadas BIGINT por identidad con prefijo id_, atributos
-- categóricos TEXT, UNIQUE compuesto sobre los atributos naturales,
-- hoja_origen + fila_origen para la trazabilidad.
--
-- Las dimensiones compartidas se declaran con IF NOT EXISTS y la misma
-- definición del componente A: si ya existen, no se modifican.
-- Las dimensiones del componente B y fact_admisiones son la propuesta de
-- implementación para el diseño de la Persona 4.
-- =====================================================================

CREATE SCHEMA IF NOT EXISTS bi;

-- ---------- Dimensiones compartidas (definición del componente A) ----------
CREATE TABLE IF NOT EXISTS bi.dim_tiempo (
    id_tiempo   BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    anio        SMALLINT NOT NULL UNIQUE CHECK (anio BETWEEN 1900 AND 2100)
);

CREATE TABLE IF NOT EXISTS bi.dim_geografia (
    id_geografia             BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    zona_residencia          TEXT NOT NULL,
    region_planificacion     TEXT NOT NULL,
    provincia                TEXT NOT NULL,
    canton                   TEXT NOT NULL,
    distrito                 TEXT NOT NULL,
    nivel_desarrollo_social  TEXT NOT NULL,
    zona_gam                 TEXT NOT NULL,
    UNIQUE (zona_residencia, region_planificacion, provincia, canton, distrito,
            nivel_desarrollo_social, zona_gam)
);

CREATE TABLE IF NOT EXISTS bi.dim_colegio (
    id_colegio           BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    modalidad            TEXT NOT NULL,
    tipo_financiamiento  TEXT NOT NULL,
    UNIQUE (modalidad, tipo_financiamiento)
);

-- ---------- Dimensiones del componente B ----------
CREATE TABLE IF NOT EXISTS bi.dim_opcion (
    id_opcion       BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    codigo_opcion   SMALLINT NOT NULL UNIQUE CHECK (codigo_opcion IN (1, 2)),
    opcion          TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS bi.dim_forma_ingreso (
    id_forma_ingreso  BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    forma_ingreso     TEXT NOT NULL UNIQUE,   -- etiqueta homologada
    valor_origen      TEXT NOT NULL,          -- valor tal como viene de Saiku OLAP
    tipo_via          TEXT NOT NULL,          -- 'Ordinaria' | 'Otra vía' | 'No especificado' | 'No clasificada'
    exige_nota        BOOLEAN NOT NULL        -- TRUE si la vía espera una nota numérica
);

CREATE TABLE IF NOT EXISTS bi.dim_rango_nota (
    id_rango_nota    BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    rango_nota       TEXT NOT NULL UNIQUE,    -- '650-699', 'No aplica', ...
    limite_inferior  NUMERIC(8,2),            -- NULL en categorías especiales
    limite_superior  NUMERIC(8,2),
    orden            SMALLINT NOT NULL,
    tipo_rango       TEXT NOT NULL            -- 'Intervalo' | 'Categoría especial'
);

CREATE TABLE IF NOT EXISTS bi.dim_perfil_estudiante (
    id_perfil_estudiante  BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    condicion_academica   TEXT NOT NULL,      -- 'En secundaria' | 'Graduado de secundaria'
    rango_edad            TEXT NOT NULL,
    orden_rango_edad      SMALLINT NOT NULL,
    nacionalidad          TEXT NOT NULL,
    grupo_nacionalidad    TEXT NOT NULL,      -- 'Costarricense' | 'Extranjera' | 'No especificado'
    tipo_diploma          TEXT NOT NULL,
    UNIQUE (condicion_academica, rango_edad, nacionalidad, tipo_diploma)
);

-- ---------- Tabla de hechos del componente B ----------
-- Granularidad: un registro por fila de las hojas «Admitidos primera opción»
-- y «Admitidos segunda opción»; cuenta registros, no personas únicas.
CREATE TABLE IF NOT EXISTS bi.fact_admisiones (
    id_admision             BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_tiempo               BIGINT NOT NULL REFERENCES bi.dim_tiempo (id_tiempo),
    id_geografia            BIGINT NOT NULL REFERENCES bi.dim_geografia (id_geografia),
    id_colegio              BIGINT NOT NULL REFERENCES bi.dim_colegio (id_colegio),
    id_opcion               BIGINT NOT NULL REFERENCES bi.dim_opcion (id_opcion),
    id_perfil_estudiante    BIGINT NOT NULL REFERENCES bi.dim_perfil_estudiante (id_perfil_estudiante),
    id_forma_ingreso        BIGINT NOT NULL REFERENCES bi.dim_forma_ingreso (id_forma_ingreso),
    id_rango_nota           BIGINT NOT NULL REFERENCES bi.dim_rango_nota (id_rango_nota),
    cantidad_admisiones     SMALLINT NOT NULL DEFAULT 1 CHECK (cantidad_admisiones = 1),
    nota_admision_original  TEXT,
    nota_admision           NUMERIC(8,2),       -- NULL si el valor no es numérico
    estado_nota             TEXT NOT NULL,      -- 'Numérica en rango' | 'Fuera de rango' | 'Cero' | 'No aplica' | 'No especificado'
    es_nota_valida          BOOLEAN NOT NULL,   -- criterio común de K05/K06
    hoja_origen             TEXT NOT NULL,
    fila_origen             INTEGER NOT NULL CHECK (fila_origen >= 2),
    id_lote                 TEXT NOT NULL,
    fecha_carga             TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (hoja_origen, fila_origen)
);

CREATE INDEX IF NOT EXISTS ix_fact_adm_tiempo  ON bi.fact_admisiones (id_tiempo);
CREATE INDEX IF NOT EXISTS ix_fact_adm_opcion  ON bi.fact_admisiones (id_opcion);
CREATE INDEX IF NOT EXISTS ix_fact_adm_forma   ON bi.fact_admisiones (id_forma_ingreso);
CREATE INDEX IF NOT EXISTS ix_fact_adm_perfil  ON bi.fact_admisiones (id_perfil_estudiante);

-- ---------- Tablas de control del ETL ----------
CREATE TABLE IF NOT EXISTS bi.etl_bitacora (
    id_evento   BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_lote     TEXT NOT NULL,
    componente  TEXT NOT NULL,
    paso        TEXT NOT NULL,
    inicio      TEXT NOT NULL,
    fin         TEXT NOT NULL,
    filas       INTEGER,
    estado      TEXT NOT NULL,
    detalle     TEXT
);

CREATE TABLE IF NOT EXISTS bi.etl_validacion (
    id_validacion  BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_lote        TEXT NOT NULL,
    componente     TEXT NOT NULL,
    codigo         TEXT NOT NULL,
    prueba         TEXT NOT NULL,
    esperado       TEXT,
    obtenido       TEXT,
    estado         TEXT NOT NULL,   -- 'OK' | 'ADVERTENCIA' | 'ERROR'
    detalle        TEXT
);
