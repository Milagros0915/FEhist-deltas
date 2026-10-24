#!/bin/bash
# Corre el workflow final (workflow_final_VM.R) con una de las configuraciones ("brazos") y varias semillas.
#
# Uso:   bash correr_final.sh <BRAZO> ["<indices de semillas>"]
#   BRAZOS (cada uno suma un cambio al anterior; F equivale al experimento F del Problema 5):
#     F   solo deltas                                              (referencia, ya corrido con 6 semillas)
#     G2  F + SIN_FOTO_MES
#     G3  G2 + BO_GANANCIA
#     G4  G3 + sin Canaritos Asesinos   (configuracion FINAL recomendada)
# Ejemplos:
#   bash correr_final.sh G4                 # las 10 semillas con la configuracion final
#   bash correr_final.sh G3 "1 2 3 4 5 6"   # solo las semillas 1 a 6
# Para comparar contra los experimentos A-M conviene CORTES=8000,10000,12000 (los de los tests de Wilcoxon):
#   CORTES=8000,10000,12000 bash correr_final.sh G3 "1 2 3 4 5 6"
# Si la VM se interrumpe, volve a lanzar el MISMO comando: se saltean las corridas terminadas.

SEMILLAS=(500009 345679 630901 450343 100043 999907 375017 715009 555557 724427)
BRAZO=${1:?indicar el brazo: F, G2, G3 o G4}
IDX=${2:-"1 2 3 4 5 6 7 8 9 10"}
SCRIPT="${SCRIPT:-$HOME/workflow_final_VM.R}"

case "$BRAZO" in
  F)  CFG="FE_HIST=deltas SIN_FOTO_MES=0 BO_GANANCIA=0 CANARITOS=1 EXPERIMENTO=9741" ;;
  G2) CFG="FE_HIST=deltas SIN_FOTO_MES=1 BO_GANANCIA=0 CANARITOS=1 EXPERIMENTO=9742" ;;
  G3) CFG="FE_HIST=deltas SIN_FOTO_MES=1 BO_GANANCIA=1 CANARITOS=1 EXPERIMENTO=9743" ;;
  G4) CFG="FE_HIST=deltas SIN_FOTO_MES=1 BO_GANANCIA=1 CANARITOS=0 EXPERIMENTO=9740" ;;
  *) echo "brazo desconocido: $BRAZO"; exit 1 ;;
esac

set -o pipefail
cd "$HOME" || exit 1
for i in $IDX; do
  s=${SEMILLAS[$((i-1))]}
  marca="$HOME/hecho_final_${BRAZO}_s${s}"
  if [ -f "$marca" ]; then echo "== salteo $BRAZO semilla $s (ya terminada)"; continue; fi
  echo "== $(date '+%F %T') arranca brazo $BRAZO semilla $s (indice $i)"
  env $CFG SEED=$s Rscript "$SCRIPT" 2>&1 | tee -a "$HOME/final_${BRAZO}_s${s}.log" && touch "$marca"
done
echo "== $(date '+%F %T') terminado"
