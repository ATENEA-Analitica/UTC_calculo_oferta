#==============================================================================================
# UTC4
# Mecanismo de seleccion y aprobacion de las ofertas tecnicas
# 2026-03-10
#==============================================================================================
# ORQUESTADOR PRINCIPAL (Entry Point)
#==============================================================================================

#-----------------------------------------
# ACTIVAR RENV (Gestión de dependencias)
#-----------------------------------------
source("renv/activate.R")

#-----------------------------------------
# CONFIGURACION DEL ENTORNO
#-----------------------------------------
library(sqldf)
library(expss)
library(readr)
library(readxl)
library(dplyr)
library(tidyr)
library(eeptools)
library(openxlsx)
options(scipen=999)

#-----------------------------------------
# CARGAR INSUMOS PARA EL CALCULO DE OFERTA
#-----------------------------------------
load("data/UTC4_Insumo_Oferta.RData")

#-----------------------------------------
# EJECUTAR MODULOS
#-----------------------------------------

# Modulo 1: Calculo de puntajes (ISOES, Descuento, Global)
source("modules/1_puntajes.R")

# Modulo 2: Ordenamiento y criterios de desempate
source("modules/2_ordenamiento.R")

# Modulo 3: Asignacion de cupos y presupuesto (Momento 1 y 2)
source("modules/3_asignacion.R")

# Modulo 4: Exportacion de resultados a Excel
source("modules/4_exportacion.R")
