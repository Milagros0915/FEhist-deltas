# 3. Resultados y tests

Puntaje público de Kaggle (202109): promedio de 3 cortes y luego promedio por semilla. Todas las diferencias son contra A (sin historia = 391,0). Fuente: `resultados/puntaje_por_semilla.csv`.

## Medias por experimento

| Exp. | Variables históricas | Semillas | Media | Dif. vs A |
|---|---|---|---|---|
| A | Sin historia | 7 | 391,0 | – |
| F | Solo deltas | 6 | 437,8 | +46,8 |
| B | Lags + deltas | 6 | 436,1 | +45,2 |
| D | Todo junto | 6 | 435,2 | +44,2 |
| J | Tendencia + razones | 6 | 423,8 | +32,8 |
| M | Deltas a 3 y 6 meses | 6 | 423,0 | +32,0 |
| C | Solo tendencia | 6 | 418,5 | +27,5 |
| I | Tendencia + mín/máx/prom | 6 | 412,0 | +21,0 |
| K | Cambio relativo | 6 | 407,9 | +16,9 |
| E | Solo lags | 6 | 403,1 | +12,1 |
| L | Meses sin actividad | 6 | 388,3 | −2,7 |

## Tests de Wilcoxon

Rangos exacto, dos colas. "p Holm" corrige las 27 comparaciones. Tabla completa en `resultados/tests_wilcoxon_holm27.csv`.

| Comparación | Dif. | p | p Holm | Lectura |
|---|---|---|---|---|
| F vs A | +46,8 | 0,0012 | 0,031 | La historia ayuda |
| C vs A | +27,5 | 0,0012 | 0,031 | La tendencia ayuda |
| E vs A | +12,1 | 0,014 | 0,112 | Los lags solos: efecto frágil |
| C vs E | +15,3 | 0,0087 | 0,087 | Tendencia mayor que lags (sugestivo) |
| F vs E | +34,6 | 0,0022 | 0,041 | Los deltas superan a los lags |
| F vs C | +19,3 | 0,0022 | 0,041 | Los deltas superan a la tendencia |
| F vs B | +1,6 | 0,48 | 1,000 | Empate |
| F vs D | +2,6 | 0,31 | 1,000 | Empate |
| J vs F | −14,0 | 0,0022 | 0,041 | F supera a J |
| M vs F | −14,8 | 0,0022 | 0,041 | F supera a M |
| K vs F | −29,9 | 0,0022 | 0,041 | F supera a K |
| I vs C | −6,5 | 0,093 | 0,558 | I no mejora a C |
| J vs C | +5,3 | 0,065 | 0,455 | J no supera a C |
| L vs A | −2,7 | 0,63 | 1,000 | Sin efecto |

## Lectura

1. **La hipótesis no se confirma.** Los lags solos son lo que menos mejora (+12,1), la tendencia sola mejora más (+27,5) y los deltas son lo mejor (+46,8).
2. **Los deltas bastan.** B (lags + deltas), D (todo junto) y F (solo deltas) empatan, así que sumar lags o tendencia a los deltas no agrega nada. F usa menos variables.
3. **Importa el cambio reciente.** Los deltas de 3 y 6 meses (M) rinden unos 15 puntos menos que los de 1 y 2 meses.
4. **Más estadísticos de ventana no ayudan.** I y J no superan a la tendencia sola.
5. **Los meses sin actividad (L) no cambian nada.** Con 2 semillas parecía negativo; con 6 quedó claro que era casualidad.
6. **Fuerza de la evidencia.** Con 6 semillas contra 6, el p más bajo posible es 0,0022. Lo débil (E vs A, C vs E) deja de ser significativo con Holm.

Una explicación posible de que los deltas rindan más: un modelo de árboles no sabe restar columnas por su cuenta. Con el lag tiene el dato, pero tiene que descubrir la resta; con el delta la resta ya está hecha. No se probó por separado.
