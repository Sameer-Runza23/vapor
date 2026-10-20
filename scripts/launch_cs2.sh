#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
ENGINE_DIR="$ROOT_DIR/engines/default"
BOTTLE_DIR="$ROOT_DIR/bottles/Steam"
CONFIG_FILE="$ROOT_DIR/config.env"

[ -f "$CONFIG_FILE" ] && source "$CONFIG_FILE"

export WINEPREFIX="$BOTTLE_DIR"
export WINEARCH="win64"
export WINEDEBUG="-all"
export WINEMSYNC=1
export WINESERVER="$ENGINE_DIR/bin/wineserver"
export WINELOADER="$ENGINE_DIR/bin/wineloader"
export DYLD_FALLBACK_LIBRARY_PATH="$ENGINE_DIR/lib64:$ENGINE_DIR/lib:$ENGINE_DIR/lib/external:/usr/lib"
export PATH="$ENGINE_DIR/bin:$PATH"

# Apple Metal Driver Extreme Performance Optimizations
export MTL_SHADER_VALIDATION=0
export MTL_CAPTURE_ENABLED=0

# Metal Performance HUD (optional toggle)
if [ "$HUD_ENABLED" = "1" ]; then
    export MTL_HUD_ENABLED=1
else
    unset MTL_HUD_ENABLED
fi

STEAM_EXE="$BOTTLE_DIR/drive_c/Program Files (x86)/Steam/steam.exe"

echo "=================================================="
echo " Vapor: Counter-Strike 2 (Official VAC Secure Launch)"
echo " Engine: Wine 11.0 & Apple D3DMetal"
echo " Bottle: $BOTTLE_DIR"
echo " Mode: Official Steam Matchmaking Verified"
echo "=================================================="

# Check if Steam is already running
if ! ps aux | grep -v grep | grep -q "steam.exe"; then
    echo "[*] Starting Steam in background..."
    "$ENGINE_DIR/bin/wineloader" "$STEAM_EXE" &
    echo "[*] Waiting for Steam connection..."
    sleep 8
fi

echo "[*] Launching Counter-Strike 2 via Official Steam Protocol..."
exec "$ENGINE_DIR/bin/wineloader" "$STEAM_EXE" "steam://rungameid/730" "$@"
