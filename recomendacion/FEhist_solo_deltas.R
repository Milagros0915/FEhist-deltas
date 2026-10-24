# FEhist - Feature Engineering historico, version SOLO DELTAS (experimento F)
#
# Recomendacion del Problema 5: de todas las variables historicas probadas,
# lo que mas mejora la prediccion son los deltas (cuanto cambio cada variable
# respecto de 1 y de 2 meses atras). Sumarles lags o tendencia no mejora:
# los experimentos B, D y F quedan empatados.
#
# Para cada campo del dataset original (*) se crean:
#   <campo>_delta1 = valor actual - valor de hace 1 mes
#   <campo>_delta2 = valor actual - valor de hace 2 meses
# (*) excepto numero_de_cliente, foto_mes y clase_ternaria
#
# NO se dejan en el dataset: los lags, ni las variables de tendencia.
#
# Donde pegarlo: en el workflow, despues de armar `dataset` (con las variables
# originales y las de la clase) y antes del entrenamiento.
# Requiere: data.table, y que `dataset` y `PARAM` ya existan.

# parametros de Feature Engineering Historico
PARAM$FE_hist$Lags$run       <- FALSE   # no se dejan los lags
PARAM$FE_hist$Deltas$run     <- TRUE    # se agregan los deltas
PARAM$FE_hist$Tendencias$run <- FALSE   # no se agrega la tendencia

# el orden es importante: por cliente y por mes
setorder(dataset, numero_de_cliente, foto_mes)

# todo es lagueable, menos la primary key y la clase
cols_lagueables <- copy( setdiff(
    colnames(dataset),
    c("numero_de_cliente", "foto_mes", "clase_ternaria")
) )

if( PARAM$FE_hist$Deltas$run ) {

  # lags auxiliares de orden 1 y 2 (solo sirven para calcular los deltas)
  dataset[,
      paste0(cols_lagueables, "_lag1") := shift(.SD, 1, NA, "lag"),
      by = numero_de_cliente,
      .SDcols = cols_lagueables
  ]
  dataset[,
      paste0(cols_lagueables, "_lag2") := shift(.SD, 2, NA, "lag"),
      by = numero_de_cliente,
      .SDcols = cols_lagueables
  ]

  # deltas: valor actual - valor del lag
  for( vcol in cols_lagueables ) {
    dataset[, paste0(vcol, "_delta1") := get(vcol) - get(paste0(vcol, "_lag1"))]
    dataset[, paste0(vcol, "_delta2") := get(vcol) - get(paste0(vcol, "_lag2"))]
  }

  # como no se quieren los lags, se eliminan los auxiliares
  if( !PARAM$FE_hist$Lags$run ) {
    dataset[, c(paste0(cols_lagueables, "_lag1"),
                paste0(cols_lagueables, "_lag2")) := NULL]
  }
}

# Verificacion: tiene que haber 2 columnas nuevas por cada campo original
# (_delta1 y _delta2) y ninguna _lag ni de tendencia
ncol(dataset)
colnames(dataset)
