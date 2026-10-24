suppressMessages(library(data.table))
options(width = 200)
semillas_ok <- c("500009","345679","630901","450343","100043","999907","375017","715009","555557","724427")
archivos <- unique(c(Sys.glob(path.expand("~/buckets/b1/subs_snap_*.csv")), path.expand("~/subs.csv")))
L <- lapply(archivos, function(f) tryCatch(fread(f, colClasses = "character"), error = function(e) NULL))
d <- rbindlist(L, fill = TRUE)
nm <- names(d)
cd <- nm[grep("^description$", nm, ignore.case = TRUE)]
cs <- nm[grep("^publicScore$", nm, ignore.case = TRUE)]
cf <- nm[grep("^date$", nm, ignore.case = TRUE)]
if (length(cd) != 1 | length(cs) != 1) { print(nm); stop("no encuentro las columnas description y publicScore") }
x <- data.table(desc = d[[cd]], score = suppressWarnings(as.numeric(d[[cs]])), fecha = if (length(cf) == 1) d[[cf]] else "")
x <- x[grepl("exp=", desc) & grepl("envios=", desc) & grepl("semilla=", desc) & !is.na(score)]
x[, exp := sub(".*exp=([A-Za-z0-9]+).*", "\\1", desc)]
x[, envios := as.integer(sub(".*envios=([0-9]+).*", "\\1", desc))]
x[, semilla := sub(".*semilla=([0-9]+).*", "\\1", desc)]
x <- x[semilla %in% semillas_ok & envios %in% c(8000L, 10000L, 12000L)]
setorder(x, fecha)
x <- x[, .SD[.N], by = .(exp, semilla, envios)]
ps <- x[, .(n_cortes = .N, score = mean(score)), by = .(exp, semilla)]
cat("\n== Semillas incompletas (deberia salir vacio) ==\n"); print(ps[n_cortes != 3])
ps <- ps[n_cortes == 3]
res <- ps[, .(semillas = .N, media = round(mean(score), 1), desvio = round(sd(score), 1)), by = exp][order(-media)]
cat("\n== Resumen por experimento ==\n"); print(res, row.names = FALSE)
comparar <- function(e1, e2) {
  a <- ps[exp == e1, score]; b <- ps[exp == e2, score]
  if (length(a) < 2 | length(b) < 2) return(NULL)
  t <- suppressWarnings(wilcox.test(a, b, exact = TRUE, alternative = "two.sided"))
  data.table(comparacion = paste(e1, "contra", e2), semillas = paste(length(a), "vs", length(b)),
             diferencia = round(mean(a) - mean(b), 1), p = signif(t$p.value, 2),
             p_minimo = signif(2 / choose(length(a) + length(b), length(a)), 2))
}
pares <- c(lapply(c("B","C","D","E","F","I","J","K","L","M"), function(e) c(e, "A")),
           list(c("C","E"), c("F","E"), c("F","C"), c("F","B"), c("F","D"), c("D","B"), c("B","C"), c("D","C"), c("D","E"), c("B","E"),
                c("C","I"), c("J","C"), c("J","F"), c("K","F"), c("M","F"), c("M","C"), c("K","C")))
tests <- rbindlist(lapply(pares, function(p) comparar(p[1], p[2])))
cat("\n== Tests de Wilcoxon (exacto, dos colas) ==\n"); print(tests, row.names = FALSE)
fwrite(res, path.expand("~/resumen_experimentos.csv")); fwrite(tests, path.expand("~/tests_wilcoxon.csv")); fwrite(ps, path.expand("~/puntaje_por_semilla.csv"))
cat("\nListo. Archivos: ~/resumen_experimentos.csv, ~/tests_wilcoxon.csv, ~/puntaje_por_semilla.csv\n")
