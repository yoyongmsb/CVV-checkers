#!/bin/bash
# ==========================================================
# BraintreeCHK Universal Installer (Termux / Linux / Ubuntu)
# Author: Kian Santang
# GitHub: https://github.com/KianSantang777/CVV-Checkers
# ==========================================================

set -e

clear
echo ""
echo "=========================================="
echo "       Stripe Auth Auto Installer"
echo "=========================================="
echo ""

if [ -d "/data/data/com.termux" ]; then
    PLATFORM="termux"
    SUDO=""
    echo "Detected environment: Termux (Android)"
else
    PLATFORM="linux"
    SUDO="sudo"
    echo "Detected environment: Linux / Ubuntu"
fi

echo "[1/8] Updating and upgrading system..."
if [ "$PLATFORM" = "termux" ]; then
    pkg update -y && pkg upgrade -y
else
    $SUDO apt update -y && $SUDO apt upgrade -y
fi

if [ "$PLATFORM" = "termux" ]; then
    echo "[2/8] Requesting storage permission..."
    termux-setup-storage
fi


echo "[3/8] Installing required packages..."
if [ "$PLATFORM" = "termux" ]; then
    pkg install python git nano -y
else
    $SUDO apt install -y python3 python3-pip git nano software-properties-common
fi


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


if command -v python3.12 >/dev/null 2>&1; then
    PY="python3.12"
else
    PY="python3"
fi


if [ -d "$HOME/CVV-Checkers" ]; then
    cd "$HOME/CVV-Checkers"
else
    echo "Error: CVV-Checkers directory not found in HOME."
    echo "Place this script inside or above the CVV-Checkers folder."
    exit 1
fi


echo "[6/8] Installing Python dependencies from requirements.txt..."
if [ -f "requirements.txt" ]; then
    $PY -m pip install --upgrade pip
    $PY -m pip install -r requirements.txt
else
    echo "Error: requirements.txt not found!"
    exit 1
fi


echo "[7/8] Setting directory permissions..."
chmod -R 755 "$HOME/CVV-Checkers"


echo "[8/8] Launching CVV-Checkers..."
echo ""
echo "=========================================="
echo "   Starting auth.py (auto-restart)"
echo "   Press CTRL + C to stop manually."
echo "=========================================="
echo ""

while true; do
    $PY "$HOME/CVV-Checkers/auth.py"
    echo ""
    echo ">>> auth.py stopped. Restarting in 5 seconds..."
    sleep 5
done
