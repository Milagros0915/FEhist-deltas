# 4. Workflow final combinado

`workflow/z739_final_senior_FEhist.ipynb` es el workflow de la cátedra (`z739_final_senior`) con interruptores que combinan los cambios de cada integrante del grupo. El objetivo es buscar la mayor ganancia en el Kaggle de 202109.

> **Estado:** cada cambio tiene evidencia por separado, pero la combinación **no se corrió completa**. El código se revisó (sintaxis del notebook y del script, bloque de deltas y métrica de ganancia probados en R con datos de prueba), pero no se ejecutó la Bayesian Optimization ni el entrenamiento final. Antes de usarlo, hacer la prueba rápida y validar con semillas (secciones 3 y 4).

## 1. Qué cambia respecto del workflow de la cátedra

Los interruptores están en una celda nueva que sigue a la celda de `PARAM`: `PARAM$FINAL$...`.

| Interruptor | Valor final | Qué hace | Evidencia |
|---|---|---|---|
| `FE_hist` | `"deltas"` | Deja solo `delta1` y `delta2`; no deja lags ni tendencia. Con `"base"` queda lags + deltas + tendencia, como trae la cátedra | Problema 5: F +46,8 sobre A; F supera a C y E (p Holm 0,041); empata con B y D |
| `sin_foto_mes` | `TRUE` | El modelo no usa `foto_mes` como variable | Problema 4: SIN_FOTO_MES, 612,1 M$ en el grupo superior (sin diferencia significativa con FEATURE_ENG) |
| `BO_ganancia` | `TRUE` | La optimización bayesiana maximiza la ganancia meseta (500 envíos) en validación en vez del AUC | Problema 4: BO_GANANCIA, 611,7 M$ en el grupo superior |
| `canaritos` | `FALSE` | No corre Canaritos Asesinos | `workflow635`, brazos E0 y E5 (12 semillas, backtest 202107): sin canaritos gana en 12 de 12, diferencia +4,6 M$, p Holm 0,003 |
| `FE_rf` | `TRUE` | Agrega las variables del Random Forest (como la cátedra) | `labo1-grupoB-feature-engineering-rf`: apagarlo da la misma ganancia; se deja encendido para no sumar cambios |
| `cortes` | 10000 a 14000, de a 500 | Envíos que se suben a Kaggle | Grupo B: en 37 corridas el óptimo estuvo entre 10.157 y 13.202 envíos |
| `subir_kaggle` | `TRUE` | Sube los archivos al final | – |
| `semillerio_propio` | `TRUE` | El semillerío final usa las 10 semillas propias (ver sección 3) | Requisito de la entrega |

Notas sobre la evidencia:

- Los experimentos del Problema 4 cambian más de un factor a la vez, así que SIN_FOTO_MES y BO_GANANCIA no están aislados contra una base. Que estén en el grupo superior es una señal, no una prueba.
- La evidencia de `workflow635` y del grupo B es de otro diseño (backtest sobre 202107, otra métrica). Respalda la dirección, no el tamaño del efecto.

## 2. Cambios en el código

| Celda original | Cambio |
|---|---|
| `PARAM` | `semilla_primigenia <- 500009` (propia, no la de la cátedra) y `experimento <- 9740`; celda nueva con `PARAM$FINAL` |
| Carpeta del experimento | Protección: corta si la carpeta ya tiene una corrida terminada (`PARAM.yml`) o una corrida a medias con otra configuración |
| Semillerío final | Con `semillerio_propio` usa las 10 semillas propias en vez de primos sorteados |
| FEhist (lags y deltas) | Se calcula según `FE_hist`; con `"deltas"` se borran los lags auxiliares |
| FEhist (tendencias) | `Tendencias$run` es `TRUE` solo con `FE_hist = "base"` |
| FE_rf | `if( PARAM$FINAL$FE_rf ) AgregaVarRandomForest()` |
| Canaritos | La llamada y el `fwrite` van dentro de `if( PARAM$FINAL$canaritos )` |
| `campos_buenos` | Si `sin_foto_mes`, se quita `foto_mes` (la columna sigue en el dataset para armar los folds) |
| `dvalidate` | Se le agrega el peso 1,0000001 a los BAJA+2, que usa la métrica de ganancia (no cambia el AUC) |
| Bayesian Optimization | Nueva `fganancia_lgbm_meseta_BO`; `EstimarGanancia_AUC_lightgbm` elige AUC o ganancia según `BO_ganancia` |
| Kaggle | Celda nueva que copia `kaggle.json` desde Drive a `~/.kaggle` y verifica que quedó; `cortes <- PARAM$FINAL$cortes`; la subida va dentro de `if( PARAM$FINAL$subir_kaggle )` |

