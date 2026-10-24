# 1. Hipótesis y diseño

## Hipótesis (Problema 5, FEhist)

> Las variables lag tienen mayor capacidad predictiva que las de tendencia.

Definiciones usadas:

| Variable | Qué es |
|---|---|
| Lag | Valor de la variable hace 1 y 2 meses (`_lag1`, `_lag2`) |
| Tendencia | Pendiente de la variable en una ventana de 6 meses, ajustada por cuadrados mínimos |
| Delta | Valor actual menos el lag (`_delta1`, `_delta2`). Se agregó como tercera opción |

## Experimentos

Cada experimento agrega un tipo de variable histórica al modelo sin historia. Todo lo demás del workflow es igual.

| Exp. | Nombre | Qué agrega |
|---|---|---|
| A | Sin historia | Nada (referencia) |
| B | Lags + deltas | Lags y deltas de 1 y 2 meses |
| C | Solo tendencia | Tendencia en ventana de 6 meses |
| D | Todo junto | Lags, deltas y tendencia |
| E | Solo lags | Lags de 1 y 2 meses |
| F | Solo deltas | Deltas de 1 y 2 meses |

Experimentos exploratorios:

| Exp. | Qué agrega |
|---|---|
| I | Tendencia + mínimo, máximo y promedio de la ventana |
| J | Tendencia + razones respecto del promedio y del máximo |
| K | Cambio relativo respecto del mes anterior |
| L | Meses desde la última actividad |
| M | Deltas a 3 y 6 meses |

## Diseño experimental

- **Modelo:** LightGBM con optimización bayesiana (`mlrMBO`, 30 iteraciones) y un semillerío final de 10 modelos.
- **Mes a predecir:** 202109, evaluado con el puntaje público de Kaggle.
- **Cortes de envíos:** 8000, 10000 y 12000. El puntaje de una corrida es el promedio de los 3 cortes.
- **Unidad de análisis:** la semilla. Cada semilla da un puntaje (promedio de los 3 cortes) y se comparan los puntajes de las semillas entre experimentos.
- **Semillas:** 6 por experimento y 7 para A.
- **Test:** Wilcoxon de rangos exacto (Mann-Whitney), dos colas, sin supuestos de normalidad. En R: `wilcox.test(x, y, exact = TRUE)`. Con n1 y n2 semillas, el p más bajo posible es `2 / choose(n1 + n2, n1)`: 0,0012 con 6 contra 7 y 0,0022 con 6 contra 6.
- **Corrección por comparaciones múltiples:** se informa el p sin corregir y el p con Holm sobre las 27 comparaciones realizadas.

## Cuidados

- Un solo período de evaluación: no se sabe si el orden se mantiene en otro mes.
- El puntaje público de Kaggle es ruidoso; por eso se usan promedios por semilla y no el mejor resultado individual.
- Con 27 comparaciones, los p cercanos a 0,05 son frágiles.
