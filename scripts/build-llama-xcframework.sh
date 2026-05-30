#!/bin/zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
VENDOR_DIR="$ROOT_DIR/Vendor"
LLAMA_DIR="$VENDOR_DIR/llama.cpp"
FRAMEWORK_DIR="$VENDOR_DIR/Frameworks"

mkdir -p "$VENDOR_DIR" "$FRAMEWORK_DIR"

if [ ! -d "$LLAMA_DIR/.git" ]; then
  git clone https://github.com/ggml-org/llama.cpp.git "$LLAMA_DIR"
fi

cd "$LLAMA_DIR"
./build-xcframework.sh
rsync -a "$LLAMA_DIR/build-apple/llama.xcframework" "$FRAMEWORK_DIR/"

echo "Copied llama.xcframework to $FRAMEWORK_DIR/llama.xcframework"
