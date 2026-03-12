#===============================================================================
# UTC4 - MODULO 2: ORDENAMIENTO
# Criterios de desempate y ranking de programas
#===============================================================================

#-------------------------------------------------------------------------------
# De persistir el empate, la Agencia aplicara la priorizacion aleatoria por medio de una herramienta estadistica.
# SEMILLA 2026-02-20 (Cierre de convocatoria)
#-------------------------------------------------------------------------------
set.seed(20260220)
LISTADO_OFERTA_PROPUESTA$SEMILLA <-  LISTADO_OFERTA_PROPUESTA$CODIGO_SNIES_DEL_PROGRAMA[sample(length(LISTADO_OFERTA_PROPUESTA$CODIGO_SNIES_DEL_PROGRAMA))]
sqldf("select SEMILLA FROM LISTADO_OFERTA_PROPUESTA GROUP BY SEMILLA HAVING COUNT(1)>1")

#----------------------------------------
# VARIABLES PARA ORDENAMIENTO
#----------------------------------------
TMP <- LISTADO_OFERTA_PROPUESTA[,c("CODIGO_INSTITUCION","CODIGO_SNIES_DEL_PROGRAMA","NOMBRE_INSTITUCION","NOMBRE_DEL_PROGRAMA","AREA_DE_CONOCIMIENTO","TOTAL_PUNTAJE_FIJO","TOTAL_PUNTAJE_ISOES","TOTAL_PUNTAJE_DESCUENTO", "PUNTAJE_GLOBAL","ANEXO3_P5_PORCENTAJE", "SEMILLA",
                                   "#_ESTUDIANTES","VALOR_ESTUDIANTE_ATENEA","CUPOS_MOMENTO_2")]

ORDENAMIENTO_PROG <-TMP %>%  arrange(desc(PUNTAJE_GLOBAL),
                                        desc(ANEXO3_P5_PORCENTAJE),
                                        SEMILLA, na.last=TRUE)

ORDENAMIENTO_PROG$UTC4_LLAVE_OFERTA <- as.double(row.names(ORDENAMIENTO_PROG))
rm(TMP)

#PEGAR RESULTADO A DATAFRAME PERSONA UNICA
LISTADO_OFERTA_PROPUESTA<- merge(x=LISTADO_OFERTA_PROPUESTA, y=ORDENAMIENTO_PROG[,c("CODIGO_INSTITUCION","CODIGO_SNIES_DEL_PROGRAMA","UTC4_LLAVE_OFERTA")], by=c("CODIGO_INSTITUCION","CODIGO_SNIES_DEL_PROGRAMA"), all = FALSE)
