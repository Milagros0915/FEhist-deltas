#!/bin/bash
# Corre las 10 semillas asignadas, de a una, para uno o varios experimentos.
#
# Uso:   bash correr_semillas.sh "<experimentos>" ["<indices de semillas>"]
# Ejemplos:
#   bash correr_semillas.sh D                    # las 10 semillas con el experimento D
#   bash correr_semillas.sh "D C"                # por cada semilla: primero D y despues C
#   bash correr_semillas.sh D "1 2 3 4 5"        # solo las semillas 1 a 5 (para repartir entre VMs)
# Opcional (variable de entorno):  CORTES=9000,10000,11000  para subir menos envios a Kaggle
#
# Si la VM se interrumpe, volve a lanzar el MISMO comando: se saltean las corridas ya terminadas
# y la que quedo a medias retoma lo que tenia guardado.

SEMILLAS=(500009 345679 630901 450343 100043 999907 375017 715009 555557 724427)
EXPS=${1:-D}
IDX=${2:-"1 2 3 4 5 6 7 8 9 10"}
SCRIPT="${SCRIPT:-$HOME/WorkFlow_FEhist_VM_v5.R}"

set -o pipefail
cd "$HOME" || exit 1

for i in $IDX; do
  s=${SEMILLAS[$((i-1))]}
  for e in $EXPS; do
    marca="$HOME/hecho_${e}_s${s}"
    if [ -f "$marca" ]; then echo "== salteo $e semilla $s (ya terminada)"; continue; fi
    echo "== $(date '+%F %T') arranca exp $e semilla $s (indice $i)"
    SEED=$s EXP=$e Rscript "$SCRIPT" 2>&1 | tee -a "$HOME/corrida_${e}_s${s}.log" && touch "$marca"
  done
done
echo "== $(date '+%F %T') terminado"
