-- Proyecto 02 - Inteligencia de Negocios
-- Integración de componentes A y B
-- Archivo: 04_integrar_fact_solicitudes_fks_v1.sql
--
-- Objetivo:
--   Completar las relaciones físicas pendientes de bi.fact_solicitudes
--   hacia las cuatro dimensiones implementadas por Persona 4.
--
-- Dependencias:
--   Deben existir previamente:
--     bi.fact_solicitudes
--     bi.dim_opcion
--     bi.dim_perfil_estudiante
--     bi.dim_forma_ingreso
--     bi.dim_rango_nota
--
-- Las columnas id_opcion, id_perfil_estudiante,
-- id_forma_ingreso e id_rango_nota ya deben existir
-- en bi.fact_solicitudes como BIGINT NOT NULL.

BEGIN;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_constraint
        WHERE conname = 'fk_fact_solicitudes_opcion'
          AND conrelid = 'bi.fact_solicitudes'::regclass
    ) THEN
        ALTER TABLE bi.fact_solicitudes
            ADD CONSTRAINT fk_fact_solicitudes_opcion
            FOREIGN KEY (id_opcion)
            REFERENCES bi.dim_opcion (id_opcion);
    END IF;
END
$$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_constraint
        WHERE conname = 'fk_fact_solicitudes_perfil_estudiante'
          AND conrelid = 'bi.fact_solicitudes'::regclass
    ) THEN
        ALTER TABLE bi.fact_solicitudes
            ADD CONSTRAINT fk_fact_solicitudes_perfil_estudiante
            FOREIGN KEY (id_perfil_estudiante)
            REFERENCES bi.dim_perfil_estudiante (id_perfil_estudiante);
    END IF;
END
$$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_constraint
        WHERE conname = 'fk_fact_solicitudes_forma_ingreso'
          AND conrelid = 'bi.fact_solicitudes'::regclass
    ) THEN
        ALTER TABLE bi.fact_solicitudes
            ADD CONSTRAINT fk_fact_solicitudes_forma_ingreso
            FOREIGN KEY (id_forma_ingreso)
            REFERENCES bi.dim_forma_ingreso (id_forma_ingreso);
    END IF;
END
$$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_constraint
        WHERE conname = 'fk_fact_solicitudes_rango_nota'
          AND conrelid = 'bi.fact_solicitudes'::regclass
    ) THEN
        ALTER TABLE bi.fact_solicitudes
            ADD CONSTRAINT fk_fact_solicitudes_rango_nota
            FOREIGN KEY (id_rango_nota)
            REFERENCES bi.dim_rango_nota (id_rango_nota);
    END IF;
END
$$;

COMMIT;

-- Verificación:
SELECT
    conname AS restriccion,
    conrelid::regclass AS tabla,
    confrelid::regclass AS referencia
FROM pg_constraint
WHERE connamespace = 'bi'::regnamespace
  AND contype = 'f'
ORDER BY conrelid::regclass::text, conname;
