-- Consultas de evidencia del ETL B (esquema bi, válidas en PostgreSQL y en SQLite)

-- 1. Conteo por hoja de origen (debe ser 659 y 83)
SELECT hoja_origen, COUNT(*) AS registros
FROM bi.fact_admisiones
GROUP BY hoja_origen;

-- 2. Admisiones por año y opción (comparar con la hoja de origen)
SELECT t.anio, o.opcion, COUNT(*) AS admisiones
FROM bi.fact_admisiones f
JOIN bi.dim_tiempo t ON f.id_tiempo = t.id_tiempo
JOIN bi.dim_opcion o ON f.id_opcion = o.id_opcion
GROUP BY t.anio, o.opcion
ORDER BY t.anio, o.opcion;

-- 3. Hechos sin dimensión (debe devolver 0)
SELECT COUNT(*) AS huerfanos
FROM bi.fact_admisiones f
LEFT JOIN bi.dim_forma_ingreso fi ON f.id_forma_ingreso = fi.id_forma_ingreso
LEFT JOIN bi.dim_perfil_estudiante p ON f.id_perfil_estudiante = p.id_perfil_estudiante
LEFT JOIN bi.dim_rango_nota r ON f.id_rango_nota = r.id_rango_nota
WHERE fi.id_forma_ingreso IS NULL OR p.id_perfil_estudiante IS NULL OR r.id_rango_nota IS NULL;

-- 4. Formas de ingreso homologadas
SELECT fi.valor_origen, fi.forma_ingreso, fi.tipo_via, COUNT(*) AS admisiones
FROM bi.fact_admisiones f
JOIN bi.dim_forma_ingreso fi ON f.id_forma_ingreso = fi.id_forma_ingreso
GROUP BY fi.valor_origen, fi.forma_ingreso, fi.tipo_via
ORDER BY admisiones DESC;

-- 5. Estado de la nota y nota promedio válida (criterio K06)
SELECT estado_nota, COUNT(*) AS registros,
       SUM(CASE WHEN es_nota_valida THEN 1 ELSE 0 END) AS validas,
       ROUND(AVG(CASE WHEN es_nota_valida THEN nota_admision END), 2) AS promedio_valido
FROM bi.fact_admisiones
GROUP BY estado_nota;

-- 6. Resultado de validaciones del último lote del ETL B
SELECT codigo, prueba, esperado, obtenido, estado
FROM bi.etl_validacion
WHERE id_lote = (SELECT MAX(id_lote) FROM bi.etl_validacion WHERE componente = 'ETL_B');

-- 7. Bitácora del último lote del ETL B
SELECT paso, inicio, fin, filas, estado, detalle
FROM bi.etl_bitacora
WHERE id_lote = (SELECT MAX(id_lote) FROM bi.etl_bitacora WHERE componente = 'ETL_B');
