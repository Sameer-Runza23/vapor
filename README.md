# 🎮 Vapor - Zero-Limit Windows Gaming Tool for macOS

**Vapor** is an open-source, free alternative to CrossOver for Apple Silicon Macs (M1/M2/M3/M4). It enables you to run Windows Steam and DirectX 11/DirectX 12 games on macOS without paid licenses, trial limits, or VM overhead.

---

## ⚡ How It Works Under The Hood

* **Wine-CX (CrossOver Engine 23.7.1):** High-performance Windows API compatibility layer.
* **Apple D3DMetal 2 (Game Porting Toolkit 2):** Translates DirectX 11 and DirectX 12 calls directly into Apple Metal 3 shaders and GPU queues.
* **Rosetta 2:** Transparently translates x86_64 Windows binaries into Apple Silicon ARM64 instructions.
* **CEF Sandbox Bypass (`-no-cef-sandbox`):** Ensures the modern Chromium-based Steam UI, store, downloads, and game library run seamlessly without black screens.
* **Live Apple Metal HUD:** Built-in FPS, GPU frame times, and VRAM monitoring overlay.

---

## 🚀 Quick Start

### 1. Launch via Graphical App (GUI)
You can launch the native macOS desktop app anytime:
```bash
open "/Users/sameerrunza/.gemini/antigravity/scratch/vapor/Vapor.app"
```
Or directly from Terminal:
```bash
/Users/sameerrunza/.gemini/antigravity/scratch/vapor/bin/vapor gui
```

### 2. Launch via Terminal (CLI)
To directly start Windows Steam:
```bash
/Users/sameerrunza/.gemini/antigravity/scratch/vapor/bin/vapor steam
```

---

## 🛠️ CLI Commands Cheatsheet

```bash
# Launch Windows Steam with Apple Metal 3 acceleration
vapor steam

# Toggle Apple Metal Performance HUD (Live FPS & GPU stats)
vapor hud on      # Enable FPS overlay in games
vapor hud off     # Disable overlay
vapor hud status  # Check current state

# Run any standalone Windows game or installer (.exe)
vapor run "/path/to/game.exe"

# Open Wine Configuration GUI (adjust Windows version, audio, DPI)
vapor winecfg

# Open Windows Task Manager (inspect game CPU/RAM usage)
vapor taskmgr

# Force kill any stuck game or Wine background processes
vapor kill

# Reinstall or initialize Steam bottle
vapor install-steam
```

---

## 📂 Project Directory Structure

```text
vapor/
├── Vapor.app/               # Native macOS SwiftUI Desktop Application
├── bin/
│   ├── vapor                # Master CLI tool
│   └── 7zz                  # Native arm64 archive extractor
├── engines/
│   └── default/             # Wine-CX + Apple D3DMetal (GPTK 2)
│       ├── bin/             # wine64, wineserver
│       ├── lib/             # Wine libraries, D3DMetal.framework
│       └── lib/external/    # libd3dshared.dylib, libinotify.0.dylib
├── bottles/
│   └── Steam/               # Windows 64-bit bottle containing Steam & installed games
│       └── drive_c/
│           ├── Program Files (x86)/Steam/steam.exe
│           └── windows/Fonts/
└── scripts/
    ├── setup_engine.sh      # Engine setup
    ├── install_steam.sh     # Steam installer
    ├── launch_steam.sh      # Steam launcher
    └── run_exe.sh           # Standalone .exe runner
```

---

## 💡 Tips for Maximum Gaming Performance

1. **Enable Metal HUD:** Run `vapor hud on` before launching your game to verify real-time FPS and Metal rendering pipeline status.
2. **Game Compatibility:** Games that use DirectX 11, DirectX 12, or Vulkan generally run with near-native performance on M-series chips. (Anti-cheat kernel drivers like EasyAntiCheat or Vanguard that require Windows kernel ring 0 are the only common limitation, identical to CrossOver and Proton).
3. **Steam Downloads:** Games installed inside Steam will be saved to:
   `bottles/Steam/drive_c/Program Files (x86)/Steam/steamapps/common/`
