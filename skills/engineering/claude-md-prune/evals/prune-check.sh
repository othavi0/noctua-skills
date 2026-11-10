#!/usr/bin/env bash
# Usage: prune-check.sh <pruned CLAUDE.md>
# Run the skill on a copy of evals/fixture, then point this at the result.
# Passes when every line of expected/keep.txt survives verbatim and no line of
# expected/cut.txt remains. The report must also flag `bun db:generate` as drift:
# package.json has no such script. That line is in neither list.
# KEEP lines match exactly. CUT lines match ignoring leading and trailing spaces.
set -u
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
file="${1:?usage: prune-check.sh <pruned CLAUDE.md>}"
[ -f "$file" ] || { echo "no such file: $file" >&2; exit 2; }
fail=0
trim() { sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//'; }
while IFS= read -r line; do
  [ -n "$line" ] || continue
  grep -Fxq -- "$line" "$file" || { echo "KEEP lost: $line"; fail=1; }
done < "$here/expected/keep.txt"
while IFS= read -r line; do
  [ -n "$line" ] || continue
  line="$(trim <<<"$line")"
  trim < "$file" | grep -Fxq -- "$line" && { echo "CUT left: $line"; fail=1; }
done < "$here/expected/cut.txt"
[ "$fail" -eq 0 ] && echo "ok: KEEP intact, CUT gone"
exit "$fail"
