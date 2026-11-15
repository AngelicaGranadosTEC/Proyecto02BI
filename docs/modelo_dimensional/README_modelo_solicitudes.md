# Persona 3 — Modelo dimensional de solicitudes

Proyecto 02 — Inteligencia de Negocios, TEC  
Componente: solicitudes de ingreso a ATI  
Esquema PostgreSQL: `bi`  
Base utilizada durante la verificación local: `dw_proyecto02_bi_tec`

## Alcance

Esta carpeta contiene los scripts SQL, documentación y diagrama correspondientes al componente de Persona 3: `bi.dim_tiempo`, `bi.dim_geografia`, `bi.dim_colegio` y `bi.fact_solicitudes`.

El diseño integrado contempla siete dimensiones. Las cuatro dimensiones asignadas a Persona 4 (`dim_opcion`, `dim_perfil_estudiante`, `dim_forma_ingreso` y `dim_rango_nota`) están representadas como referencias lógicas en `fact_solicitudes`; sus tablas y restricciones FOREIGN KEY deben integrarse cuando estén implementadas.

## Fuente operacional

La fuente seleccionada es `Datos proyecto BI v2.xlsx`. No combinar con `Datos proyecto BI.xlsx`, que corresponde a una extracción anterior.

**Confidencialidad:** no incluir archivos Excel originales, datos personales, datos institucionales sin autorización, contraseñas ni archivos `.env` en el repositorio. Confirmar que el repositorio GitHub tenga acceso restringido según los acuerdos del proyecto.

## Estructura

- `sql/01_crear_modelo_v1.sql`: crea las cuatro tablas iniciales y sus restricciones.
- `sql/02_ajustar_fact_solicitudes_integracion_v2.sql`: adapta `fact_solicitudes` para el modelo integrado; depende del primer script y requiere que la tabla esté vacía.
- `documentacion/Documentacion_modelo_dimensional_Persona3.docx` y `.md`: documentación actualizada para el informe.
- `documentacion/Diagrama_dimensional_solicitudes_Persona3.mmd`: diagrama Mermaid actualizado.
- `documentacion/*_v1*`: antecedentes de la primera versión del diseño; no sustituyen la documentación actualizada.
- `integracion/`: contrato dimensional aprobado y mensaje de coordinación con Persona 4.

## Reproducción desde cero

1. Crear la base de datos `dw_proyecto02_bi_tec` (o utilizar el nombre acordado por el equipo).
2. Conectarse a esa base de datos en pgAdmin.
3. Ejecutar `sql/01_crear_modelo_v1.sql`.
4. Sin cargar registros en `bi.fact_solicitudes`, ejecutar `sql/02_ajustar_fact_solicitudes_integracion_v2.sql`.
5. Verificar tablas, columnas y restricciones.

El segundo script depende del primero y no debe ejecutarse de forma aislada. Está diseñado para detenerse si `bi.fact_solicitudes` contiene registros. El primer script utiliza `CREATE TABLE IF NOT EXISTS`: si ya existen tablas `bi` con otra estructura, no las modifica; detenerse y revisar antes de continuar. No ejecutar el segundo script sobre una base con datos cargados sin revisar y respaldar primero.

## Estado verificado al 10/11/2026

- Las cuatro tablas del componente fueron creadas en PostgreSQL.
- Se verificaron claves primarias, restricciones UNIQUE y CHECK.
- Se verificaron tres claves foráneas desde `fact_solicitudes` hacia `dim_tiempo`, `dim_geografia` y `dim_colegio`.
- Se agregaron cuatro columnas BIGINT NOT NULL e índices para la futura integración con las dimensiones de Persona 4. Las cuatro restricciones FOREIGN KEY correspondientes están pendientes.
- En la verificación realizada, las cuatro tablas tenían cero registros. La carga ETL y las pruebas con datos reales siguen pendientes.

Este estado describe la verificación realizada en el entorno local; no afirma que el ETL o el dashboard estén terminados.

## Pendientes

- Integrar las cuatro dimensiones de Persona 4 y crear las restricciones FOREIGN KEY.
- Implementar y probar el ETL de solicitudes.
- Validar conteos, calidad, trazabilidad y reglas de transformación con los datos autorizados.
- Actualizar este README después de cada integración comprobada.
