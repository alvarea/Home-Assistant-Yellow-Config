#!/usr/bin/env bash
# Lista las tareas de un subproyecto del Project "HOMY Backlog" con Status, Subtype y labels hold:*.
#
# Uso:   tools/homy-list.sh <SUBPROYECTO> [--all]
#   <SUBPROYECTO>: valor del campo Subproject (ALA, BAT, ENE, ...); "-" = todos
#   --all: incluye las cerradas (por defecto solo abiertas)
# Salida ordenada: In progress, Todo, Done; una línea por tarea:
#   <Status> | #<n> | <Subtype> | <título> | <hold:*>
#
# Requiere gh en el PATH y GH_PROJECT_TOKEN (classic, scope `project`), del entorno o de CLAUDE.local.md.
set -euo pipefail
SUB="${1:?Uso: $0 <SUBPROYECTO|-> [--all]}"
ALL="${2:-}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TOKEN="${GH_PROJECT_TOKEN:-$(grep '^GH_PROJECT_TOKEN=' "$ROOT/CLAUDE.local.md" 2>/dev/null | cut -d= -f2 || true)}"
[ -n "$TOKEN" ] || { echo "ERROR: falta GH_PROJECT_TOKEN (entorno o CLAUDE.local.md)" >&2; exit 1; }
export GH_TOKEN="$TOKEN"

NUM=$(gh api graphql -f query='{user(login:"alvarea"){projectsV2(first:50){nodes{number title}}}}' \
  --jq '.data.user.projectsV2.nodes[] | select(.title=="HOMY Backlog") | .number' | head -1)
[ -n "$NUM" ] || { echo "ERROR: no encuentro el Project \"HOMY Backlog\"" >&2; exit 1; }

gh api graphql --paginate -F num="$NUM" -f query='
  query($num:Int!, $endCursor:String){ user(login:"alvarea"){ projectV2(number:$num){
    items(first:100, after:$endCursor){ pageInfo{ hasNextPage endCursor } nodes{
      st:fieldValueByName(name:"Status"){ ... on ProjectV2ItemFieldSingleSelectValue{ name } }
      ty:fieldValueByName(name:"Subtype"){ ... on ProjectV2ItemFieldSingleSelectValue{ name } }
      sp:fieldValueByName(name:"Subproject"){ ... on ProjectV2ItemFieldSingleSelectValue{ name } }
      content{ ... on Issue{ number title state labels(first:20){ nodes{ name } } } }
    } } } } }' \
  --jq ".data.user.projectV2.items.nodes[]
        | select(.content.number != null)
        | select(\"$SUB\" == \"-\" or .sp.name == \"$SUB\")
        | select(\"$ALL\" == \"--all\" or .content.state == \"OPEN\")
        | [ (.st.name // \"-\"), \"#\\(.content.number)\", (.ty.name // \"-\"), .content.title,
            ([.content.labels.nodes[].name | select(startswith(\"hold:\"))] | join(\",\")) ]
        | join(\" | \")" \
  | awk -F' \\| ' '{o = ($1=="In progress") ? 1 : ($1=="Todo") ? 2 : 3; print o "\t" $0}' | sort -t$'\t' -k1,1n -s | cut -f2-
