#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
ENGINE_DIR="$ROOT_DIR/engines/default"
BOTTLE_NAME="${1:-Steam}"
BOTTLE_DIR="$ROOT_DIR/bottles/$BOTTLE_NAME"

echo "=================================================="
echo " Vapor: Installing Steam into Bottle '$BOTTLE_NAME'"
echo "=================================================="

# Ensure engine is installed
if [ ! -f "$ENGINE_DIR/bin/wine64" ] && [ ! -f "$ENGINE_DIR/bin/wine" ]; then
    echo "[-] Engine not found. Running setup_engine.sh..."
    "$SCRIPT_DIR/setup_engine.sh"
fi

WINE_BIN="$ENGINE_DIR/bin/wine64"
[ ! -f "$WINE_BIN" ] && WINE_BIN="$ENGINE_DIR/bin/wine"
WINESERVER_BIN="$ENGINE_DIR/bin/wineserver"

# Configure environment
export WINEPREFIX="$BOTTLE_DIR"
export WINEARCH="win64"
export WINEDEBUG="-all"
export DYLD_FALLBACK_LIBRARY_PATH="$ENGINE_DIR/lib:$ENGINE_DIR/lib64:$DYLD_FALLBACK_LIBRARY_PATH"
export PATH="$ENGINE_DIR/bin:$PATH"

mkdir -p "$BOTTLE_DIR"

STEAM_EXE="$BOTTLE_DIR/drive_c/Program Files (x86)/Steam/steam.exe"

if [ -f "$STEAM_EXE" ]; then
    echo "✓ Steam is already installed in '$BOTTLE_NAME'!"
    echo "  Location: $STEAM_EXE"
    exit 0
fi

echo "[-] Initializing Windows bottle (win64)..."
"$WINE_BIN" wineboot -u

echo "[-] Linking macOS TrueType fonts into Windows bottle..."
mkdir -p "$BOTTLE_DIR/drive_c/windows/Fonts"
ln -sf /System/Library/Fonts/Supplemental/*.ttf "$BOTTLE_DIR/drive_c/windows/Fonts/" 2>/dev/null || true
ln -sf /Library/Fonts/*.ttf "$BOTTLE_DIR/drive_c/windows/Fonts/" 2>/dev/null || true

# Download official Steam installer

TEMP_INSTALLER="/tmp/SteamSetup.exe"
echo "[-] Downloading official Windows SteamSetup.exe..."
curl -L --progress-bar -o "$TEMP_INSTALLER" "https://cdn.cloudflare.steamstatic.com/client/installer/SteamSetup.exe"

echo "[-] Installing Steam silently into bottle..."
"$WINE_BIN" "$TEMP_INSTALLER" /S || true

echo "[-] Waiting for installation to complete..."
"$WINESERVER_BIN" -w

rm -f "$TEMP_INSTALLER"

if [ -f "$STEAM_EXE" ]; then
    echo "=================================================="
    echo "✓ Steam successfully installed in bottle '$BOTTLE_NAME'!"
    echo "  To launch: $ROOT_DIR/bin/vapor steam"
    echo "=================================================="
else
    echo "[!] Steam executable not detected at expected path yet."
    echo "    Wine prefix created at: $BOTTLE_DIR"
fi
