# FEhist: Feature Engineering histórico con deltas

Problema 5 (FEhist) · Predicción de bajas de clientes bancarios (BAJA+2), LightGBM en R.

## Hipótesis
Las variables **lag** tienen mayor capacidad predictiva que las de **tendencia**.

## Resultado
La hipótesis **no se confirma**: los lags aportan menos que la tendencia, y ambos menos que los **deltas**.

| Exp. | Variables históricas | Media Kaggle | Dif. vs A |
|---|---|---|---|
| A | Sin historia | 391,0 | – |
| E | Solo lags | 403,1 | +12,1 |
| C | Solo tendencia (ventana 6) | 418,5 | +27,5 |
| D | Todo junto | 435,2 | +44,2 |
| B | Lags + deltas | 436,1 | +45,2 |
| **F** | **Solo deltas (1 y 2 meses)** | **437,8** | **+46,8** |

Puntaje público de Kaggle (predicción de 202109), promedio de 3 cortes (8000, 10000 y 12000 envíos). Semillas: A = 7, el resto = 6.
Test: Wilcoxon de rangos exacto (dos colas). F supera a lags y a tendencia (p = 0,0022; p Holm sobre 27 comparaciones = 0,041), y B, D y F empatan (p = 0,48 y 0,31).

## Recomendación
Incorporar **solo los deltas de 1 y 2 meses** (experimento F): tiene el promedio más alto y usa menos variables que combinarlos con lags o tendencia.

## Uso
`FEhist_solo_deltas.R` es un bloque para pegar en el workflow, después de armar `dataset` y antes de entrenar. Requiere `data.table` y que `dataset` y `PARAM` ya existan. Crea `<campo>_delta1` y `<campo>_delta2` por cada campo original y no deja lags ni tendencia.

## Límites
- Un solo período de evaluación; el puntaje público de Kaggle es ruidoso.
- Muchas comparaciones: con Holm, los efectos débiles (E vs A, C vs E) dejan de ser significativos.
- Pendiente: confirmar F en otro mes.

## Contenido
- `FEhist_solo_deltas.R`: el código de la recomendación.
- `resultados/`: puntaje por semilla, resumen por experimento y tests con Holm.
