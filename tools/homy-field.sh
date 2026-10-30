#!/usr/bin/env bash
# Fija un campo de una issue en el GitHub Project "HOMY Backlog".
#
# Uso:   tools/homy-field.sh [--if-empty] <numero_issue> "<Campo>" "<Valor>"
# Campos desplegables (el valor es el nombre de la opción):
#   Status     Todo | In progress | Done
#   Subtype    Bug | Task | Improvement | Cleansing
#   Subproject ALA | BAT | ENE | ESPH | LAV | MAIN | MAT | METEO | PLA | TES | ZHA
#   Priority   P0 (urgente) | P1 (importante) | P2 (normal, por defecto)
# Campos de fecha (valor AAAA-MM-DD o "today"):
#   Start date | Target date
# --if-empty: solo escribe si el campo está vacío en esa issue.
# Si la issue no está en el Project, la añade.
#
# Requiere gh en el PATH (source tools/homy-gh.sh) y GH_PROJECT_TOKEN (token *classic*
# con scope `project`; los fine-grained no pueden acceder a Projects de una cuenta
# personal), del entorno o de CLAUDE.local.md.
# Las opciones nuevas de un desplegable se añaden A MANO en la UI del Project (por API
# GitHub regenera todas las opciones y se pierden los valores ya asignados).
set -euo pipefail

IF_EMPTY=0
if [ "${1:-}" = "--if-empty" ]; then IF_EMPTY=1; shift; fi
USO="Uso: $0 [--if-empty] <numero_issue> \"<Campo>\" \"<Valor>\""
ISSUE="${1:?$USO}"; FIELD="${2:?$USO}"; VALUE="${3:?$USO}"
OWNER="alvarea"
REPO="home-assistant-yellow-config"
PROJECT_TITLE="HOMY Backlog"

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TOKEN="${GH_PROJECT_TOKEN:-$(grep '^GH_PROJECT_TOKEN=' "$ROOT/CLAUDE.local.md" 2>/dev/null | cut -d= -f2 || true)}"
[ -n "$TOKEN" ] || { echo "ERROR: falta GH_PROJECT_TOKEN (entorno o CLAUDE.local.md)" >&2; exit 1; }
export GH_TOKEN="$TOKEN"

# 1. Project (por título), campo (por nombre) y, si es desplegable, opción
PROJECT_NUMBER=$(gh api graphql -f login="$OWNER" -f query='
  query($login:String!){ user(login:$login){ projectsV2(first:50){ nodes{ number title } } } }' \
  --jq ".data.user.projectsV2.nodes[] | select(.title==\"$PROJECT_TITLE\") | .number" | head -1)
[ -n "$PROJECT_NUMBER" ] || { echo "ERROR: no encuentro el Project \"$PROJECT_TITLE\"" >&2; exit 1; }
IFS=$'\t' read -r PROJECT_ID FIELD_ID FIELD_TYPE OPTION_ID < <(
  gh api graphql -f login="$OWNER" -F num="$PROJECT_NUMBER" -f query='
    query($login:String!,$num:Int!){ user(login:$login){ projectV2(number:$num){
      id fields(first:50){ nodes{
        ... on ProjectV2FieldCommon { id name dataType }
        ... on ProjectV2SingleSelectField { options { id name } }
      } }
    } } }' \
  --jq ".data.user.projectV2 | .id as \$pid | ([.fields.nodes[] | select(.name==\"$FIELD\")][0]) as \$f
        | [\$pid, (\$f.id // \"\"), (\$f.dataType // \"\"), (((\$f.options // [])[] | select(.name==\"$VALUE\") | .id) // \"\")] | @tsv"
) || true
[ -n "${PROJECT_ID:-}" ] || { echo "ERROR: no encuentro el Project \"$PROJECT_TITLE\"" >&2; exit 1; }
[ -n "${FIELD_ID:-}" ]   || { echo "ERROR: el campo \"$FIELD\" no existe en el Project" >&2; exit 1; }
case "$FIELD_TYPE" in
  SINGLE_SELECT)
    [ -n "${OPTION_ID:-}" ] || { echo "ERROR: la opción \"$VALUE\" no existe en el campo \"$FIELD\" (añádela a mano en la UI del Project)" >&2; exit 1; } ;;
  DATE)
    [ "$VALUE" = "today" ] && VALUE=$(date +%Y-%m-%d)
    [[ "$VALUE" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]] || { echo "ERROR: fecha no válida \"$VALUE\" (AAAA-MM-DD o today)" >&2; exit 1; } ;;
  *) echo "ERROR: el campo \"$FIELD\" es de tipo $FIELD_TYPE, no soportado (solo desplegables y fechas)" >&2; exit 1 ;;
esac

# 2. Item de la issue en el Project (lo añade si no está) y valor actual del campo
IFS=$'\t' read -r ISSUE_NODE ITEM_ID CURRENT < <(
  gh api graphql -f o="$OWNER" -f r="$REPO" -F n="$ISSUE" -f fname="$FIELD" -f query='
    query($o:String!,$r:String!,$n:Int!,$fname:String!){ repository(owner:$o,name:$r){ issue(number:$n){
      id projectItems(first:20){ nodes{ id project{ id }
        fv: fieldValueByName(name:$fname){
          ... on ProjectV2ItemFieldSingleSelectValue { name }
          ... on ProjectV2ItemFieldDateValue { date } } } } } } }' \
  --jq ".data.repository.issue | .id as \$iid | ([.projectItems.nodes[] | select(.project.id==\"$PROJECT_ID\")][0]) as \$it
        | [\$iid, (\$it.id // \"\"), ((\$it.fv.name // \$it.fv.date) // \"\")] | @tsv"
) || true
[ -n "${ISSUE_NODE:-}" ] || { echo "ERROR: no existe la issue #$ISSUE" >&2; exit 1; }
if [ "$IF_EMPTY" = 1 ] && [ -n "${CURRENT:-}" ]; then
  echo "SIN CAMBIO: #$ISSUE $FIELD ya tiene valor ($CURRENT)"; exit 0
fi
if [ -z "${ITEM_ID:-}" ]; then
  ITEM_ID=$(gh api graphql -f p="$PROJECT_ID" -f c="$ISSUE_NODE" -f query='
    mutation($p:ID!,$c:ID!){ addProjectV2ItemById(input:{projectId:$p,contentId:$c}){ item{ id } } }' \
    --jq '.data.addProjectV2ItemById.item.id')
fi

# 3. Fijar el valor
if [ "$FIELD_TYPE" = "SINGLE_SELECT" ]; then
  gh api graphql -f p="$PROJECT_ID" -f i="$ITEM_ID" -f f="$FIELD_ID" -f v="$OPTION_ID" -f query='
    mutation($p:ID!,$i:ID!,$f:ID!,$v:String!){
      updateProjectV2ItemFieldValue(input:{projectId:$p,itemId:$i,fieldId:$f,value:{singleSelectOptionId:$v}}){
        projectV2Item{ id } } }' --jq '.data.updateProjectV2ItemFieldValue.projectV2Item.id' >/dev/null
else
  gh api graphql -f p="$PROJECT_ID" -f i="$ITEM_ID" -f f="$FIELD_ID" -f v="$VALUE" -f query='
    mutation($p:ID!,$i:ID!,$f:ID!,$v:Date!){
      updateProjectV2ItemFieldValue(input:{projectId:$p,itemId:$i,fieldId:$f,value:{date:$v}}){
        projectV2Item{ id } } }' --jq '.data.updateProjectV2ItemFieldValue.projectV2Item.id' >/dev/null
fi

echo "OK: #$ISSUE $FIELD → $VALUE"
