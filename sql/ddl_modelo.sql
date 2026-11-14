-- =====================================================================
-- Proyecto 02 · TI-6900 Inteligencia de Negocios · Escuela de ATI (TEC)
-- DDL de las tablas que alimenta el ETL B (admitidos)
-- Motor de referencia: SQLite 3 (sintaxis SQL estándar; portable a PostgreSQL)
--
-- IMPORTANTE: este DDL es la propuesta del componente B para el contrato de
-- datos. Las estructuras de fact_admisiones y de las dimensiones B son
-- diseño de la Persona 4; las dimensiones compartidas (tiempo, geografía y
-- colegio) son diseño de la Persona 3. Si el contrato final cambia nombres o
-- tipos, se ajusta este archivo y el diccionario COLUMNAS_* del ETL.
-- Todas las sentencias usan IF NOT EXISTS para que la ejecución sea idempotente
-- y no choque con el DDL del ETL A si este se ejecuta primero.
-- =====================================================================

PRAGMA foreign_keys = ON;

-- ---------- Dimensiones compartidas (componente A) ----------
CREATE TABLE IF NOT EXISTS dim_tiempo (
    sk_tiempo        INTEGER PRIMARY KEY,
    anio             INTEGER NOT NULL UNIQUE,
    etiqueta_anio    TEXT    NOT NULL
);

CREATE TABLE IF NOT EXISTS dim_geografia (
    sk_geografia            INTEGER PRIMARY KEY,
    clave_natural           TEXT NOT NULL UNIQUE,
    provincia               TEXT NOT NULL,
    canton                  TEXT NOT NULL,
    distrito                TEXT NOT NULL,
    region_planificacion    TEXT NOT NULL,
    zona_residencia         TEXT NOT NULL,
    nivel_desarrollo_social TEXT NOT NULL,
    zona_gam                TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS dim_colegio (
    sk_colegio           INTEGER PRIMARY KEY,
    clave_natural        TEXT NOT NULL UNIQUE,
    modalidad            TEXT NOT NULL,
    tipo_financiamiento  TEXT NOT NULL
);

-- ---------- Dimensiones del componente B ----------
CREATE TABLE IF NOT EXISTS dim_opcion (
    sk_opcion        INTEGER PRIMARY KEY,
    codigo_opcion    INTEGER NOT NULL UNIQUE,   -- 1 = primera, 2 = segunda
    opcion           TEXT    NOT NULL
);

CREATE TABLE IF NOT EXISTS dim_forma_ingreso (
    sk_forma_ingreso   INTEGER PRIMARY KEY,
    clave_natural      TEXT NOT NULL UNIQUE,
    forma_ingreso      TEXT NOT NULL,            -- etiqueta homologada
    valor_origen       TEXT NOT NULL,            -- valor tal como viene de Saiku
    tipo_via           TEXT NOT NULL,            -- 'Examen de admisión' | 'Vía especial' | 'No especificado'
    exige_nota         INTEGER NOT NULL CHECK (exige_nota IN (0, 1))  -- 1 = se espera nota numérica
);

CREATE TABLE IF NOT EXISTS dim_rango_nota (
    sk_rango_nota      INTEGER PRIMARY KEY,
    clave_natural      TEXT NOT NULL UNIQUE,
    rango_nota         TEXT NOT NULL,            -- '650-699', 'No aplica', ...
    limite_inferior    REAL,                     -- NULL en categorías especiales
    limite_superior    REAL,
    orden              INTEGER NOT NULL,
    tipo_rango         TEXT NOT NULL             -- 'Intervalo' | 'Categoría especial'
);

CREATE TABLE IF NOT EXISTS dim_perfil_estudiante (
    sk_perfil             INTEGER PRIMARY KEY,
    clave_natural         TEXT NOT NULL UNIQUE,
    condicion_academica   TEXT NOT NULL,         -- 'En secundaria' | 'Graduado de secundaria'
    rango_edad            TEXT NOT NULL,
    orden_rango_edad      INTEGER NOT NULL,
    nacionalidad          TEXT NOT NULL,
    grupo_nacionalidad    TEXT NOT NULL,         -- 'Costarricense' | 'Extranjera' | 'No especificado'
    tipo_diploma          TEXT NOT NULL
);

-- ---------- Tabla de hechos del componente B ----------
-- Granularidad: un registro de admisión exportado por Saiku OLAP
-- (una fila de las hojas "Admitidos primera opción" o "Admitidos segunda opción").
CREATE TABLE IF NOT EXISTS fact_admisiones (
    sk_admision          INTEGER PRIMARY KEY,
    sk_tiempo            INTEGER NOT NULL REFERENCES dim_tiempo(sk_tiempo),
    sk_geografia         INTEGER NOT NULL REFERENCES dim_geografia(sk_geografia),
    sk_colegio           INTEGER NOT NULL REFERENCES dim_colegio(sk_colegio),
    sk_opcion            INTEGER NOT NULL REFERENCES dim_opcion(sk_opcion),
    sk_perfil            INTEGER NOT NULL REFERENCES dim_perfil_estudiante(sk_perfil),
    sk_forma_ingreso     INTEGER NOT NULL REFERENCES dim_forma_ingreso(sk_forma_ingreso),
    sk_rango_nota        INTEGER NOT NULL REFERENCES dim_rango_nota(sk_rango_nota),
    nota_admision        REAL,                   -- NULL cuando no aplica / no es numérica
    estado_nota          TEXT NOT NULL,          -- 'Válida' | 'No aplica' | 'Cero' | 'No especificado' | 'Fuera de rango'
    es_nota_valida       INTEGER NOT NULL CHECK (es_nota_valida IN (0, 1)),
    cantidad_admisiones  INTEGER NOT NULL DEFAULT 1,
    hoja_origen          TEXT NOT NULL,          -- linaje
    fila_origen          INTEGER NOT NULL,       -- fila de Excel (encabezado = fila 1)
    id_lote              TEXT NOT NULL,
    fecha_carga          TEXT NOT NULL,
    UNIQUE (hoja_origen, fila_origen)            -- impide cargas duplicadas
);

-- ---------- Tablas de control del ETL ----------
CREATE TABLE IF NOT EXISTS etl_bitacora (
    id_evento     INTEGER PRIMARY KEY,
    id_lote       TEXT NOT NULL,
    componente    TEXT NOT NULL,
    paso          TEXT NOT NULL,
    inicio        TEXT NOT NULL,
    fin           TEXT NOT NULL,
    filas         INTEGER,
    estado        TEXT NOT NULL,
    detalle       TEXT
);

CREATE TABLE IF NOT EXISTS etl_validacion (
    id_validacion INTEGER PRIMARY KEY,
    id_lote       TEXT NOT NULL,
    componente    TEXT NOT NULL,
    codigo        TEXT NOT NULL,
    prueba        TEXT NOT NULL,
    esperado      TEXT,
    obtenido      TEXT,
    estado        TEXT NOT NULL,            -- 'OK' | 'ADVERTENCIA' | 'ERROR'
    detalle       TEXT
);
