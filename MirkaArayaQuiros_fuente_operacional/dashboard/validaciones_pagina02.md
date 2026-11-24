# Validaciones — Página 02 (PN1)

Las siguientes cifras corresponden al modelo utilizado para diseñar la página 02. Si el grupo modifica los ETL, sus exclusiones o la fuente, **se deben volver a validar** antes de entregar.

## Conteos de referencia (sin filtros)

| Indicador | Registros esperados |
|---|---:|
| Solicitudes, primera opción (K01) | 2.725 |
| Solicitudes, segunda opción (K02) | 2.129 |
| Total solicitudes | 4.854 |
| Admisiones, primera opción | 659 |
| Admisiones, segunda opción | 83 |
| Total admisiones | 742 |

## Comprobaciones por año

| Año | Solicitudes (ambas opciones) | Admisiones (ambas opciones) | Observación |
|---|---:|---:|---|
| 2020 | 942 | 116 | Ambas opciones con registros |
| 2021 | 434 | 97 | Sin registros de admisiones de segunda opción |
| 2022 | 351 | 107 | Sin registros de segunda opción en ambas fuentes |
| 2023 | 284 | 90 | Sin registros de segunda opción en ambas fuentes |
| 2024 | 379 | 103 | Sin registros de segunda opción en ambas fuentes |
| 2025 | 1.170 | 110 | Ambas opciones con registros |
| 2026 | 1.294 | 119 | Ambas opciones con registros |

## Pruebas de funcionamiento

- [ ] El total sin filtros es 4.854 solicitudes y 742 admisiones.
- [ ] El filtro de año 2026 muestra 1.294 solicitudes y 119 admisiones.
- [ ] El filtro de año 2023 muestra 284 solicitudes y 90 admisiones.
- [ ] Al expandir la matriz se puede distinguir primera y segunda opción.
- [ ] Las combinaciones año/opción sin registros se interpretan como **sin datos**, no como ceros confirmados.
- [ ] La tarjeta de solicitudes muestra el total exacto sin abreviarlo como «5 mil».
- [ ] La página tiene cinco objetos de información, un segmentador y nota metodológica.
- [ ] Todas las visualizaciones responden al filtro y se han guardado en el PBIX compartido.

**Precaución:** Las cifras representan registros agregados y no tasas oficiales de admisión ni personas únicas. No hay llave de unión individual entre `fact_solicitudes` y `fact_admisiones`.
