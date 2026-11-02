#!/usr/bin/env bash
set -uo pipefail
cd "$(dirname "$0")"
ROOT="$(cd ../../.. && pwd)"
CLANGXX="$ROOT/install/lib/llvm/bin/clang++"
mkdir -p build

if "$CLANGXX" -x hip --offload-arch=spvcpu -Wno-unused-value hip_symbol.hip \
  -o build/hip_symbol 2>build/compile.log; then
  echo "COMPILE-OK"
  ./build/hip_symbol
else
  echo "COMPILE-FAIL:"
  tail -8 build/compile.log
  exit 1
fi