El resto (catastrophe analysis, data drifting, FE intra-mes, training strategy, 30 iteraciones de la BO, semillerío de 10 y final train 201901-202107) queda como en la cátedra.

## 3. Cómo correrlo

### En Colab (notebook)

Abrir `workflow/z739_final_senior_FEhist.ipynb` con runtime R, ajustar `PARAM$FINAL` y correr de arriba abajo.

### En una VM (script)

`workflow/workflow_final_VM.R` es el mismo código con la configuración por variables de entorno. Las rutas salen de `BUCKET_DIR` (por defecto `$HOME/buckets/b1`); el dataset va en `$BUCKET_DIR/datasets/`.

```bash
# prueba rápida del circuito (unos minutos): 2 iteraciones de la BO, 1 modelo, sin subir a Kaggle
HT_ITER=2 SEMILLERIO=1 CORTES=10000 SUBIR_KAGGLE=0 Rscript workflow_final_VM.R

# corrida final con la configuración recomendada
SEED=500009 Rscript workflow_final_VM.R
```

Variables: `SEED`, `EXPERIMENTO`, `SEMILLERIO_PROPIO`, `KAGGLE_JSON`, `FE_HIST` (`deltas` o `base`), `SIN_FOTO_MES`, `BO_GANANCIA`, `CANARITOS`, `FE_RF` (1 o 0), `CORTES` (separados por coma), `SUBIR_KAGGLE`, `SEMILLERIO`, `HT_ITER`, `BUCKET_DIR`.

Con otro `SEED` distinto de 500009, el nombre de la carpeta lleva `s<semilla>`. Usar siempre un nombre de experimento nuevo para una corrida nueva: con el mismo nombre se retoma la anterior.

**Memoria:** sin Canaritos el dataset llega al entrenamiento con muchas más columnas. Usar una VM de al menos 128 GB de RAM.


## 3b. Semillas propias y carpeta del experimento

- **Semillas:** la semilla primigenia es 500009 (la primera asignada) y el semillerío final usa, en este orden, las 10 semillas propias: 500009, 345679, 630901, 450343, 100043, 999907, 375017, 715009, 555557 y 724427. No se usa la de la cátedra (102191) ni los primos sorteados desde ella.
- **Carpeta:** la corrida final escribe en `WF9740`. Los experimentos anteriores usaron `WF9501` a `WF95xx` (y sus variantes con `s<semilla>`) y los brazos de validación usan `WF9741` a `WF9744`, así que no se pisan. Para confirmarlo en cada VM antes de lanzar: `ls ~/buckets/b1/exp | grep 974` no debería listar nada.
- **Protección:** si la carpeta ya tiene una corrida terminada, el workflow corta con un mensaje. Retomar una corrida cortada a la mitad sigue funcionando con la misma configuración y la misma semilla; con otra configuración también corta. Para una corrida nueva, cambiar `PARAM$experimento`.
- **Brazos de validación:** `correr_final.sh` usa `SEMILLERIO_PROPIO=0` para que cada semilla sortee sus primos, igual que los experimentos A-M, y los puntajes sean comparables.

## 3c. Credenciales de Kaggle

Antes de los submits hay una celda que copia `kaggle.json` desde `/content/.drive/My Drive/labo1/kaggle/kaggle.json` a `~/.kaggle/`, le pone permisos 600 y verifica que el archivo quedó en su lugar (si no, corta antes de subir). Requiere tener Drive montado en Colab. En el script de VM, el archivo se toma de `~/.kaggle/kaggle.json` o de la ruta indicada en `KAGGLE_JSON`.

## 3d. Ensemble y elección de la predicción final

El workflow ya promedia las 10 semillas del semillerío en `prediccion.txt` (columna `prob`, más `prob_1` a `prob_10`) y genera un archivo por corte. Para decidir qué subir como final:

