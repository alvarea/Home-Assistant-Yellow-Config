#!/usr/bin/env bash
# Fija un campo de tipo desplegable (single select) de una issue en el GitHub Project "HOMY Backlog".
#
# Uso:   tools/homy-field.sh <numero_issue> "<Campo>" "<Opción>"
# Campos: Status (Todo | In progress | Done)
#         Subtype (Bug | Task | Improvement | Cleansing)
#         Subproject (ALA | BAT | ENE | ESPH | LAV | MAIN | MAT | METEO | PLA | TES | ZHA)
# Si la issue no está en el Project, la añade.
#
# Requiere gh en el PATH y GH_PROJECT_TOKEN (token *classic* con scope `project`; los
# fine-grained no pueden acceder a Projects de una cuenta personal), del entorno o de
# CLAUDE.local.md. Usa GraphQL: funciona en sesiones enlazadas al Mac (device_bash).
# Las opciones nuevas de un desplegable se añaden A MANO en la UI del Project (por API
# GitHub regenera todas las opciones y se pierden los valores ya asignados).
set -euo pipefail

ISSUE="${1:?Uso: $0 <numero_issue> \"<Campo>\" \"<Opción>\"}"
FIELD="${2:?Uso: $0 <numero_issue> \"<Campo>\" \"<Opción>\"}"
VALUE="${3:?Uso: $0 <numero_issue> \"<Campo>\" \"<Opción>\"}"
OWNER="alvarea"
REPO="home-assistant-yellow-config"
PROJECT_TITLE="HOMY Backlog"

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TOKEN="${GH_PROJECT_TOKEN:-$(grep '^GH_PROJECT_TOKEN=' "$ROOT/CLAUDE.local.md" 2>/dev/null | cut -d= -f2 || true)}"
[ -n "$TOKEN" ] || { echo "ERROR: falta GH_PROJECT_TOKEN (entorno o CLAUDE.local.md)" >&2; exit 1; }
export GH_TOKEN="$TOKEN"

# 1. Project (por título), campo y opción (por nombre, sin IDs fijos)
PROJECT_NUMBER=$(gh api graphql -f login="$OWNER" -f query='
  query($login:String!){ user(login:$login){ projectsV2(first:50){ nodes{ number title } } } }' \
  --jq ".data.user.projectsV2.nodes[] | select(.title==\"$PROJECT_TITLE\") | .number" | head -1)
[ -n "$PROJECT_NUMBER" ] || { echo "ERROR: no encuentro el Project \"$PROJECT_TITLE\"" >&2; exit 1; }
IFS=$'\t' read -r PROJECT_ID FIELD_ID OPTION_ID < <(
  gh api graphql -f login="$OWNER" -F num="$PROJECT_NUMBER" -f query='
    query($login:String!,$num:Int!){ user(login:$login){ projectV2(number:$num){
      id fields(first:50){ nodes{ ... on ProjectV2SingleSelectField { id name options { id name } } } }
    } } }' \
  --jq ".data.user.projectV2 | .id as \$pid | ([.fields.nodes[] | select(.name==\"$FIELD\")][0]) as \$f
        | [\$pid, (\$f.id // \"\"), (((\$f.options // [])[] | select(.name==\"$VALUE\") | .id) // \"\")] | @tsv"
) || true
[ -n "${PROJECT_ID:-}" ] || { echo "ERROR: no encuentro el Project \"$PROJECT_TITLE\"" >&2; exit 1; }
[ -n "${FIELD_ID:-}" ]   || { echo "ERROR: el campo \"$FIELD\" no existe o no es un desplegable" >&2; exit 1; }
[ -n "${OPTION_ID:-}" ]  || { echo "ERROR: la opción \"$VALUE\" no existe en el campo \"$FIELD\" (añádela a mano en la UI del Project)" >&2; exit 1; }

# 2. Item de la issue en el Project (lo añade si no está)
IFS=$'\t' read -r ISSUE_NODE ITEM_ID < <(
  gh api graphql -f o="$OWNER" -f r="$REPO" -F n="$ISSUE" -f query='
    query($o:String!,$r:String!,$n:Int!){ repository(owner:$o,name:$r){ issue(number:$n){
      id projectItems(first:20){ nodes{ id project{ id } } } } } }' \
  --jq ".data.repository.issue | [.id, ((.projectItems.nodes[] | select(.project.id==\"$PROJECT_ID\") | .id) // \"\")] | @tsv"
) || true
[ -n "${ISSUE_NODE:-}" ] || { echo "ERROR: no existe la issue #$ISSUE" >&2; exit 1; }
if [ -z "${ITEM_ID:-}" ]; then
  ITEM_ID=$(gh api graphql -f p="$PROJECT_ID" -f c="$ISSUE_NODE" -f query='
    mutation($p:ID!,$c:ID!){ addProjectV2ItemById(input:{projectId:$p,contentId:$c}){ item{ id } } }' \
    --jq '.data.addProjectV2ItemById.item.id')
fi

# 3. Fijar el valor
gh api graphql -f p="$PROJECT_ID" -f i="$ITEM_ID" -f f="$FIELD_ID" -f v="$OPTION_ID" -f query='
  mutation($p:ID!,$i:ID!,$f:ID!,$v:String!){
    updateProjectV2ItemFieldValue(input:{projectId:$p,itemId:$i,fieldId:$f,value:{singleSelectOptionId:$v}}){
      projectV2Item{ id } } }' --jq '.data.updateProjectV2ItemFieldValue.projectV2Item.id' >/dev/null

echo "OK: #$ISSUE $FIELD → $VALUE"
