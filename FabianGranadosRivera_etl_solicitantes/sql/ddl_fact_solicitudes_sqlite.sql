-- Modelo de prueba local compatible con el modelo de solicitudes de Pamela, ajustado a siete dimensiones.
-- Las dimensiones compartidas ya se crean con el DDL SQLite de Sergio.
CREATE TABLE IF NOT EXISTS bi.fact_solicitudes (
 id_solicitud INTEGER PRIMARY KEY,
 id_tiempo INTEGER NOT NULL REFERENCES dim_tiempo(id_tiempo),
 id_geografia INTEGER NOT NULL REFERENCES dim_geografia(id_geografia),
 id_colegio INTEGER NOT NULL REFERENCES dim_colegio(id_colegio),
 id_opcion INTEGER NOT NULL REFERENCES dim_opcion(id_opcion),
 id_perfil_estudiante INTEGER NOT NULL REFERENCES dim_perfil_estudiante(id_perfil_estudiante),
 id_forma_ingreso INTEGER NOT NULL REFERENCES dim_forma_ingreso(id_forma_ingreso),
 id_rango_nota INTEGER NOT NULL REFERENCES dim_rango_nota(id_rango_nota),
 cantidad_solicitudes INTEGER NOT NULL DEFAULT 1 CHECK(cantidad_solicitudes=1),
 nota_admision_original TEXT,
 nota_admision NUMERIC,
 nota_iv_ciclo_original TEXT,
 nota_iv_ciclo NUMERIC,
 hoja_origen TEXT NOT NULL,
 fila_origen INTEGER NOT NULL CHECK(fila_origen>=2),
 fecha_carga TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
 UNIQUE(hoja_origen,fila_origen)
);
