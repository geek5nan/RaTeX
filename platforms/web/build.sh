#!/usr/bin/env bash
set -e
cd "$(dirname "$0")"
echo "Building ratex-wasm for web..."
wasm-pack build ../../crates/ratex-wasm --target web --out-dir "$(pwd)/pkg"
# wasm-pack writes pkg/.gitignore with "*"; npm pack honors it and omits all pkg/ files from the tarball.
rm -f "$(pwd)/pkg/.gitignore"
echo "Done. Output in platforms/web/pkg/"
