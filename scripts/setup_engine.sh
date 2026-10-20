#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
BIN_DIR="$ROOT_DIR/bin"
ENGINES_DIR="$ROOT_DIR/engines"
DEFAULT_ENGINE_DIR="$ENGINES_DIR/default"
SEVEN_ZIP="$BIN_DIR/7zz"

ENGINE_URL="https://github.com/The-Wineskin-Project/Engines/releases/download/v1.0/WS12WineCX64Bit23.7.1-4_D3DMetal-v2.1.tar.7z"
ENGINE_ARCHIVE="$ENGINES_DIR/engine.tar.7z"

echo "=================================================="
echo " Vapor: Engine Setup (Wine-CX + Apple D3DMetal 2)"
echo "=================================================="

if [ -f "$DEFAULT_ENGINE_DIR/bin/wine64" ] || [ -f "$DEFAULT_ENGINE_DIR/bin/wine" ]; then
    echo "✓ Wine engine is already installed at: $DEFAULT_ENGINE_DIR"
    exit 0
fi

mkdir -p "$ENGINES_DIR"
mkdir -p "$BIN_DIR"

if [ ! -f "$SEVEN_ZIP" ]; then
    echo "[-] Downloading 7zz extractor..."
    curl -L -s -o "$BIN_DIR/7z.tar.xz" "https://github.com/ip7z/7zip/releases/download/26.04/7z2604-mac.tar.xz"
    tar -xf "$BIN_DIR/7z.tar.xz" -C "$BIN_DIR"
    rm -f "$BIN_DIR/7z.tar.xz"
    chmod +x "$SEVEN_ZIP"
    echo "✓ 7zz installed."
fi

echo "[-] Downloading Wine-CX + D3DMetal (approx. 182 MB)..."
echo "    URL: $ENGINE_URL"
curl -L --progress-bar -o "$ENGINE_ARCHIVE" "$ENGINE_URL"

echo "[-] Extracting engine archive..."
TEMP_EXTRACT="$ENGINES_DIR/temp_extract"
rm -rf "$TEMP_EXTRACT"
mkdir -p "$TEMP_EXTRACT"

# Extract .tar.7z: first 7zz unpacks to .tar, then tar unpacks
"$SEVEN_ZIP" x "$ENGINE_ARCHIVE" -so | tar -xf - -C "$TEMP_EXTRACT"

# Find the extracted engine root
EXTRACTED_SUBDIR=$(find "$TEMP_EXTRACT" -maxdepth 2 -type d -name "bin" | head -n 1)
if [ -n "$EXTRACTED_SUBDIR" ]; then
    ENGINE_ROOT="$(dirname "$EXTRACTED_SUBDIR")"
    rm -rf "$DEFAULT_ENGINE_DIR"
    mv "$ENGINE_ROOT" "$DEFAULT_ENGINE_DIR"
else
    mv "$TEMP_EXTRACT" "$DEFAULT_ENGINE_DIR"
fi

rm -rf "$TEMP_EXTRACT"
rm -f "$ENGINE_ARCHIVE"

# Ensure execute permissions on binaries
chmod +x "$DEFAULT_ENGINE_DIR/bin"/* 2>/dev/null || true

# Compile libinotify shim for macOS if missing
if [ ! -f "$DEFAULT_ENGINE_DIR/lib/external/libinotify.0.dylib" ]; then
    echo "[-] Compiling inotify compatibility shim for macOS..."
    mkdir -p "$DEFAULT_ENGINE_DIR/lib/external"
    cat << 'EOF' > /tmp/inotify_shim.c
#include <errno.h>
int inotify_init(void) { errno = ENOSYS; return -1; }
int inotify_init1(int flags) { errno = ENOSYS; return -1; }
int inotify_add_watch(int fd, const char *pathname, unsigned int mask) { errno = ENOSYS; return -1; }
int inotify_rm_watch(int fd, int wd) { errno = ENOSYS; return -1; }
EOF
    clang -target x86_64-apple-macos10.15 -shared -install_name @rpath/libinotify.0.dylib -o "$DEFAULT_ENGINE_DIR/lib/external/libinotify.0.dylib" /tmp/inotify_shim.c
    rm -f /tmp/inotify_shim.c
    echo "✓ inotify shim installed."
fi

echo "✓ Wine-CX engine with D3DMetal installed successfully!"
echo "  Location: $DEFAULT_ENGINE_DIR"

