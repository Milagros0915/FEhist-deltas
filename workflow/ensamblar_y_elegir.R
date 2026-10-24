# Ensemble de corridas y eleccion del corte final para Kaggle
#
# Modo 1: ENSAMBLAR  (promedia las predicciones de varias corridas y genera los archivos para subir)
#   Rscript ensamblar_y_elegir.R ensamblar <carpeta_salida> <carpeta_corrida_1> [<carpeta_corrida_2> ...]
#   - Cada carpeta de corrida es la WF<experimento> del bucket y debe tener prediccion.txt
#     (columnas numero_de_cliente, prob y prob_1..prob_k del semillerio).
#   - Con una sola carpeta, el resultado es el ensemble del semillerio de esa corrida.
#   - Variables de entorno: CORTES (default 10000,10500,...,14000), PROMEDIO=prob|rank (default prob)
#   - Deja en <carpeta_salida>: prediccion.txt (prob del ensemble) y kaggle/KAENS_<envios>.csv
#
# Modo 2: ELEGIR  (a partir de los puntajes publicos de los cortes, sugiere cuales marcar como finales)
#   Rscript ensamblar_y_elegir.R elegir <puntajes.csv>
#   - puntajes.csv: columnas envios,score (el puntaje publico de cada corte subido)
#   - Suaviza la curva con un promedio movil de 3 cortes y sugiere 2 candidatos.

suppressMessages(library(data.table))

args <- commandArgs(trailingOnly = TRUE)
if( length(args) < 2 ) stop("Uso: ver el encabezado del script")
modo <- args[1]

if( modo == "ensamblar" ) {
  salida <- args[2]
  corridas <- args[-(1:2)]
  stopifnot( length(corridas) >= 1 )
  cortes <- as.integer(strsplit(Sys.getenv("CORTES", paste(seq(10000, 14000, by = 500), collapse = ",")), ",")[[1]])
  promedio <- Sys.getenv("PROMEDIO", "prob")
  stopifnot( promedio %in% c("prob", "rank") )

  tb <- NULL
  for( i in seq_along(corridas) ) {
    arch <- file.path(corridas[i], "prediccion.txt")
    if( !file.exists(arch) ) stop("No existe ", arch)
    x <- fread(arch, sep = "\t")[, list(numero_de_cliente, prob)]
    setnames(x, "prob", paste0("prob_c", i))
    if( is.null(tb) ) {
      tb <- x
    } else {
      if( !setequal(tb$numero_de_cliente, x$numero_de_cliente) )
        stop("Las corridas no tienen los mismos clientes: ", arch)
      tb <- merge(tb, x, by = "numero_de_cliente")
    }
  }

  cols <- grep("^prob_c", colnames(tb), value = TRUE)
  if( promedio == "rank" ) {
    # promedio de rangos (percentiles): evita que una corrida con probabilidades mas altas pese mas
    tb[, prob := rowMeans(as.data.table(lapply(.SD, function(v) frank(v) / .N))), .SDcols = cols]
  } else {
    tb[, prob := rowMeans(.SD), .SDcols = cols]
  }
  setorder(tb, -prob)

  dir.create(file.path(salida, "kaggle"), recursive = TRUE, showWarnings = FALSE)
  fwrite(tb, file = file.path(salida, "prediccion.txt"), sep = "\t")

  for( envios in cortes ) {
    tb[, Predicted := 0L]
    tb[1:envios, Predicted := 1L]
    fwrite(tb[, list(numero_de_cliente, Predicted)],
      file = file.path(salida, "kaggle", paste0("KAENS_", envios, ".csv")), sep = ",")
  }
  cat("Ensemble de", length(corridas), "corrida(s), promedio =", promedio, "\n")
  cat("Archivos en", file.path(salida, "kaggle"), ": cortes", paste(cortes, collapse = ", "), "\n")
  if( length(corridas) > 1 ) {
    cat("Correlacion de rangos entre corridas (si es muy baja, el ensemble aporta mas):\n")
    print(round(cor(tb[, cols, with = FALSE], method = "spearman"), 4))
  }

} else if( modo == "elegir" ) {
  tp <- fread(args[2])
  stopifnot( all(c("envios", "score") %in% colnames(tp)) )
  setorder(tp, envios)
  n <- nrow(tp)
  tp[, suavizado := sapply(seq_len(n), function(i) mean(score[max(1, i - 1):min(n, i + 1)]))]
  print(tp)
  mejor_crudo <- tp[which.max(score), envios]
  ord <- order(-tp$suavizado)
  c1 <- tp$envios[ord[1]]
  # segundo candidato: el mejor suavizado que no sea el mismo corte (se prefiere uno vecino)
  c2 <- tp$envios[ord[2]]
  cat("\nMejor corte por puntaje publico crudo:", mejor_crudo, "\n")
  cat("Mejor corte por puntaje suavizado (promedio movil de 3):", c1, "\n")
  cat("Segundo mejor suavizado:", c2, "\n")
  cat("\nSugerencia para marcar como las 2 submissions finales de Kaggle:", c1, "y", c2, "\n")
  cat("Criterio: el puntaje publico es una muestra ruidosa del privado; un corte que esta en el centro\n")
  cat("de una zona alta es mas probable que se mantenga que un pico aislado.\n")
  if( mejor_crudo != c1 )
    cat("Aviso: el mejor crudo (", mejor_crudo, ") no coincide con el mejor suavizado (", c1,
        "): puede ser un pico por ruido.\n", sep = "")
} else {
  stop("Modo desconocido: ", modo, " (usar ensamblar o elegir)")
}