1. **Ensemble entre corridas (opcional).** Si se corrió el workflow final con más de una semilla primigenia, se promedian las predicciones:

   ```bash
   Rscript ensamblar_y_elegir.R ensamblar ENS_final WF9740 WF9740s345679
   ```

   Deja `ENS_final/prediccion.txt` y `ENS_final/kaggle/KAENS_<envios>.csv`. Con una sola carpeta, es el ensemble del semillerío. `PROMEDIO=rank` promedia rangos en vez de probabilidades. Con varias corridas imprime la correlación entre ellas: si es muy alta, el ensemble aporta poco.
2. **Subir todos los cortes** (el workflow lo hace solo) y anotar el puntaje público de cada uno en un `puntajes.csv` con columnas `envios,score`.
3. **Elegir.**

   ```bash
   Rscript ensamblar_y_elegir.R elegir puntajes.csv
   ```

   Suaviza la curva con un promedio móvil de 3 cortes y sugiere 2 candidatos. Kaggle permite marcar 2 submissions como finales; conviene marcar el mejor suavizado y el segundo, y no el máximo crudo.
4. **Criterio.** El puntaje público es una muestra ruidosa del privado. Un corte en el centro de una zona alta es más probable que se mantenga que un pico aislado. El grupo B vio el óptimo entre 10.157 y 13.202 envíos.

Limitación: ninguna de estas reglas garantiza el mejor puntaje privado. Es una forma de reducir el riesgo de elegir un pico por ruido.

## 4. Cómo validar la combinación

El lanzador `workflow/correr_final.sh` corre un brazo con varias semillas. Cada brazo suma un cambio al anterior:

| Brazo | Configuración | Equivale a |
|---|---|---|
| F | Solo deltas | Experimento F del Problema 5 (ya corrido con 6 semillas) |
| G2 | F + SIN_FOTO_MES | |
| G3 | G2 + BO_GANANCIA | |
| G4 | G3 + sin Canaritos | Configuración final (versión de validación, `WF9744`) |

```bash
CORTES=8000,10000,12000 bash correr_final.sh G2 "1 2 3 4 5 6"
CORTES=8000,10000,12000 bash correr_final.sh G3 "1 2 3 4 5 6"
CORTES=8000,10000,12000 bash correr_final.sh G4 "1 2 3 4 5 6"
```

- Con `CORTES=8000,10000,12000` el puntaje es comparable con los de los experimentos A-M.
- Usar las mismas semillas y comparar cada brazo con el anterior con Wilcoxon (`analisis/wilcoxon_semillas.R`), con Holm sobre las 3 comparaciones.
- Con 6 semillas, el p más bajo es 0,0022 en un test no pareado.
- Para la entrega final, correr el mejor brazo con las semillas propias: `SEED=500009 Rscript workflow_final_VM.R` (ajustando las variables de ese brazo) y los cortes de 10000 a 14000.
- Diferencias contra el F original: el brazo F del lanzador también usa los cortes y el código del notebook nuevo; si se quiere comparabilidad exacta, volver a correr F con ese lanzador.

## 5. Qué no se incorporó y por qué

| Idea | Origen | Motivo |
|---|---|---|
| FEATURE_ENG (tendencia + mín/máx/prom/ratios) | Problema 4 | Se solapa con los deltas, y en el Problema 5 I y J no superan a la tendencia sola |
| BO_AMPLIADA, PONDERACION, LABEL_BAJA2 | Problema 4 | Quedaron por debajo del grupo superior (601,5; 603,1; 599,2 M$) |
| FE evolutivo con historia de cada fórmula (E11, 606,2 M$) | `workflow635` | Una sola semilla, ~12 h de cómputo y más de 450 GB de RAM; sin validar en otro mes |
| Bagging de negativos en el final train | `workflow635` | No se sostiene al validar en 202105; la base gana |
| Optimizar los parámetros del Random Forest | Grupo B | No mejora respecto del baseline |
| Más iteraciones de la BO | Problema 4 (BO_AMPLIADA) | No mejoró |

## 6. Riesgos conocidos

- **Métrica de la BO:** `modelo_train$record_evals$valid$ganancia$eval` depende del nombre `"ganancia"` de la métrica personalizada. Si da error en la prueba rápida, revisar ese nombre.
- **Interacciones:** los cambios pueden no sumarse. Por eso los brazos G2 a G4.
- **Repetir una semilla no garantiza el mismo número:** LightGBM suma en paralelo y el orden depende del procesador (lo documentó el grupo B). Comparar siempre con varias semillas.
- **Un solo período:** todo se mide en 202109 con puntaje público de Kaggle.
