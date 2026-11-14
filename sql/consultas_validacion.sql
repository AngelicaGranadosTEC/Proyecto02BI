-- Consultas de evidencia del ETL B (ejecutar sobre data/dw/dw_ati.db)

-- 1. Conteo por hoja de origen (debe ser 659 y 83)
SELECT hoja_origen, COUNT(*) AS registros
FROM fact_admisiones GROUP BY hoja_origen;

-- 2. Admisiones por año y opción (comparar con la hoja de origen)
SELECT t.anio, o.opcion, COUNT(*) AS admisiones
FROM fact_admisiones f
JOIN dim_tiempo t USING (sk_tiempo)
JOIN dim_opcion o USING (sk_opcion)
GROUP BY t.anio, o.opcion ORDER BY t.anio, o.opcion;

-- 3. Hechos sin dimensión (debe devolver 0)
SELECT COUNT(*) AS huerfanos
FROM fact_admisiones f
LEFT JOIN dim_forma_ingreso fi USING (sk_forma_ingreso)
LEFT JOIN dim_perfil_estudiante p USING (sk_perfil)
LEFT JOIN dim_rango_nota r USING (sk_rango_nota)
WHERE fi.sk_forma_ingreso IS NULL OR p.sk_perfil IS NULL OR r.sk_rango_nota IS NULL;

-- 4. Formas de ingreso homologadas
SELECT fi.valor_origen, fi.forma_ingreso, fi.tipo_via, COUNT(*) AS admisiones
FROM fact_admisiones f JOIN dim_forma_ingreso fi USING (sk_forma_ingreso)
GROUP BY 1, 2, 3 ORDER BY admisiones DESC;

-- 5. Estado de la nota y nota promedio válida (criterio K06)
SELECT estado_nota, COUNT(*) AS registros, SUM(es_nota_valida) AS validas,
       ROUND(AVG(CASE WHEN es_nota_valida = 1 THEN nota_admision END), 2) AS promedio_valido
FROM fact_admisiones GROUP BY estado_nota;

-- 6. Resultado de validaciones del último lote
SELECT codigo, prueba, esperado, obtenido, estado
FROM etl_validacion
WHERE id_lote = (SELECT MAX(id_lote) FROM etl_validacion WHERE componente = 'ETL_B');

-- 7. Bitácora del último lote
SELECT paso, inicio, fin, filas, estado, detalle
FROM etl_bitacora
WHERE id_lote = (SELECT MAX(id_lote) FROM etl_bitacora WHERE componente = 'ETL_B');
