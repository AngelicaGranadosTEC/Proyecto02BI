/*
Proyecto 02 - Inteligencia de Negocios (TEC)
Persona 3 - Ajuste de fact_solicitudes para integracion dimensional
Version: 2.0

PRECONDICIONES:
1. Ejecutar en la base dw_proyecto02_bi_tec.
2. El esquema debe ser bi.
3. La tabla bi.fact_solicitudes debe existir.
4. La tabla debe estar vacia. El bloque DO detiene el script si encuentra registros.

IMPORTANTE:
- No crea las cuatro dimensiones asignadas a Persona 4.
- Agrega sus columnas FK como BIGINT NOT NULL, pero NO crea aun las restricciones
  FOREIGN KEY correspondientes. Estas se agregaran cuando existan las dimensiones.
- Conserva las columnas de trazabilidad y las notas originales.
- Los atributos descriptivos retirados permanecen en el archivo fuente original.
*/

BEGIN;

DO $$
DECLARE
    v_registros BIGINT;
BEGIN
    IF to_regclass('bi.fact_solicitudes') IS NULL THEN
        RAISE EXCEPTION 'No existe la tabla bi.fact_solicitudes. Verifique la base de datos y el esquema.';
    END IF;

    SELECT COUNT(*) INTO v_registros
    FROM bi.fact_solicitudes;

    IF v_registros > 0 THEN
        RAISE EXCEPTION
            'Operacion cancelada: bi.fact_solicitudes contiene % registros. No se modifico la tabla.',
            v_registros;
    END IF;
END $$;

-- 1. Agregar las claves que conectaran con las dimensiones de Persona 4.
ALTER TABLE bi.fact_solicitudes
    ADD COLUMN IF NOT EXISTS id_opcion BIGINT,
    ADD COLUMN IF NOT EXISTS id_perfil_estudiante BIGINT,
    ADD COLUMN IF NOT EXISTS id_forma_ingreso BIGINT,
    ADD COLUMN IF NOT EXISTS id_rango_nota BIGINT;

-- La tabla fue validada como vacia; por eso estas columnas pueden definirse NOT NULL.
ALTER TABLE bi.fact_solicitudes
    ALTER COLUMN id_opcion SET NOT NULL,
    ALTER COLUMN id_perfil_estudiante SET NOT NULL,
    ALTER COLUMN id_forma_ingreso SET NOT NULL,
    ALTER COLUMN id_rango_nota SET NOT NULL;

-- 2. Retirar atributos descriptivos que, según el diseño aprobado, pertenecen a dimensiones.
ALTER TABLE bi.fact_solicitudes
    DROP COLUMN IF EXISTS opcion_carrera,
    DROP COLUMN IF EXISTS rango_edad,
    DROP COLUMN IF EXISTS forma_ingreso,
    DROP COLUMN IF EXISTS rango_nota_admision,
    DROP COLUMN IF EXISTS nacionalidad,
    DROP COLUMN IF EXISTS tipo_estudiante,
    DROP COLUMN IF EXISTS tipo_diploma_secundaria,
    DROP COLUMN IF EXISTS solicitud_adecuacion;

-- 3. Índices para las futuras relaciones con las dimensiones de Persona 4.
CREATE INDEX IF NOT EXISTS ix_fact_solicitudes_id_opcion
    ON bi.fact_solicitudes (id_opcion);

CREATE INDEX IF NOT EXISTS ix_fact_solicitudes_id_perfil_estudiante
    ON bi.fact_solicitudes (id_perfil_estudiante);

CREATE INDEX IF NOT EXISTS ix_fact_solicitudes_id_forma_ingreso
    ON bi.fact_solicitudes (id_forma_ingreso);

CREATE INDEX IF NOT EXISTS ix_fact_solicitudes_id_rango_nota
    ON bi.fact_solicitudes (id_rango_nota);

-- 4. Documentar explícitamente que las FK se completarán al integrar las dimensiones.
COMMENT ON COLUMN bi.fact_solicitudes.id_opcion IS
    'FK lógica pendiente de restricción física hacia bi.dim_opcion(id_opcion); dimensión a cargo de Persona 4.';

COMMENT ON COLUMN bi.fact_solicitudes.id_perfil_estudiante IS
    'FK lógica pendiente de restricción física hacia bi.dim_perfil_estudiante(id_perfil_estudiante); dimensión a cargo de Persona 4.';

COMMENT ON COLUMN bi.fact_solicitudes.id_forma_ingreso IS
    'FK lógica pendiente de restricción física hacia bi.dim_forma_ingreso(id_forma_ingreso); dimensión a cargo de Persona 4.';

COMMENT ON COLUMN bi.fact_solicitudes.id_rango_nota IS
    'FK lógica pendiente de restricción física hacia bi.dim_rango_nota(id_rango_nota); dimensión a cargo de Persona 4.';

COMMENT ON TABLE bi.fact_solicitudes IS
    'Hecho de solicitudes. Granularidad: un registro por cada registro de solicitud disponible en la fuente. Integra siete dimensiones cuando se creen las dimensiones asignadas a Persona 4.';

COMMIT;

-- 5. Consulta de verificacion posterior (ejecutar y revisar el resultado).
SELECT
    table_name,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns
WHERE table_schema = 'bi'
  AND table_name = 'fact_solicitudes'
ORDER BY ordinal_position;
