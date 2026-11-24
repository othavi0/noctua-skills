#!/usr/bin/env bash
# Runs scripts/nuvem.sh fetch against a fake curl on PATH: no network, no key, no credit.
# Usage: bash evals/nuvem-script.test.sh   (needs bash, jq)
set -uo pipefail
HERE=$(cd "$(dirname "$0")/.." && pwd)
NS="$HERE/scripts/nuvem.sh"
T=$(mktemp -d)
trap 'rm -rf "$T"' EXIT
fails=0
# shellcheck disable=SC2053 # the third argument is a glob pattern
check() { if [[ "$2" == $3 ]]; then echo "ok   $1"; else echo "FAIL $1: got '$2', want '$3'"; fails=$((fails + 1)); fi; }

mkdir -p "$T/bin" "$T/state" "$T/config"
echo '{"session_x":"sesn_test"}' >"$T/state/state.json"
# The fake API. Page 1 holds the uploads the session mounted (not downloadable, as the
# real API marks them), one output and one output whose download fails with a 500.
cat >"$T/bin/curl" <<'FAKE'
#!/usr/bin/env bash
log="$FAKE_DIR/curl.log"
grep -q "x-api-key: $ANTHROPIC_API_KEY" && echo "stdin-key=yes" >>"$log"
out="" wfmt="" url=""
while [ $# -gt 0 ]; do
  case "$1" in
  -o) out="$2"; shift ;;
  -w) wfmt="$2"; shift ;;
  -H) echo "header $2" >>"$log"; shift ;;
  -K | -X | -d | -F) shift ;;
  http*) url="$1" ;;
  esac
  shift
done
echo "argv $*" >>"$log"
echo "url $url" >>"$log"
f() { printf '{"type":"file","id":"%s","filename":"%s","downloadable":%s}' "$1" "$2" "$3"; }
code=200
case "$url" in
*"/files?scope_id=sesn_test"*"page=p2"*)
  body="{\"data\":[$(f file_report report.md true)],\"next_page\":null,\"has_more\":false}" ;;
*"/files?scope_id=sesn_test"*"after_id="*)
  code=400 body='{"type":"error","error":{"message":"after_id is not supported"}}' ;;
*"/files?scope_id=sesn_test"*)
  body="{\"data\":[$(f file_patch x.patch true),$(f file_apoio x-apoio.tar.gz false),$(f file_bundle x.bundle false),$(f file_broken quebrado.txt true)],\"next_page\":\"p2\",\"has_more\":true,\"last_id\":\"file_broken\"}" ;;
*/files/file_patch/content) body="patch-body" ;;
*/files/file_report/content) body="report-body" ;;
*/files/file_broken/content) code=500 body='{"type":"error","error":{"type":"api_error","message":"internal boom"}}' ;;
*/files/*/content) code=400 body='{"type":"error","error":{"message":"is not downloadable"}}' ;;
*) code=404 body='{"type":"error","error":{"message":"not found"}}' ;;
esac
if [ -n "$out" ]; then printf '%s' "$body" >"$out"; else printf '%s' "$body"; fi
[ -n "$wfmt" ] && printf '%s' "${wfmt//'%{http_code}'/$code}"
if [ "$code" -ge 400 ]; then echo "curl: (22) The requested URL returned error: $code" >&2; exit 22; fi
FAKE
chmod +x "$T/bin/curl"

run() { PATH="$T/bin:$PATH" FAKE_DIR="$T" ANTHROPIC_API_KEY=sk-fake-eval-key NUVEM_STATE="$T/state" NUVEM_CONFIG="$T/config" bash "$NS" "$@"; }

out=$(run fetch x 2>&1); code=$?
check "fetch exits 5 when one download fails" "$code" "5"
check "fetch downloads the outputs on both pages" "$(cat "$T/state/out-x/x.patch" "$T/state/out-x/report.md" 2>/dev/null)" "patch-bodyreport-body"
check "fetch follows the next_page cursor" "$(grep -c 'page=p2' "$T/curl.log")" "1"
check "fetch never asks for a file the API marks not downloadable" "$(grep -cE 'file_(apoio|bundle)/content' "$T/curl.log")" "0"
check "a failed download names the HTTP code, the endpoint and the API message" "$out" "*FAILED to download quebrado.txt: HTTP 500 from GET /files/file_broken/content: internal boom*"
check "fetch counts only the real failure" "$out" "*ERROR: 1 download(s) failed*"
check "no partial file is left behind" "$(find "$T/state/out-x" -name '*.part' | wc -l)" "0"
check "every request sends only the managed-agents beta" "$(grep '^header anthropic-beta' "$T/curl.log" | sort -u)" "header anthropic-beta: managed-agents-2026-04-01"
check "the key reaches curl on stdin" "$(grep -c '^stdin-key=yes' "$T/curl.log")" "$(grep -c '^url ' "$T/curl.log")"
check "the key is never in argv" "$(grep -c 'sk-fake-eval-key' "$T/curl.log")" "0"

echo "$fails failure(s)"
[ "$fails" -eq 0 ]
