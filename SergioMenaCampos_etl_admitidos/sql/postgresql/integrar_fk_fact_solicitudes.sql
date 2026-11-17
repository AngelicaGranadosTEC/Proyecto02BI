-- =====================================================================
-- Integración del modelo: cierra las cuatro FOREIGN KEY pendientes de
-- bi.fact_solicitudes (componente A) hacia las dimensiones del componente B.
--
-- Ejecutar UNA vez, de forma conjunta, cuando:
--   1. existan bi.dim_opcion, bi.dim_perfil_estudiante, bi.dim_forma_ingreso
--      y bi.dim_rango_nota (las crea sql/postgresql/ddl_componente_b.sql), y
--   2. el ETL A haya cargado fact_solicitudes con llaves válidas.
-- Si alguna fila de fact_solicitudes apunta a una llave inexistente, la
-- sentencia falla y no se agrega la restricción.
-- =====================================================================

ALTER TABLE bi.fact_solicitudes
    ADD CONSTRAINT fk_solicitudes_opcion
        FOREIGN KEY (id_opcion) REFERENCES bi.dim_opcion (id_opcion),
    ADD CONSTRAINT fk_solicitudes_perfil
        FOREIGN KEY (id_perfil_estudiante) REFERENCES bi.dim_perfil_estudiante (id_perfil_estudiante),
    ADD CONSTRAINT fk_solicitudes_forma_ingreso
        FOREIGN KEY (id_forma_ingreso) REFERENCES bi.dim_forma_ingreso (id_forma_ingreso),
    ADD CONSTRAINT fk_solicitudes_rango_nota
        FOREIGN KEY (id_rango_nota) REFERENCES bi.dim_rango_nota (id_rango_nota);
