#!/bin/bash
# ==========================================================
# CVV-Checkers Universal Installer (Termux / Linux / Ubuntu)
# Author: Kian Santang
# GitHub: https://github.com/KianSantang777/CVV-Checkers
# ==========================================================

set -e

clear
echo ""
echo "=========================================="
echo "       CVV-Checkers Auto Installer"
echo "=========================================="
echo ""

# Detect platform
if [ -d "/data/data/com.termux" ]; then
    PLATFORM="termux"
    SUDO=""
    echo "Detected environment: Termux (Android)"
else
    PLATFORM="linux"
    SUDO="sudo"
    echo "Detected environment: Linux / Ubuntu"
fi

# Step 1: Update & Upgrade
echo "[1/8] Updating and upgrading system..."
if [ "$PLATFORM" = "termux" ]; then
    pkg update -y && pkg upgrade -y
else
    $SUDO apt update -y && $SUDO apt upgrade -y
fi

# Step 2: Request storage permission (Termux only)
if [ "$PLATFORM" = "termux" ]; then
    echo "[2/8] Requesting storage permission..."
    termux-setup-storage
fi

# Step 3: Install essential packages
echo "[3/8] Installing required packages..."
if [ "$PLATFORM" = "termux" ]; then
    pkg install python git nano -y
else
    $SUDO apt install -y python3 python3-pip git nano software-properties-common
fi

# Step 4: Ensure Python 3.12.x (Linux only)
echo "[4/8] Checking Python version..."
PY_VER=$(python3 -V 2>&1)

if echo "$PY_VER" | grep -q "3.12"; then
    echo "Python version OK: $PY_VER"
else
    echo "Python 3.12.x not found."
    if [ "$PLATFORM" = "linux" ]; then
        echo "Installing Python 3.12..."
        $SUDO add-apt-repository -y ppa:deadsnakes/ppa
        $SUDO apt update -y
        $SUDO apt install -y python3.12 python3.12-venv python3.12-distutils
    else
        echo "Warning: Termux uses default Python version."
    fi
fi

# Pick python executable
if command -v python3.12 >/dev/null 2>&1; then
    PY="python3.12"
else
    PY="python3"
fi

# Step 5: Navigate to project directory
if [ -d "$HOME/CVV-checkers" ]; then
    cd "$HOME/CVV-checkers"
else
    echo "Error: CVV-Checkers directory not found in HOME."
    echo "Place this script inside or above the CVV-Checkers folder."
    exit 1
fi

# Step 6: Install Python requirements
echo "[6/8] Installing Python dependencies from stuff/requirements.txt..."
if [ -f "stuff/requirements.txt" ]; then
    $PY -m pip install --upgrade pip
    $PY -m pip install -r requirements.txt
else
    echo "Error: requirements.txt not found!"
    exit 1
fi

# Step 7: Fix permissions
echo "[7/8] Setting directory permissions..."
chmod -R 755 "$HOME/CVV-checkers"

# Step 8: Run main script with auto-restart
echo "[8/8] Launching CVV-checkers..."
echo ""
echo "=========================================="
echo "   Starting auth.py (auto-restart)"
echo "   Press CTRL + C to stop manually."
echo "=========================================="
echo ""

while true; do
    $PY "$HOME/CVV-checkers/auth.py"
    echo ""
    echo ">>> auth.py stopped. Restarting in 5 seconds..."
    sleep 5
done
