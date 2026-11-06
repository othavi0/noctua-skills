#!/usr/bin/env bash
# Claude Managed Agents driver. Run with no arguments to list the commands.
set -euo pipefail
shopt -s inherit_errexit
SKILL="$(cd "$(dirname "$0")/.." && pwd)"
CONFIG="${NUVEM_CONFIG:-$HOME/.config/nuvem}"
STATE="${NUVEM_STATE:-$HOME/.local/state/nuvem}"
S_JSON="$STATE/state.json"
KEY_FILE="${ANTHROPIC_API_KEY_FILE:-$HOME/.config/anthropic/api-key}"
API=https://api.anthropic.com/v1
# shellcheck source=/dev/null
source "$SKILL/limits.conf"
# shellcheck source=/dev/null
[ -f "$CONFIG/limits.conf" ] && source "$CONFIG/limits.conf"
for v in MONTHLY_CREDIT_CENTS CONSOLE_LIMIT_CENTS MARGIN_CENTS SESSION_CAP_CENTS EXTERNAL_SPEND_CENTS; do
  [[ ${!v:-} =~ ^[0-9]+$ ]] || { echo "ERROR: $v in limits.conf must be a whole number of cents, no sign" >&2; exit 5; }
done

die() { echo "ERROR: $*" >&2; exit 5; }

key() {
  if [ -n "${ANTHROPIC_API_KEY:-}" ]; then printf '%s' "$ANTHROPIC_API_KEY"; else cat "$KEY_FILE"; fi
}
# The key reaches curl on stdin (printf is a builtin), never in argv.
call() {
  local method="$1" path="$2"
  shift 2
  printf 'header = "x-api-key: %s"\n' "$(key)" |
    curl -sS --fail-with-body -K - -X "$method" "$API$path" \
      -H "anthropic-version: 2026-10-21" \
      -H "anthropic-beta: managed-agents-2026-04-01,files-api-2025-04-14" \
      "$@"
}
json() { call "$1" "$2" -H "content-type: application/json" -d "$3"; }
prepare_state() {
  mkdir -p "$STATE" || die "cannot create $STATE"
  [ -f "$S_JSON" ] || echo '{}' >"$S_JSON"
}
put() {
  [ -n "$2" ] && [ "$2" != null ] || die "empty value for $1; nothing saved"
  jq --arg k "$1" --arg v "$2" '.[$k]=$v' "$S_JSON" >"$S_JSON.n" && mv "$S_JSON.n" "$S_JSON"
}
get() { jq -r --arg k "$1" '.[$k] // empty' "$S_JSON"; }
usd() { awk -v c="$1" 'BEGIN { printf "US$ %.2f", c / 100 }'; }
id_of() { jq -er '.id | select(type == "string" and . != "")'; }

# Sessions matching a filter, following the cursor, one JSON object per line.
list_sessions() {
  local filter="$1" cursor="" previous="" body
  while :; do
    body="$(call GET "/sessions?include_archived=true&limit=100&$filter${cursor:+&page=$cursor}")" ||
      die "cannot read this month's sessions; no session opens without the spend read"
    echo "$body" | jq -e '.data | type == "array"' >/dev/null ||
      die "response has no session list; no session opens without the spend read"
    echo "$body" | jq -c '.data[]'
    previous="$cursor"
    cursor="$(echo "$body" | jq -r '.next_page // empty')"
    [ -n "$cursor" ] || break
    [ "$cursor" != "$previous" ] || die "the API repeated the session list cursor"
  done
}

# This month's sessions (UTC) plus the live ones from any date, deduplicated.
month_sessions() {
  local month live
  month="$(list_sessions "created_at%5Bgte%5D=$(date -u +%Y-%m-01T00:00:00Z)")"
  live="$(list_sessions "statuses%5B%5D=running&statuses%5B%5D=idle&statuses%5B%5D=rescheduling")"
  printf '%s\n%s\n' "$month" "$live" | jq -sc 'map(select(. != null)) | unique_by(.id) | .[]'
}

