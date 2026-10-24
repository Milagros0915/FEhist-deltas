# Test de Wilcoxon (suma de rangos / Mann-Whitney) EXACTO, a dos colas,
# para comparar experimentos. Unidad de analisis: la SEMILLA
# (promedio de sus tres cortes de Kaggle).

# 1) Datos: un puntaje por semilla (promedio de los 3 cortes).
#    Reemplazar por los valores reales. Estos son SOLO DE EJEMPLO.
datos <- data.frame(
  exp  = rep(c("A", "F"), times = c(7, 6)),
  seed = c(1:7, 1:6),
  score = c(385, 390, 392, 388, 395, 387, 391,     # ejemplo: experimento A
            436, 439, 435, 440, 437, 438)          # ejemplo: experimento F
)

# 2) Funcion de comparacion
comparar <- function(datos, e1, e2) {
  x <- datos$score[datos$exp == e1]
  y <- datos$score[datos$exp == e2]
  t <- wilcox.test(x, y, exact = TRUE, alternative = "two.sided")
  n1 <- length(x); n2 <- length(y)
  data.frame(
    comparacion = paste(e1, "contra", e2),
    semillas    = paste(n1, "vs", n2),
    diferencia  = round(mean(x) - mean(y), 1),   # diferencia de medias, en puntos
    p           = signif(t$p.value, 2),
    p_minimo    = signif(2 / choose(n1 + n2, n1), 2)  # p minimo posible con esas semillas
  )
}

# 3) Uso
print(comparar(datos, "F", "A"))

# Varias comparaciones juntas:
# pares <- list(c("F","A"), c("C","A"), c("E","A"), c("C","E"), c("F","B"))
# print(do.call(rbind, lapply(pares, function(p) comparar(datos, p[1], p[2]))))
