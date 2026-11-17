"""
Reglas de homologación de las dimensiones del componente B
(dim_forma_ingreso, dim_rango_nota, dim_perfil_estudiante) y de la nota de admisión.

Se separan en este módulo para que el ETL A (solicitantes) las importe y ambas tablas
de hechos usen exactamente los mismos miembros: estas dimensiones son conformadas.
"""
from __future__ import annotations

import pandas as pd

from comun import categoria_especial, clave, limpiar

# Catálogos de homologación (RT-B03, RT-B05, RT-B06)
CATALOGO_FORMA_INGRESO = {
    # clave canónica           etiqueta                     tipo_via      exige_nota
    "PUNTAJE ADMISION":       ("Puntaje de admisión",       "Ordinaria",  1),
    "EXENCION":               ("Exención",                  "Otra vía",   0),
    "REVALIDACION":           ("Revalidación",              "Otra vía",   1),
    "RECONOCIMIENTO DE MATERIAS": ("Reconocimiento de materias", "Otra vía", 1),
}

RANGOS_EDAD = {
    "0-17": ("Menor de 18", 1), "18-22": ("18 a 22", 2), "23-26": ("23 a 26", 3),
    "27-30": ("27 a 30", 4), "31-100": ("31 o más", 5),
}

CONDICION_ACADEMICA = {
    "ESTUDIANTE DE SECUNDARIA": "En secundaria",
    "GRADUADO DE SECUNDARIA": "Graduado de secundaria",
}

TIPO_DIPLOMA = {
    "ACADEMICO": "Académico", "MADUREZ": "Madurez", "A DISTANCIA": "A distancia",
    "PLAN DE ESTUDIOS": "Plan de estudios", "EXTRANJERO": "Extranjero",
    "NUEVAS OPORTUNIDADES": "Nuevas oportunidades",
    "CONCLUSION CICLO DIVERSIFICADO": "Conclusión ciclo diversificado",
}


def homologar_forma_ingreso(valor: str) -> dict:
    """RT-B03: homologación y clasificación de la forma de ingreso."""
    k = clave(valor)
    # El valor de origen "RECONOCIMIENTO DE MATERIAS  CI" llega truncado y con doble espacio:
    # se reconoce por prefijo para no depender del texto cortado por la exportación.
    for prefijo, (etiqueta, via, exige) in CATALOGO_FORMA_INGRESO.items():
        if k == prefijo or k.startswith(prefijo + " "):
            return dict(forma_ingreso=etiqueta, tipo_via=via, exige_nota=exige, clasificada=True)
    especial = categoria_especial(valor)
    return dict(forma_ingreso=especial or limpiar(valor).capitalize(),
                tipo_via="No especificado" if especial else "No clasificada",
                exige_nota=1, clasificada=False)


def clasificar_rango(valor: str) -> dict:
    """RT-B05: separa el intervalo 'min-max' en límites numéricos y asigna orden."""
    especial = categoria_especial(valor)
    if especial:
        return dict(rango_nota=especial, limite_inferior=None, limite_superior=None,
                    orden=98 if especial == "No aplica" else 99, tipo_rango="Categoría especial")
    partes = limpiar(valor).split("-")
    try:
        li, ls = float(partes[0]), float(partes[1])
    except (IndexError, ValueError):
        return dict(rango_nota=limpiar(valor), limite_inferior=None, limite_superior=None,
                    orden=97, tipo_rango="No reconocido")
    return dict(rango_nota=f"{int(li)}-{int(ls)}", limite_inferior=li, limite_superior=ls,
                orden=int(li), tipo_rango="Intervalo")


def evaluar_nota(valor: str, forma: dict, rango: dict) -> dict:
    """RT-B04: convierte la nota a número y le asigna un estado verificable."""
    especial = categoria_especial(valor)
    if especial:
        return dict(nota_admision=None, estado_nota=especial, es_nota_valida=0)
    try:
        nota = float(limpiar(valor).replace(",", "."))
    except ValueError:
        return dict(nota_admision=None, estado_nota="No numérica", es_nota_valida=0)
    if nota == 0:
        return dict(nota_admision=0.0, estado_nota="Cero", es_nota_valida=0)
    li, ls = rango["limite_inferior"], rango["limite_superior"]
    en_rango = li is not None and li <= nota < ls + 1      # '650-699' cubre [650, 700)
    estado = "Numérica en rango" if en_rango else "Fuera de rango"
    # Criterio común K05/K06: solo cuenta como válida la nota > 0 de la vía 'Puntaje de admisión'
    valida = int(en_rango and forma["forma_ingreso"] == "Puntaje de admisión")
    return dict(nota_admision=round(nota, 2), estado_nota=estado, es_nota_valida=valida)


def estandarizar_perfil(fila: pd.Series) -> dict:
    """RT-B06: estandarización de categorías del perfil del estudiante."""
    k_tipo = clave(fila["Tipo de Estudiante"])
    condicion = next((v for p, v in CONDICION_ACADEMICA.items() if k_tipo.startswith(p)),
                     categoria_especial(fila["Tipo de Estudiante"]) or limpiar(fila["Tipo de Estudiante"]))
    edad_txt = limpiar(fila["Rango de Edad"])
    rango_edad, orden_edad = RANGOS_EDAD.get(edad_txt, (categoria_especial(edad_txt) or edad_txt, 9))
    nac_especial = categoria_especial(fila["Nacionalidad"])
    nacionalidad = nac_especial or limpiar(fila["Nacionalidad"]).capitalize()
    grupo = ("No especificado" if nac_especial
             else "Costarricense" if clave(fila["Nacionalidad"]) == "COSTARRICENSE" else "Extranjera")
    k_dip = clave(fila["Tipo de Diploma de Secundaria"])
    diploma = TIPO_DIPLOMA.get(k_dip, categoria_especial(k_dip) or limpiar(fila["Tipo de Diploma de Secundaria"]))
    return dict(condicion_academica=condicion, rango_edad=rango_edad, orden_rango_edad=orden_edad,
                nacionalidad=nacionalidad, grupo_nacionalidad=grupo, tipo_diploma=diploma)