# Committed cents this month: a finished session counts what it spent; a live one
# counts the larger of its spend and its cap, because it can still spend up to the cap.
committed_cents() {
  local lines
  lines="$(month_sessions)"
  echo "$lines" | jq -es --argjson ext "$EXTERNAL_SPEND_CENTS" '
    def c: (. // "0") | tonumber | ceil;
    if any(.[]; .status != "terminated" and (.budget.max_list_cost.amount == null))
    then error("a live session has no cap; archive it before opening another")
    else ([.[] | (.usage.list_cost.amount | c) as $s |
            if .status == "terminated" then $s
            else [$s, (.budget.max_list_cost.amount | c)] | max end] | add // 0) + $ext
    end' || die "cannot add up this month's commitment"
}

month_ceiling() {
  local a="$MONTHLY_CREDIT_CENTS" b="$CONSOLE_LIMIT_CENTS"
  [ "$a" -lt "$b" ] && echo "$a" || echo "$b"
}

upload() {
  local file="$1" k id
  k="file_$(sha256sum "$file" | cut -c1-16)"
  id="$(get "$k")"
  if [ -z "$id" ]; then
    id="$(call POST /files -F "file=@$file" | id_of)" || die "upload of $file failed"
    put "$k" "$id"
  fi
  echo "$id"
}

ensure_agent_and_environment() {
  local id
  if [ -z "$(get agent)" ] || [ "$(get agent_model)" != "$MODEL" ]; then
    id="$(json POST /agents "$(jq -n --arg m "$MODEL" '{name:"nuvem",model:$m,
      system:"You work alone in a disposable container and follow the brief in the first message.",
      tools:[{type:"agent_toolset_20260401",configs:[{name:"web_search",enabled:false},{name:"web_fetch",enabled:false}]}]}')" | id_of)" ||
      die "cannot create the agent"
    put agent "$id"
    put agent_model "$MODEL"
  fi
  if [ -z "$(get environment)" ]; then
    id="$(json POST /environments "$(jq -n --argjson h "$(printf '%s\n' "${ALLOWED_HOSTS[@]}" | jq -R . | jq -s .)" \
      '{name:"nuvem-limited",config:{type:"cloud",networking:{type:"limited",allow_package_managers:true,allowed_hosts:$h}}}')" | id_of)" ||
      die "cannot create the environment"
    put environment "$id"
  fi
}

status_of() {
  local st
  st="$(call GET "/sessions/$(sid)" | jq -r '.status // empty')" || return 1
  case "$st" in running | idle | rescheduling | terminated) echo "$st" ;; *) return 1 ;; esac
}

command="${1:-}"
name="${2:-}"
sid() { get "session_$name"; }
need_name() { [ -n "$name" ] && [ -n "$(sid)" ] || { echo "no session '$name'; see: $0 list" >&2; exit 2; }; }
[ -n "$command" ] && prepare_state

case "$command" in
spend)
  c="$(committed_cents)"
  echo "committed this month: $(usd "$c") (spend of finished sessions, caps of live ones, plus $(usd "$EXTERNAL_SPEND_CENTS") of declared external use)"
  echo "monthly credit: $(usd "$MONTHLY_CREDIT_CENTS") | Console limit: $(usd "$CONSOLE_LIMIT_CENTS") | margin: $(usd "$MARGIN_CENTS")"
  echo "free for new sessions: $(usd $(($(month_ceiling) - MARGIN_CENTS - c)))"
  ;;
start)
  dry=0
  args=()
  for a in "${@:3}"; do [ "$a" = "--dry-run" ] && dry=1 || args+=("$a"); done
  [ -n "$name" ] && [ -n "${args[0]:-}" ] || { echo "usage: $0 start <name> <brief.md> [cents] [support.tar.gz] [bundle] [--dry-run]" >&2; exit 2; }
  brief="${args[0]}"
  cents="${args[1]:-$SESSION_CAP_CENTS}"
  support="${args[2]:-}"
  bundle="${args[3]:-$STATE/$name.bundle}"
  [[ $cents =~ ^[1-9][0-9]*$ ]] || { echo "REFUSED: '$cents' is not a cap in cents (positive whole number)" >&2; exit 3; }
  [ "$cents" -le "$SESSION_CAP_CENTS" ] || { echo "REFUSED: $(usd "$cents") is over the per-session cap of $(usd "$SESSION_CAP_CENTS") (limits.conf)" >&2; exit 3; }
  # One opening at a time: two parallel reads would see the same spend.
  exec 9>"$STATE/.lock"
  flock -w 60 9 || die "another opening has held the lock for 60 s"
  c="$(committed_cents)"
  free=$(($(month_ceiling) - MARGIN_CENTS - c))
  if [ "$cents" -gt "$free" ]; then
    echo "REFUSED: $(usd "$c") committed this month; the session may spend $(usd "$cents"), but only $(usd "$free") fit under the monthly credit and the Console limit with the margin." >&2
    exit 4
  fi
  echo "ok: $(usd "$c") committed, session up to $(usd "$cents"), $(usd $((free - cents))) left"
  [ "$dry" = 1 ] && exit 0
  [ -z "$(sid)" ] || { echo "session '$name' already exists: $(sid)" >&2; exit 2; }
  [ -f "$brief" ] || { echo "missing brief $brief" >&2; exit 2; }
  [ -f "$bundle" ] || { echo "missing bundle $bundle; create it with: git bundle create $bundle <refs>" >&2; exit 2; }
  ensure_agent_and_environment
  bundle_id="$(upload "$bundle")"
  resources="$(jq -n --arg b "$bundle_id" '[{type:"file",file_id:$b,mount_path:"/repo.bundle"}]')"
  if [ -n "$support" ]; then
    support_id="$(upload "$support")"
    resources="$(echo "$resources" | jq --arg m "$support_id" '. + [{type:"file",file_id:$m,mount_path:"/support.tar.gz"}]')"
  fi
  text="$(cat "$SKILL/references/brief-base.md" "$brief")"
  id="$(json POST /sessions "$(jq -n --arg a "$(get agent)" --arg v "$(get environment)" --arg c "$cents" --arg t "$text" --argjson r "$resources" \
    '{agent:$a,environment_id:$v,budget:{type:"limit",max_list_cost:{amount:$c,currency:"USD"}},resources:$r,
      initial_events:[{type:"user.message",content:[{type:"text",text:$t}]}]}')" | id_of)" || die "cannot open the session"
  put "session_$name" "$id"
  echo "$name $id"
  ;;
