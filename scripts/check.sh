#!/bin/sh
# Checks that both install scripts parse, and that the blocks marked
# "# >>> shared <name>" ... "# <<< shared <name>" are the same in
# cli/index.html and engine/index.html apart from the binary name.
# Cloudflare Pages serves each file as is, so nothing else keeps them in step.
set -eu
cd "$(dirname "$0")/.."

# blocks <file> <binary>: every shared block, the binary name replaced by BIN.
blocks() {
  awk '/^ *# >>> shared /{on=1} on{print} /^ *# <<< shared /{on=0}' "$1" | sed "s/$2/BIN/g"
}

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
fail=0
for f in cli/index.html engine/index.html; do
  bash -n "$f" || { echo "$f does not parse"; fail=1; }
done
blocks cli/index.html inferencesh > "$TMP/cli"
blocks engine/index.html inferencesh-engine > "$TMP/engine"
n=$(grep -c '# >>> shared' "$TMP/cli" || true)
[ "$n" -gt 0 ] || { echo "no shared blocks in cli/index.html"; exit 1; }
if ! diff -u --label engine/index.html --label cli/index.html "$TMP/engine" "$TMP/cli"; then
  echo "shared blocks differ between cli/index.html and engine/index.html"
  fail=1
fi
[ "$fail" = 1 ] || echo "ok: $n shared blocks match"
exit "$fail"
