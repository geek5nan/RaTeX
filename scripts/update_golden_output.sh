#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FONT_DIR="$ROOT/tools/lexer_compare/node_modules/katex/dist/fonts"
OUTPUT_DIR="$ROOT/tests/golden/output"
TEST_CASES="$ROOT/tests/golden/test_cases.txt"
TMP_ERR="$(mktemp)"
trap 'rm -f "$TMP_ERR"' EXIT

echo "Building ratex-render (release)..."
cargo build --release -p ratex-render

echo "Clearing old output..."
rm -f "$OUTPUT_DIR"/*.png

echo "Rendering formulas..."
cargo run --release -p ratex-render --bin render -- \
  --font-dir "$FONT_DIR" \
  --output-dir "$OUTPUT_DIR" \
  < "$TEST_CASES" 2>"$TMP_ERR"

if [[ -s "$TMP_ERR" ]]; then
  failed_count=$(grep -c '^ERR' "$TMP_ERR" 2>/dev/null || true)
  echo ""
  echo "Failed: $failed_count case(s)"
  grep '^ERR' "$TMP_ERR" || true
fi

echo "Done."
