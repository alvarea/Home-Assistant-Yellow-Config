#!/usr/bin/env bash
# Atajo: cambia el Status de una issue en el Project "HOMY Backlog".
# Uso: tools/homy-status.sh <numero_issue> "Todo" | "In progress" | "Done"
# Al pasar a "In progress" pone también Start date = hoy, solo si estaba vacía.
# (Cerrar la issue ya la pasa sola a Done.) Motivos de espera: labels hold:*.
set -euo pipefail
N="${1:?Uso: $0 <numero_issue> \"<Status>\"}"; S="${2:?Uso: $0 <numero_issue> \"<Status>\"}"
D="$(dirname "$0")"
"$D/homy-field.sh" "$N" "Status" "$S"
if [ "$S" = "In progress" ]; then "$D/homy-field.sh" --if-empty "$N" "Start date" today; fi
