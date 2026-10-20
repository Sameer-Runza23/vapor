# Contributing to Vapor 🎮

Thank you for your interest in contributing to **Vapor**! Our goal is to provide a seamless, 100% free, and high-performance Windows gaming engine for Apple Silicon Macs.

---

## 🕹️ Reporting Game Compatibility

One of the best ways to contribute is testing Windows games and reporting results.

When submitting a compatibility report (via GitHub Issues), please include:
- **Game Name:** (e.g. Counter-Strike 2, Cyberpunk 2077)
- **Mac Model & Specs:** (e.g. Mac mini M2 Pro, 16GB RAM)
- **macOS Version:** (e.g. macOS Sonoma 14.6 / Sequoia 15.0)
- **Graphics Settings:** (e.g. 1920x1080 Medium, FSR Enabled)
- **Average FPS:** (Obtained using `vapor hud on` Metal HUD)
- **Status:**
  - 🟢 **Playable:** Smooth gameplay with no game-breaking glitches.
  - 🟡 **Runs with Issues:** Visual artifacts, occasional frame drops, or audio stutter.
  - 🔴 **Unplayable:** Crashes on launch, anti-cheat blocking, or black screen.

---

## 💻 Code Contributions

### Development Setup
1. Clone your fork:
   ```bash
   git clone https://github.com/Sameer-Runza23/vapor.git
   cd vapor
   ```
2. Download engine and build GUI:
   ```bash
   ./scripts/setup_engine.sh
   ./scripts/build_dmg.sh
   ```
3. Test locally:
   ```bash
   ./bin/vapor gui
   ```

### Pull Request Guidelines
- Ensure all paths remain dynamic (never hardcode personal user paths).
- Test on Apple Silicon macOS (M1/M2/M3/M4).
- Keep commit messages concise and descriptive.

---

## 🛡️ Anti-Cheat & VAC Notice
Vapor launches Steam in clean vanilla mode (`-no-cef-sandbox`). We strictly adhere to fair play and do not support cheats, memory injectors, or bypassing official server security checks.
