# FEhist: Feature Engineering histórico para predecir bajas de clientes bancarios

Laboratorio de Implementación I · Maestría en Ciencia de Datos · Universidad Austral · 2026
Grupo A · Problema 5 (FEhist) · Autora: Milagros Villalba

Predicción de bajas BAJA+2 de un banco (competencia Kaggle `labo-1-ba-2026-analista-sr`, mes a predecir 202109) con LightGBM en R.

## Pregunta y resultado en una línea

**Hipótesis:** las variables *lag* predicen mejor que las de *tendencia*.
**Resultado:** no se confirma. Los lags aportan menos que la tendencia, y ambos menos que los **deltas** (valor actual menos el de hace 1 o 2 meses).
**Recomendación:** incorporar solo los deltas de 1 y 2 meses (experimento F).

| Exp. | Variables históricas | Media Kaggle | Dif. vs A |
|---|---|---|---|
| A | Sin historia | 391,0 | – |
| E | Solo lags | 403,1 | +12,1 |
| C | Solo tendencia (ventana 6) | 418,5 | +27,5 |
| D | Todo junto | 435,2 | +44,2 |
| B | Lags + deltas | 436,1 | +45,2 |
| **F** | **Solo deltas (1 y 2 meses)** | **437,8** | **+46,8** |

Puntaje público de Kaggle, promedio de 3 cortes (8000, 10000 y 12000 envíos) y luego promedio por semilla. Semillas: A = 7, el resto = 6. Test: Wilcoxon de rangos exacto, dos colas. F supera a lags y a tendencia (p = 0,0022; p Holm sobre 27 comparaciones = 0,041); B, D y F empatan. Detalle en [docs/03_resultados_y_tests.md](docs/03_resultados_y_tests.md).

## Workflow final

Además de la recomendación de FEhist, `workflow/` tiene el workflow de la cátedra (`z739_final_senior`) con los cambios que combinan lo mejor de cada integrante del grupo para buscar la mayor ganancia:

| Cambio | Origen |
|---|---|
| Solo deltas de 1 y 2 meses | Problema 5, Mily (este repo) |
| Sin `foto_mes` entre las variables del modelo | Problema 4 (experimento SIN_FOTO_MES) |
| La Bayesian Optimization maximiza la ganancia meseta en vez del AUC | Problema 4 (experimento BO_GANANCIA) |
| Sin Canaritos Asesinos | `workflow635` (E5 > E0, 12 de 12 semillas) |
| Cortes de Kaggle de 10000 a 14000 envíos | `labo1-grupoB-feature-engineering-rf` |

La corrida final usa las 10 semillas propias de Mily, escribe en una carpeta propia (`WF9740`) y tiene protección contra pisar corridas anteriores.

La combinación **no está validada todavía**: cada cambio tiene evidencia por separado, pero no se corrieron juntos. [docs/04_workflow_final.md](docs/04_workflow_final.md) explica cada cambio, cómo correrlo y cómo validarlo con las mismas semillas.

## Estructura

```
README.md
docs/
  01_hipotesis_y_diseno.md      Hipótesis, experimentos A-M y diseño experimental
  02_procedimiento.md           Cómo se corrió: máquinas, semillas, lanzadores, cómo retomar y cómo analizar
  03_resultados_y_tests.md      Medias, tests de Wilcoxon (sin corregir y con Holm) y lectura
  04_workflow_final.md          Workflow final combinado: cambios, evidencia, uso y validación
workflow/
  z739_final_senior_FEhist.ipynb   Notebook final (runtime R de Colab)
  workflow_final_VM.R              Mismo código como script para VM, configurable por variables de entorno
  correr_final.sh                  Lanza un brazo (F, G2, G3, G4) con varias semillas
  ensamblar_y_elegir.R             Ensemble de corridas y elección de los cortes finales para Kaggle
experimentos/
  workflows/                       Versiones v1 a v9 del script con los que se corrieron los experimentos A-M
  lanzadores/                      correr_semillas*.sh: corre las 10 semillas asignadas
analisis/
  analisis_wilcoxon.R              Arma el resumen, la tabla por semilla y los tests desde los resultados
  wilcoxon_semillas.R              Función comparar(): Wilcoxon exacto entre dos experimentos
resultados/
  puntaje_por_semilla.csv          Puntaje por experimento y semilla
  resumen_experimentos.csv         Media por experimento y diferencia contra A
  tests_wilcoxon_holm27.csv        Tests con p sin corregir y p Holm (27 comparaciones)
  Experimentos_FEhist.xlsx         Planilla con el detalle de los experimentos
recomendacion/
  FEhist_solo_deltas.R             Bloque de código con solo deltas (experimento F)
```

## Límites

- Un solo período de evaluación (202109) y un puntaje público de Kaggle ruidoso.
- Muchas comparaciones: con Holm, los efectos débiles (E vs A, C vs E) dejan de ser significativos; los fuertes se mantienen.
- Con 6 semillas contra 6, el p más bajo posible es 0,0022.
- Pendiente: confirmar F en otro mes y validar el workflow final combinado.

## Repositorios relacionados

- [workflow635](https://github.com/Milagros0915/workflow635) (fork): workflow de la cátedra llevado a VM, FE evolutivo y brazos del grupo B.
- [labo1-grupoB-feature-engineering-rf](https://github.com/Milagros0915/labo1-grupoB-feature-engineering-rf) (fork): análisis del grupo B sobre las variables del Random Forest.
