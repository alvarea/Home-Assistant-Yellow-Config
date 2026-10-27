#!/usr/bin/env bash
# Atajo: cambia el Status de una issue en el Project "HOMY Backlog".
# Uso: tools/homy-status.sh <numero_issue> "Todo" | "In progress" | "Done"
# (cerrar la issue ya la pasa sola a Done). Motivos de espera: labels hold:*.
exec "$(dirname "$0")/homy-field.sh" "${1:?Uso: $0 <numero_issue> \"<Status>\"}" "Status" "${2:?Uso: $0 <numero_issue> \"<Status>\"}"
