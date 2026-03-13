# Mecanismo de Asignacion de Cupos: Convocatoria UTC4 (Estrategia LA U EN TU COLEGIO)

<div align="center">

![R Version](https://img.shields.io/badge/R-4.5.1%2B-blue?style=for-the-badge&logo=r)
![License](https://img.shields.io/badge/Licencia-CC%20BY-green?style=for-the-badge)
![Status](https://img.shields.io/badge/Estado-Producci%C3%B3n%20Auditada-success?style=for-the-badge)
![Reproducibilidad](https://img.shields.io/badge/Reproducibilidad-renv%20%7C%20Seed-orange?style=for-the-badge)

**Agencia Distrital para la Educacion Superior, la Ciencia y la Tecnologia (ATENEA)**
*Gerencia de Estrategia*  
*Subgerencia de Análisis de Información y Gestión del Conocimiento*

</div>

---

## Tabla de Contenidos

1. [Introduccion y Contexto](#1-introduccion-y-contexto)
2. [Arquitectura del Proyecto](#2-arquitectura-del-proyecto)
3. [Requisitos Tecnicos](#3-requisitos-tecnicos)
4. [Logica Detallada del Algoritmo](#4-logica-detallada-del-algoritmo)
    * [Fase 1: Calculo de Puntajes](#fase-1-calculo-de-puntajes-modulo-1)
    * [Fase 2: Ordenamiento y Desempate](#fase-2-ordenamiento-y-desempate-modulo-2)
    * [Fase 3: Motor de Asignacion Iterativa](#fase-3-motor-de-asignacion-iterativa-modulo-3)
    * [Fase 4: Exportacion de Resultados](#fase-4-exportacion-de-resultados-modulo-4)
5. [Diccionario de Datos (Inputs y Outputs)](#5-diccionario-de-datos)
6. [Instrucciones de Ejecucion](#6-instrucciones-de-ejecucion)
7. [Garantia de Reproducibilidad](#7-garantia-de-reproducibilidad)
8. [Uso del Código](#8-uso-del-codigo)

---

## 1. Introduccion y Contexto

Este repositorio contiene la implementacion tecnica del **Algoritmo de Seleccion y Aprobacion de Ofertas Tecnicas** para la cuarta convocatoria de la estrategia "LA U EN TU COLEGIO" (UTC4). Este software es el responsable de evaluar las propuestas presentadas por las Instituciones de Educacion Superior (IES), calcular los puntajes de cada programa ofertado, establecer el ranking de priorizacion y asignar los cupos disponibles dentro del presupuesto aprobado.

El algoritmo ha sido disenado bajo los principios de:
* **Transparencia:** Reglas de negocio codificadas explicitamente sin "cajas negras".
* **Eficiencia:** Uso de procesamiento vectorial y SQL embebido (`sqldf`) para manejo de datos.
* **Auditabilidad:** Generacion de trazas intermedias y archivo final con hojas de auditoria presupuestal.
* **Reproducibilidad:** Uso de semilla fija (`set.seed`) y gestion de entornos con `renv`.

---

## 2. Arquitectura del Proyecto

El codigo ha sido refactorizado desde un script monolitico a una arquitectura modular secuencial. Esto facilita la depuracion y permite auditar cada etapa del proceso por separado.

```text
UTC_calculo_oferta/
|
|-- .gitignore                 # Configuracion de exclusion de archivos sensibles
|-- UTC4_Main.R                # ORQUESTADOR PRINCIPAL (Entry Point)
|-- README.md                  # Documentacion tecnica (Este archivo)
|-- renv.lock                  # Manifiesto de dependencias exactas (Freeze)
|
|-- data/                      # Carpeta de almacenamiento de insumos (Ignorada en git)
|   +-- UTC4_Insumo_Oferta.RData  # Base de datos (Oferta + Programas)
|
|-- output/                    # Carpeta de resultados generados (Ignorada en git)
|   +-- UTC4_OFERTA_VF_YYYYMMDD.xlsx  # Archivo de salida con fecha de ejecucion
|
+-- modules/                   # Logica de Negocio desagregada
    |-- 1_puntajes.R           # Calculo de puntajes (ISOES, Descuento, Global)
    |-- 2_ordenamiento.R       # Ranking y criterios de desempate
    |-- 3_asignacion.R         # Motor iterativo de asignacion de cupos y presupuesto
    +-- 4_exportacion.R        # Generacion de resultados en Excel
```

---

## 3. Requisitos Tecnicos

Para garantizar la ejecucion identica de los resultados, se deben cumplir las siguientes especificaciones:

### Software

* **Lenguaje R:** Version 4.5.1 o superior.
* **Gestor de Paquetes:** `renv` (version 1.1.5+).

### Dependencias (Librerias R)

El entorno se restaura automaticamente usando `renv.lock`, pero las librerias base son:

| Libreria   | Version (Aprox) | Funcion Principal                                        |
|------------|-----------------|----------------------------------------------------------|
| `sqldf`    | 0.4-12          | Consultas SQL sobre dataframes para validaciones.        |
| `expss`    | 0.11.7          | Herramientas de analisis y etiquetado de datos.          |
| `readr`    | 2.2.0           | Lectura eficiente de archivos planos.                    |
| `readxl`   | 1.4.5           | Lectura de archivos Excel.                               |
| `dplyr`    | 1.2.0           | Manipulacion de dataframes, mutaciones y agregaciones.   |
| `tidyr`    | 1.3.2           | Transformacion y reestructuracion de datos.              |
| `eeptools` | 1.2.7           | Herramientas auxiliares de calculo.                      |
| `openxlsx` | 4.2.8           | Escritura y formateo de reportes finales en Excel.       |

---

## 4. Logica Detallada del Algoritmo

A continuacion, se describe la implementacion tecnica de cada modulo.

### Fase 1: Calculo de Puntajes (Modulo 1)

**Archivo:** `modules/1_puntajes.R`

**Objetivo:** Evaluar cada programa ofertado por las IES mediante tres componentes de puntaje que conforman el puntaje global.

**Formula de Puntuacion:**

$$PuntajeGlobal = PuntajeFijo + PuntajeISOES + PuntajeDescuento$$

#### Desglose de Componentes:

1. **Puntaje Fijo (Precalculado en insumos)**
   * Componente que llega calculado en la base `LISTADO_OFERTA_PROPUESTA`.
   * Corresponde a criterios de evaluacion tecnica previamente validados.

2. **Puntaje ISOES (Max 25 puntos)**
   * Basado en el indicador `ISOES_PROGRAMA` de cada programa.
   * **Metodo:** Normalizacion Min-Max escalada a 25 puntos.
   * **Formula:**
   $$PuntajeISOES = 25 \times \frac{ISOES_{programa} - ISOES_{min}}{ISOES_{max} - ISOES_{min}}$$
   * El programa con mayor ISOES recibe 25 puntos; el de menor ISOES recibe 0.

3. **Puntaje Descuento Adicional (Max 30 puntos)**
   * Basado en el porcentaje de descuento adicional (`%_ADICIONAL`) ofrecido por la IES.
   * **Metodo:** Normalizacion Min-Max escalada a 30 puntos.
   * **Formula:**
   $$PuntajeDescuento = 30 \times \frac{Descuento_{programa} - Descuento_{min}}{Descuento_{max} - Descuento_{min}}$$
   * La IES que ofrece mayor descuento recibe 30 puntos; la de menor descuento recibe 0.

---

### Fase 2: Ordenamiento y Desempate (Modulo 2)

**Archivo:** `modules/2_ordenamiento.R`

**Objetivo:** Establecer el ranking definitivo de programas para la asignacion de cupos, aplicando criterios de desempate deterministas.

**Jerarquia de Ordenamiento:**

El ordenamiento es **estricto y deterministico**. Se utiliza la funcion `arrange` con la siguiente jerarquia:

1. `desc(PUNTAJE_GLOBAL)`: Mayor puntaje global primero.
2. `desc(ANEXO3_P5_PORCENTAJE)`: Mayor porcentaje en Anexo 3 desempata.
3. `SEMILLA` (Aleatorio auditable): Priorizacion aleatoria como ultimo criterio.

**Blindaje de Aleatoriedad:**

De persistir el empate, la Agencia aplicara la priorizacion aleatoria por medio de una herramienta estadistica. Para garantizar que el desempate aleatorio sea auditable:

```r
set.seed(20260220)  # Semilla fija: fecha de cierre de convocatoria (2026-02-20)
LISTADO_OFERTA_PROPUESTA$SEMILLA <- LISTADO_OFERTA_PROPUESTA$CODIGO_SNIES_DEL_PROGRAMA[
  sample(length(LISTADO_OFERTA_PROPUESTA$CODIGO_SNIES_DEL_PROGRAMA))
]
```

Esto asegura que el mismo programa siempre reciba el mismo valor de desempate, sin importar el orden de carga de los datos.

**Resultado:** Se genera la variable `UTC4_LLAVE_OFERTA` que asigna la posicion definitiva de cada programa en el ranking.

---

### Fase 3: Motor de Asignacion Iterativa (Modulo 3)

**Archivo:** `modules/3_asignacion.R`

**Objetivo:** Distribuir los cupos disponibles respetando el ranking de programas y las restricciones presupuestales, ejecutando dos momentos de asignacion.

**Presupuesto Inicial:** `$5.410.442.689 COP`

#### Momento 1: Asignacion Principal

Se recorre la lista ordenada de programas (de mayor a menor puntaje) y se aplica:

```text
PARA CADA Programa EN Lista_Ordenada:

   CUPO_OFERTADO  = Estudiantes propuestos por la IES
   CUPO_CALCULADO = Presupuesto_Remanente / Valor_Estudiante_Atenea

   SI (CUPO_CALCULADO >= CUPO_OFERTADO):
       # REGLA 1: Presupuesto alcanza para todos los cupos ofertados
       Asignar CUPO_OFERTADO
       Descontar (CUPO_OFERTADO * Valor_Estudiante) del presupuesto

   SINO SI (CUPO_CALCULADO >= 100):
       # REGLA 2: Presupuesto alcanza para al menos 100 cupos
       Asignar CUPO_CALCULADO (truncado a entero)
       Descontar (CUPO_CALCULADO * Valor_Estudiante) del presupuesto

   SINO:
       # SIN ASIGNACION: No se pueden financiar al menos 100 cupos
       Registrar programa sin financiacion
```

#### Momento 2: Reasignacion con Presupuesto Remanente

Solo participan los programas que **recibieron cupos en el Momento 1**. Se recorren en el mismo orden y se aplica:

```text
PARA CADA Programa CON cupos en Momento 1:

   CUPO_OFERTADO  = Cupos adicionales del Momento 2 (CUPOS_MOMENTO_2)
   CUPO_CALCULADO = Presupuesto_Remanente / Valor_Estudiante_Atenea

   SI (CUPO_CALCULADO >= CUPO_OFERTADO):
       # REGLA 1: Presupuesto alcanza para todos los cupos del Momento 2
       Asignar CUPO_OFERTADO

   SINO SI (CUPO_CALCULADO > 0):
       # REGLA 2: Presupuesto alcanza para al menos 1 cupo
       Asignar CUPO_CALCULADO (truncado a entero)

   SINO:
       # SIN ASIGNACION: Presupuesto agotado
       Registrar sin financiacion
```

**Consolidacion:** Al finalizar ambos momentos se calculan los totales:
* `CUPO_ASIGNADO_TOTAL = Momento1 + Momento2`
* `COSTO_CUPOS_ASIGNADOS_TOTAL = Costo_Momento1 + Costo_Momento2`

---

### Fase 4: Exportacion de Resultados (Modulo 4)

**Archivo:** `modules/4_exportacion.R`

**Objetivo:** Generar el archivo de resultados definitivo y las tablas de auditoria.

1. **Merge Final:** Se cruza `LISTADO_OFERTA_PROPUESTA` (datos completos de la oferta) con `ORDENAMIENTO_PROG` (resultados de asignacion) por `CODIGO_INSTITUCION` y `CODIGO_SNIES_DEL_PROGRAMA`.
2. **Exportacion Excel:** Se genera `output/UTC4_OFERTA_VF_YYYYMMDD.xlsx` con fecha dinamica.
3. **Tablas Resumen en Consola:**
   * Cupos asignados agrupados por IES.
   * Cupos asignados agrupados por IES y Programa.
   * Sumatoria total de cupos y costo.

---

## 5. Diccionario de Datos

### Input: `data/UTC4_Insumo_Oferta.RData`

Contiene el dataframe `LISTADO_OFERTA_PROPUESTA` con las ofertas tecnicas de las IES. Campos clave:

| Campo | Descripcion |
|---|---|
| `CODIGO_INSTITUCION` | Codigo unico de la IES |
| `CODIGO_SNIES_DEL_PROGRAMA` | Codigo SNIES del programa academico |
| `NOMBRE_INSTITUCION` | Nombre de la IES |
| `NOMBRE_DEL_PROGRAMA` | Nombre del programa ofertado |
| `AREA_DE_CONOCIMIENTO` | Area de conocimiento del programa |
| `ISOES_PROGRAMA` | Indicador ISOES del programa |
| `%_ADICIONAL` | Porcentaje de descuento adicional ofrecido |
| `TOTAL_PUNTAJE_FIJO` | Puntaje fijo precalculado (evaluacion tecnica) |
| `ANEXO3_P5_PORCENTAJE` | Porcentaje Anexo 3 (criterio de desempate) |
| `#_ESTUDIANTES` | Cupos ofertados por la IES (Momento 1) |
| `CUPOS_MOMENTO_2` | Cupos adicionales para Momento 2 |
| `VALOR_ESTUDIANTE_ATENEA` | Costo por estudiante financiado por Atenea |

### Output: `output/UTC4_OFERTA_VF_YYYYMMDD.xlsx`

Archivo final con 2 hojas:

| Hoja | Contenido Clave |
|---|---|
| **UTC4_PROGRAMAS** | Resultado detallado por programa. Incluye puntajes, ranking, cupos asignados por momento y costos totales. |
| **PRESUPUESTO** | Auditoria presupuestal: presupuesto inicial, remanente despues de Momento 1 y remanente despues de Momento 2. |

---

## 6. Instrucciones de Ejecucion

Siga estos pasos estrictamente para replicar los resultados oficiales.

1. **Preparar el Entorno:**
   * Instale R (4.5+) y RStudio.
   * Clone este repositorio en su maquina local.

2. **Instalar Dependencias (renv):**
   Abra el proyecto en RStudio y ejecute en la consola:
   ```r
   # Esto descargara las versiones exactas de las librerias usadas en la auditoria
   if (!require("renv")) install.packages("renv")
   renv::restore()
   ```

3. **Cargar Insumos:**
   Asegurese de que el archivo `UTC4_Insumo_Oferta.RData` (provisto por el equipo de datos) se encuentre en la carpeta `data/`.

4. **Ejecutar Algoritmo:**
   Abra el archivo **`UTC4_Main.R`** y ejecute con `source("UTC4_Main.R")` o el boton "Source" de RStudio.
   * El script activa `renv`, carga las librerias y ejecuta los 4 modulos en secuencia.
   * Vera en consola el progreso de la asignacion programa por programa.
   * Los modulos **no se ejecutan de forma independiente**: siempre debe ejecutarse desde `UTC4_Main.R`.

5. **Validar Resultados:**
   Al finalizar, busque el archivo `UTC4_OFERTA_VF_YYYYMMDD.xlsx` en la carpeta `output/`.

---

## 7. Garantia de Reproducibilidad

Este algoritmo es deterministico. Esto significa que **siempre generara exactamente el mismo resultado** bajo las mismas entradas, gracias a:

1. **Semilla Fija:** Se utiliza `set.seed(20260220)` (fecha de cierre de convocatoria) para los desempates aleatorios.
2. **Entorno Controlado:** El archivo `renv.lock` asegura que las funciones matematicas de las librerias no cambien por actualizaciones de software.
3. **Versionamiento:** El codigo fuente esta bajo control de versiones (git), permitiendo rastrear cualquier cambio en la logica.

---
## 8. Uso del Codigo

Autorizacion de Uso (CC BY)

Este algoritmo de asignacion de cupos es una obra institucional de ATENEA
(bajo el articulo 91 de la Ley 23 de 1982) y se publica bajo Autorizacion
general de explotacion con atribucion (CC BY), en cumplimiento de los
principios de transparencia y acceso a la informacion publica.

Cualquier persona puede reproducir, distribuir, comunicar publicamente y
transformar esta obra, siempre que reconozca a ATENEA como autora
institucional, indicando el nombre de la Agencia. Las modificaciones o
versiones derivadas son responsabilidad exclusiva de quien las realice.

(c) 2026 ATENEA - Agencia Distrital para la Educacion Superior, la Ciencia
y la Tecnologia.

Esta autorizacion no implica cesion de derechos patrimoniales ni afecta los
derechos morales sobre la obra original.

**Desarrollado por:** SAIGC - ATENEA

**Fecha de Publicacion:** Marzo 2026
