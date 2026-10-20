#!/usr/bin/env bash
set -e

# ==============================================================================
#  🎮 Vapor Installer - Windows Gaming Engine for Apple Silicon macOS
#  GitHub: https://github.com/Sameer-Runza23/vapor
# ==============================================================================

BOLD="\033[1m"
GREEN="\033[32m"
CYAN="\033[36m"
YELLOW="\033[33m"
RED="\033[31m"
RESET="\033[0m"

echo -e "${CYAN}${BOLD}"
cat << 'EOF'
 __      __                           
 \ \    / /                           
  \ \  / /_ _ _ __   ___  _ __        
   \ \/ / _` | '_ \ / _ \| '__|       
    \  / (_| | |_) | (_) | |          
     \/ \__,_| .__/ \___/|_|          
             | |                      
             |_|                      
EOF
echo -e "${RESET}"
echo -e "${BOLD}Zero-Limit Windows Gaming Engine for macOS (Apple Silicon)${RESET}"
echo "=================================================================="

# 1. System checks
echo -e "\n${BOLD}[1/5] Verifying System Requirements...${RESET}"

if [[ "$OSTYPE" != "darwin"* ]]; then
    echo -e "${RED}[Error] Vapor only supports macOS.${RESET}"
    exit 1
fi

ARCH="$(uname -m)"
if [[ "$ARCH" != "arm64" ]]; then
    echo -e "${RED}[Error] Vapor requires Apple Silicon (M1, M2, M3, M4 or newer). Detected: $ARCH${RESET}"
    exit 1
fi
echo -e "${GREEN}✓ Apple Silicon architecture detected ($ARCH).${RESET}"

# Check Rosetta 2
if ! arch -x86_64 /usr/bin/true 2>/dev/null; then
    echo -e "${YELLOW}[!] Rosetta 2 is required to translate x86_64 Windows binaries.${RESET}"
    echo "[-] Installing Rosetta 2..."
    softwareupdate --install-rosetta --agree-to-license
    echo -e "${GREEN}✓ Rosetta 2 installed.${RESET}"
else
    echo -e "${GREEN}✓ Rosetta 2 translation layer is active.${RESET}"
fi

# 2. Setup Destination Directory
INSTALL_DIR="$HOME/.vapor"
echo -e "\n${BOLD}[2/5] Setting up Vapor in: $INSTALL_DIR...${RESET}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd || echo "")"

if [ -f "$SCRIPT_DIR/bin/vapor" ]; then
    # Running from local repo
    if [ "$SCRIPT_DIR" != "$INSTALL_DIR" ]; then
        echo "[-] Syncing local files to $INSTALL_DIR..."
        mkdir -p "$INSTALL_DIR"
        rsync -a --exclude 'engines' --exclude 'bottles' --exclude '.git' "$SCRIPT_DIR/" "$INSTALL_DIR/"
    fi
else
    # Running via remote curl
    if [ -d "$INSTALL_DIR/.git" ]; then
        echo "[-] Updating existing Vapor repository..."
        cd "$INSTALL_DIR" && git pull --quiet
    else
        echo "[-] Cloning Vapor repository from GitHub..."
        rm -rf "$INSTALL_DIR"
        git clone https://github.com/Sameer-Runza23/vapor.git "$INSTALL_DIR"
    fi
fi

chmod +x "$INSTALL_DIR/bin/vapor"
chmod +x "$INSTALL_DIR"/scripts/*.sh 2>/dev/null || true

# 3. Setup CLI Command in PATH
echo -e "\n${BOLD}[3/5] Installing 'vapor' command line interface...${RESET}"
CLI_LINK="/usr/local/bin/vapor"
ALT_CLI_DIR="$HOME/.local/bin"
ALT_CLI_LINK="$ALT_CLI_DIR/vapor"

if [ -w "/usr/local/bin" ]; then
    ln -sf "$INSTALL_DIR/bin/vapor" "$CLI_LINK"
    echo -e "${GREEN}✓ Symlinked vapor to $CLI_LINK${RESET}"
else
    mkdir -p "$ALT_CLI_DIR"
    ln -sf "$INSTALL_DIR/bin/vapor" "$ALT_CLI_LINK"
    echo -e "${GREEN}✓ Symlinked vapor to $ALT_CLI_LINK${RESET}"

    # Check if ~/.local/bin is in PATH
    if [[ ":$PATH:" != *":$ALT_CLI_DIR:"* ]]; then
        SHELL_RC="$HOME/.zshrc"
        [ -f "$HOME/.bashrc" ] && [ ! -f "$HOME/.zshrc" ] && SHELL_RC="$HOME/.bashrc"
        if ! grep -q "$ALT_CLI_DIR" "$SHELL_RC" 2>/dev/null; then
            echo "export PATH=\"\$HOME/.local/bin:\$PATH\"" >> "$SHELL_RC"
            echo -e "${YELLOW}[i] Added ~/.local/bin to $SHELL_RC. Run 'source $SHELL_RC' or restart terminal.${RESET}"
        fi
    fi
fi

# 4. Build and Install Native GUI (.app)
echo -e "\n${BOLD}[4/5] Building native macOS GUI app...${RESET}"
mkdir -p "$INSTALL_DIR/gui"
swiftc -parse-as-library -O "$INSTALL_DIR/gui/VaporApp.swift" -o "$INSTALL_DIR/gui/Vapor" 2>/dev/null || true

# Assemble .app bundle
APP_DIR="$INSTALL_DIR/Vapor.app"
mkdir -p "$APP_DIR/Contents/MacOS"
mkdir -p "$APP_DIR/Contents/Resources"
cp "$INSTALL_DIR/gui/Vapor" "$APP_DIR/Contents/MacOS/Vapor" 2>/dev/null || true

# Copy into Applications folder
if [ -d "/Applications" ]; then
    echo "[-] Installing Vapor.app to /Applications..."
    rm -rf "/Applications/Vapor.app"
    cp -R "$APP_DIR" "/Applications/Vapor.app"
    echo -e "${GREEN}✓ Vapor.app installed in /Applications!${RESET}"
fi

# 5. Initialize Wine-CX & Apple D3DMetal Engine
echo -e "\n${BOLD}[5/5] Initializing Wine-CX and Apple D3DMetal Engine...${RESET}"
"$INSTALL_DIR/scripts/setup_engine.sh"

echo -e "\n=================================================================="
echo -e "${GREEN}${BOLD}🎉 Vapor successfully installed!${RESET}"
echo "=================================================================="
echo -e "You can now launch Vapor in two ways:\n"
echo -e "  1. ${BOLD}Desktop App:${RESET} Open ${CYAN}Vapor.app${RESET} in Applications or Spotlight (Cmd + Space)"
echo -e "  2. ${BOLD}Terminal:${RESET}    Run ${CYAN}vapor steam${RESET} or ${CYAN}vapor cs2${RESET}"
echo ""
echo -e "To launch Windows Steam now, simply run:"
echo -e "  ${BOLD}${CYAN}vapor steam${RESET}"
echo "=================================================================="
