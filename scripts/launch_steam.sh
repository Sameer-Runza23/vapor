#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

if [ -w "$ROOT_DIR" ] && [ ! -d "$ROOT_DIR/../../MacOS" ] && [ -d "$ROOT_DIR/engines" ]; then
    VAPOR_DATA_DIR="${VAPOR_DATA_DIR:-$ROOT_DIR}"
else
    VAPOR_DATA_DIR="${VAPOR_DATA_DIR:-$HOME/Library/Application Support/Vapor}"
fi
mkdir -p "$VAPOR_DATA_DIR/engines" "$VAPOR_DATA_DIR/bottles"

BOTTLE_NAME="${1:-Steam}"
ENGINE_DIR="$VAPOR_DATA_DIR/engines/default"
BOTTLE_DIR="$VAPOR_DATA_DIR/bottles/$BOTTLE_NAME"
CONFIG_FILE="$VAPOR_DATA_DIR/config.env"

[ -f "$CONFIG_FILE" ] && source "$CONFIG_FILE"

export WINEPREFIX="$BOTTLE_DIR"
export WINEARCH="win64"
export WINEDEBUG="-all"
export WINEMSYNC=1
export WINESERVER="$ENGINE_DIR/bin/wineserver"
export WINELOADER="$ENGINE_DIR/bin/wineloader"
export DYLD_FALLBACK_LIBRARY_PATH="$ENGINE_DIR/lib64:$ENGINE_DIR/lib:$ENGINE_DIR/lib/external:/usr/lib"
export PATH="$ENGINE_DIR/bin:$PATH"

if [ "$HUD_ENABLED" = "1" ]; then
    export MTL_HUD_ENABLED=1
fi

STEAM_EXE="$BOTTLE_DIR/drive_c/Program Files (x86)/Steam/steam.exe"

if [ ! -f "$STEAM_EXE" ]; then
    echo "[!] Steam executable not found at: $STEAM_EXE"
    exit 1
fi

echo "=================================================="
echo " Vapor: Windows Steam (Standalone Engine)"
echo " Bottle: $BOTTLE_NAME ($BOTTLE_DIR)"
echo " Engine: Wine 11.0 & Apple D3DMetal"
echo " HUD: $([ "$HUD_ENABLED" = "1" ] && echo "ON" || echo "OFF")"
echo "=================================================="

shift 2>/dev/null || true
exec "$ENGINE_DIR/bin/wineloader" "$STEAM_EXE" "$@"
