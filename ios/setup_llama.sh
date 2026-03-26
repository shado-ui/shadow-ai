#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LLAMA_DIR="$SCRIPT_DIR/llama-cpp-src"
BUILD_DIR="$SCRIPT_DIR/llama-cpp-build"
OUTPUT_DIR="$SCRIPT_DIR/llama-lib"

echo "=== Setting up llama.cpp for iOS (arm64) ==="

if [ -f "$OUTPUT_DIR/lib/libllama-ios.a" ] && [ -f "$OUTPUT_DIR/include/llama.h" ]; then
    echo "llama.cpp already built, skipping."
    exit 0
fi

if [ ! -d "$LLAMA_DIR" ]; then
    echo "Cloning llama.cpp (pinned to b8514)..."
    git clone --depth 1 --branch b8514 https://github.com/ggml-org/llama.cpp.git "$LLAMA_DIR"
fi

echo "Building llama.cpp for iOS arm64..."
rm -rf "$BUILD_DIR"

IOS_SDK=$(xcrun --sdk iphoneos --show-sdk-path)

cmake -B "$BUILD_DIR" \
    -DCMAKE_SYSTEM_NAME=iOS \
    -DCMAKE_OSX_SYSROOT="$IOS_SDK" \
    -DCMAKE_OSX_ARCHITECTURES=arm64 \
    -DCMAKE_OSX_DEPLOYMENT_TARGET=16.0 \
    -DCMAKE_BUILD_TYPE=Release \
    -DGGML_METAL=OFF \
    -DGGML_ACCELERATE=ON \
    -DBUILD_SHARED_LIBS=OFF \
    -DLLAMA_BUILD_TESTS=OFF \
    -DLLAMA_BUILD_EXAMPLES=OFF \
    -DLLAMA_BUILD_SERVER=OFF \
    "$LLAMA_DIR"

cmake --build "$BUILD_DIR" --config Release -j$(sysctl -n hw.ncpu)

echo "Collecting static libraries..."
mkdir -p "$OUTPUT_DIR/lib" "$OUTPUT_DIR/include"

STATIC_LIBS=$(find "$BUILD_DIR" -name "*.a" -type f)
echo "Found: $STATIC_LIBS"

libtool -static -o "$OUTPUT_DIR/lib/libllama-ios.a" $STATIC_LIBS

echo "Copying all headers..."
find "$LLAMA_DIR" -path "*/include/*.h" -exec cp {} "$OUTPUT_DIR/include/" \; 2>/dev/null || true
find "$LLAMA_DIR" -path "*/src/*.h" -name "llama-*.h" -exec cp {} "$OUTPUT_DIR/include/" \; 2>/dev/null || true

echo "=== Done ==="
ls -la "$OUTPUT_DIR/lib/"
ls -la "$OUTPUT_DIR/include/"
