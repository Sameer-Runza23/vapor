#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
ENGINE_DIR="$ROOT_DIR/engines/default"
CONFIG_FILE="$ROOT_DIR/config.env"

[ -f "$CONFIG_FILE" ] && source "$CONFIG_FILE"

EXE_PATH="$1"
BOTTLE_NAME="${2:-Steam}"
BOTTLE_DIR="$ROOT_DIR/bottles/$BOTTLE_NAME"

if [ -z "$EXE_PATH" ]; then
    echo "Usage: vapor run <path/to/app.exe> [bottle_name] [args...]"
    exit 1
fi

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

echo "=================================================="
echo " Vapor: Executing Windows Binary"
echo " Target: $EXE_PATH"
echo " Bottle: $BOTTLE_NAME"
echo " Engine: Standalone Wine 11.0 & Apple D3DMetal"
echo "=================================================="

exec "$ENGINE_DIR/bin/wineloader" "$EXE_PATH" "${@:3}"
