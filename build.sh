#!/bin/bash

set -e

echo "=== Metanit C++ Port — Build ==="

rm -rf build
mkdir build
cd build

cmake .. -G Ninja
cmake --build . -j$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 4)

echo ""
echo "✅ Build complete: build/metanit_port"
echo "   Run: ./build/metanit_port"
