#!/usr/bin/env bash
set -u
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
fail=0
check() { # name, expected exit, expected output pattern, file
  out="$(bash "$here/prune-check.sh" "$4")"; code=$?
  if [ "$code" -eq "$2" ] && grep -q -- "$3" <<<"$out"; then echo "pass: $1"
  else echo "FAIL: $1 (exit $code)"; echo "$out"; fail=1; fi
}
check "unpruned fixture still has CUT lines" 1 "^CUT left:" "$here/fixture/CLAUDE.md"
if bash "$here/prune-check.sh" "$here/fixture/CLAUDE.md" | grep -q "^KEEP lost:"; then
  echo "FAIL: keep.txt has a line the fixture lacks"; fail=1
else echo "pass: every KEEP line exists in the fixture"; fi
cp "$here/expected/keep.txt" "$tmp/good.md"
check "KEEP-only file passes" 0 "^ok:" "$tmp/good.md"
grep -v "12-minute" "$here/expected/keep.txt" > "$tmp/lost.md"
check "dropped KEEP line fails" 1 "^KEEP lost: - Single test" "$tmp/lost.md"
sed 's/Coerce with/Convert with/' "$here/expected/keep.txt" > "$tmp/reworded.md"
check "reworded KEEP line fails" 1 "^KEEP lost: - \`db.execute" "$tmp/reworded.md"
{ cat "$here/expected/keep.txt"; echo "    - Prefer const over let  "; } > "$tmp/indented.md"
check "CUT line left with other indentation fails" 1 "^CUT left: - Prefer const" "$tmp/indented.md"
exit "$fail"