status)
  need_name
  call GET "/sessions/$(sid)" | jq -c '{status,stop_reason,minutes:((.usage.active_seconds // 0) / 60 | floor),cost:.usage.list_cost.amount,cap:.budget.max_list_cost.amount}'
  ;;
wait)
  # Returns when the session stops running. Run it in the background.
  need_name
  errors=0
  while :; do
    if st="$(status_of)"; then
      errors=0
      [ "$st" = running ] || [ "$st" = rescheduling ] || break
    else
      errors=$((errors + 1))
      [ "$errors" -lt 5 ] || die "the API returned no known status 5 times in a row; the session may still be live"
    fi
    sleep 120
  done
  "$0" status "$name"
  call GET "/sessions/$(sid)/events?beta=true&limit=5&order=desc" | jq -r '.data[] | select(.type|test("error|idle")) | "\(.type) \(.stop_reason // .error // "" | tostring)"'
  ;;
events)
  need_name
  call GET "/sessions/$(sid)/events?beta=true&limit=${3:-20}&order=desc" |
    jq -r '.data[] | "\(.type) \(.content // .error // "" | tostring | .[0:300])"'
  ;;
fetch)
  need_name
  out="$STATE/out-$name"
  mkdir -p "$out"
  after=""
  failures=0
  while :; do
    body="$(call GET "/files?scope_id=$(sid)&limit=100${after:+&after_id=$after}")" || die "cannot list the session's files"
    while read -r id file; do
      case "$file" in *.bundle | support.tar.gz) continue ;; esac
      target="$out/$(basename "$file")"
      if call GET "/files/$id/content" -o "$target.part"; then
        mv "$target.part" "$target" && echo "$target"
      else
        rm -f "$target.part"
        echo "FAILED to download $file" >&2
        failures=$((failures + 1))
      fi
    done < <(echo "$body" | jq -r '.data[] | "\(.id) \(.filename)"')
    [ "$(echo "$body" | jq -r '.has_more')" = true ] || break
    after="$(echo "$body" | jq -r '.last_id')"
  done
  [ "$failures" -eq 0 ] || die "$failures download(s) failed; run fetch again before archiving"
  ;;
archive)
  need_name
  call POST "/sessions/$(sid)/archive" >/dev/null || die "cannot archive"
  "$0" status "$name"
  ;;
list)
  jq -r 'to_entries[] | select(.key|startswith("session_")) | "\(.key|ltrimstr("session_")) \(.value)"' "$S_JSON"
  ;;
costs)
  lines="$(month_sessions)"
  echo "$lines" | jq -rs --slurpfile s "$S_JSON" '
    ($s[0] | to_entries | map(select(.key|startswith("session_"))) | map({(.value): (.key|ltrimstr("session_"))}) | add // {}) as $names |
    (.[] | "\($names[.id] // .id)\t\(.status)\t\((.usage.active_seconds // 0) / 60 | floor) min\t\(.usage.list_cost.amount|tonumber)"),
    "total\t\t\t\([.[].usage.list_cost.amount|tonumber]|add // 0)"' |
    awk -F'\t' -v OFS='\t' '{ $4 = sprintf("US$ %.2f", $4 / 100); print }' | column -t -s $'\t'
  ;;
*)
  cat >&2 <<EOF
usage: $0 <command>
  spend                                   this month's commitment and what still fits
  start <name> <brief> [cents] [support.tar.gz] [bundle] [--dry-run]
                                          opens the session if it fits under the credit and the limit
  status | wait | events | fetch | archive <name>
  list                                    sessions in this state
  costs                                   this month's sessions with time and cost
EOF
  exit 2
  ;;
esac
