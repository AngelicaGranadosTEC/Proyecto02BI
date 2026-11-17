-- =====================================================================
-- DDL del componente B · versión SQLite para pruebas locales
-- Misma estructura que sql/postgresql/ddl_componente_b.sql.
-- El ETL abre el archivo con ATTACH ... AS bi, por eso las tablas se
-- consultan como bi.<tabla>, igual que en PostgreSQL.
-- =====================================================================

CREATE TABLE IF NOT EXISTS bi.dim_tiempo (
    id_tiempo   INTEGER PRIMARY KEY,
    anio        INTEGER NOT NULL UNIQUE CHECK (anio BETWEEN 1900 AND 2100)
);

CREATE TABLE IF NOT EXISTS bi.dim_geografia (
    id_geografia             INTEGER PRIMARY KEY,
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
    id_colegio           INTEGER PRIMARY KEY,
    modalidad            TEXT NOT NULL,
    tipo_financiamiento  TEXT NOT NULL,
    UNIQUE (modalidad, tipo_financiamiento)
);

CREATE TABLE IF NOT EXISTS bi.dim_opcion (
    id_opcion       INTEGER PRIMARY KEY,
    codigo_opcion   INTEGER NOT NULL UNIQUE CHECK (codigo_opcion IN (1, 2)),
    opcion          TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS bi.dim_forma_ingreso (
    id_forma_ingreso  INTEGER PRIMARY KEY,
    forma_ingreso     TEXT NOT NULL UNIQUE,
    valor_origen      TEXT NOT NULL,
    tipo_via          TEXT NOT NULL,
    exige_nota        BOOLEAN NOT NULL
);

CREATE TABLE IF NOT EXISTS bi.dim_rango_nota (
    id_rango_nota    INTEGER PRIMARY KEY,
    rango_nota       TEXT NOT NULL UNIQUE,
    limite_inferior  NUMERIC,
    limite_superior  NUMERIC,
    orden            INTEGER NOT NULL,
    tipo_rango       TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS bi.dim_perfil_estudiante (
    id_perfil_estudiante  INTEGER PRIMARY KEY,
    condicion_academica   TEXT NOT NULL,
    rango_edad            TEXT NOT NULL,
    orden_rango_edad      INTEGER NOT NULL,
    nacionalidad          TEXT NOT NULL,
    grupo_nacionalidad    TEXT NOT NULL,
    tipo_diploma          TEXT NOT NULL,
    UNIQUE (condicion_academica, rango_edad, nacionalidad, tipo_diploma)
);

CREATE TABLE IF NOT EXISTS bi.fact_admisiones (
    id_admision             INTEGER PRIMARY KEY,
    id_tiempo               INTEGER NOT NULL REFERENCES dim_tiempo (id_tiempo),
    id_geografia            INTEGER NOT NULL REFERENCES dim_geografia (id_geografia),
    id_colegio              INTEGER NOT NULL REFERENCES dim_colegio (id_colegio),
    id_opcion               INTEGER NOT NULL REFERENCES dim_opcion (id_opcion),
    id_perfil_estudiante    INTEGER NOT NULL REFERENCES dim_perfil_estudiante (id_perfil_estudiante),
    id_forma_ingreso        INTEGER NOT NULL REFERENCES dim_forma_ingreso (id_forma_ingreso),
    id_rango_nota           INTEGER NOT NULL REFERENCES dim_rango_nota (id_rango_nota),
    cantidad_admisiones     INTEGER NOT NULL DEFAULT 1 CHECK (cantidad_admisiones = 1),
    nota_admision_original  TEXT,
    nota_admision           NUMERIC,
    estado_nota             TEXT NOT NULL,
    es_nota_valida          BOOLEAN NOT NULL,
    hoja_origen             TEXT NOT NULL,
    fila_origen             INTEGER NOT NULL CHECK (fila_origen >= 2),
    id_lote                 TEXT NOT NULL,
    fecha_carga             TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (hoja_origen, fila_origen)
);

CREATE TABLE IF NOT EXISTS bi.etl_bitacora (
    id_evento   INTEGER PRIMARY KEY,
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
    id_validacion  INTEGER PRIMARY KEY,
    id_lote        TEXT NOT NULL,
    componente     TEXT NOT NULL,
    codigo         TEXT NOT NULL,
    prueba         TEXT NOT NULL,
    esperado       TEXT,
    obtenido       TEXT,
    estado         TEXT NOT NULL,
    detalle        TEXT
);
