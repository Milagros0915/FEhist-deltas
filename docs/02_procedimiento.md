# 2. Procedimiento

Cómo se corrieron los experimentos A-M y cómo se llegó a las tablas.

## Máquinas

- Dos máquinas virtuales en Google Cloud, 8 vCPU cada una. Una con 60 GB de RAM (normal) y otra con 247 GB (Spot, que Google puede detener).
- Cada VM con su bucket montado: el dataset en `buckets/b1/datasets/` y las salidas en `buckets/b1/exp/WF<experimento>/`.
- Cuota total de 16 vCPU: caben dos VM de 8.

## Scripts

| Archivo | Para qué |
|---|---|
| `experimentos/workflows/WorkFlow_FEhist_VM*.R` | Workflow de la cátedra convertido a script. El experimento se elige con `EXP=<letra>` y la semilla con `SEED` o `SEED_IDX` |
| `experimentos/lanzadores/correr_semillas_v5.sh` | Corre una lista de semillas para uno o más experimentos |

Versiones: v1 a v5 corresponden a los experimentos A-I; v6 al J, v7 al K, v8 al L y v9 al M.

## Semillas asignadas

| Índice | Semilla | Índice | Semilla |
|---|---|---|---|
| 1 | 500009 | 6 | 999907 |
| 2 | 345679 | 7 | 375017 |
| 3 | 630901 | 8 | 715009 |
| 4 | 450343 | 9 | 555557 |
| 5 | 100043 | 10 | 724427 |

## Correr un experimento

```bash
# una semilla de un experimento
SEED_IDX=1 EXP=F Rscript WorkFlow_FEhist_VM_v5.R

# varias semillas con el lanzador (si la VM se corta, repetir el mismo comando)
CORTES=8000,10000,12000 bash correr_semillas_v5.sh F "1 2 3 4 5 6"
```

- El script crea la carpeta `WF<id>s<semilla>` en el bucket. Si se repite la misma corrida, la optimización bayesiana retoma desde `HT.RDATA` y los modelos ya entrenados no se repiten.
- El lanzador deja una marca `hecho_<exp>_s<semilla>` solo si la corrida terminó bien.

## Obtener el puntaje

1. El script genera un archivo por corte en `kaggle/` y lo sube a la competencia.
2. El puntaje público de cada corte se lee de Kaggle y se promedian los 3 cortes de la misma semilla.
3. Esos promedios están en `resultados/puntaje_por_semilla.csv`.

## Análisis

```bash
Rscript analisis/analisis_wilcoxon.R
```

Genera `resumen_experimentos.csv`, `tests_wilcoxon.csv` y `puntaje_por_semilla.csv`. La función `comparar()` de `analisis/wilcoxon_semillas.R` compara dos experimentos con `wilcox.test(x, y, exact = TRUE)`.

`resultados/tests_wilcoxon_holm27.csv` agrega el p ajustado por Holm sobre las 27 comparaciones.

## Problemas que aparecieron

- **VM Spot:** Google la detuvo varias veces. Se resolvió relanzando el mismo comando.
- **Retomar:** relanzar solo retoma si la carpeta de salida es la misma; una carpeta nueva arranca de cero.
- **Listado de Kaggle:** muestra como máximo 200 filas, así que hubo que guardar instantáneas de los puntajes.
