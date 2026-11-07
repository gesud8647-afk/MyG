#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
ref='4762ad7316dcdec20016ab5985fb46a27902204d'
if [[ ! -d .llama-src/.git ]]; then
  git clone --depth 1 --branch b6000 https://github.com/ggml-org/llama.cpp.git .llama-src
fi
actual=$(git -C .llama-src rev-parse HEAD)
[[ "$actual" == "$ref" ]] || { echo 'Commit llama.cpp diverso dal riferimento verificato.' >&2; exit 1; }
cmake -S .llama-src -B build-engine \
  -DCMAKE_SYSTEM_NAME=iOS \
  -DCMAKE_SYSTEM_PROCESSOR=arm64 \
  -DCMAKE_OSX_SYSROOT=iphoneos \
  -DCMAKE_OSX_ARCHITECTURES=arm64 \
  -DCMAKE_OSX_DEPLOYMENT_TARGET=16.0 \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_TRY_COMPILE_TARGET_TYPE=STATIC_LIBRARY \
  -DBUILD_SHARED_LIBS=OFF \
  -DGGML_BACKEND_DL=OFF \
  -DGGML_NATIVE=OFF \
  -DGGML_METAL=OFF \
  -DGGML_BLAS=OFF \
  -DGGML_ACCELERATE=ON \
  -DGGML_OPENMP=OFF \
  -DGGML_LLAMAFILE=OFF \
  -DLLAMA_BUILD_COMMON=OFF \
  -DLLAMA_BUILD_TESTS=OFF \
  -DLLAMA_BUILD_EXAMPLES=OFF \
  -DLLAMA_BUILD_TOOLS=OFF \
  -DLLAMA_BUILD_SERVER=OFF
cmake --build build-engine --config Release --target llama --parallel 3
mkdir -p Vendor/include
cp .llama-src/include/*.h Vendor/include/
cp .llama-src/ggml/include/*.h Vendor/include/
python3 - <<'PY'
from pathlib import Path
import subprocess
libs = sorted(str(p.resolve()) for p in Path('build-engine').rglob('*.a'))
if not any(Path(p).name == 'libllama.a' for p in libs): raise SystemExit('libllama.a non generato')
if not any(Path(p).name == 'libggml-cpu.a' for p in libs): raise SystemExit('Backend CPU mancante')
subprocess.run(['xcrun','libtool','-static','-o','Vendor/libpocket-llama.a',*libs],check=True)
PY
xcrun --sdk iphoneos clang++ -arch arm64 -miphoneos-version-min=16.0 \
  -std=c++17 -Wall -Wextra -fsyntax-only -I Vendor/include PocketAI/PocketBridge.cpp
lipo Vendor/libpocket-llama.a -verify_arch arm64
