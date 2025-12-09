#!/usr/bin/env bash

# ==========================================================
# Universal Runner / Installer
# Clean • Modern • Realtime • Termux-safe
# Repo : https://github.com/KianSantang777/CVV-Checkers
# ==========================================================

set -e

# ---------------- UI COLORS ----------------
CLR_RESET='\033[0m'
CLR_DIM='\033[2m'
CLR_OK='\033[0;32m'
CLR_ERR='\033[0;31m'

# ---------------- UI FUNCTIONS ----------------
step() { printf "${CLR_DIM}• %s${CLR_RESET}\n" "$1"; }
ok()   { printf "${CLR_OK}✓ %s${CLR_RESET}\n" "$1"; }
fail() { printf "${CLR_ERR}✗ %s${CLR_RESET}\n" "$1"; exit 1; }

run() {
    local msg="$1"; shift
    printf "${CLR_DIM}• %s${CLR_RESET} " "$msg"

    "$@" >/dev/null 2>&1 &
    local pid=$!

    local spin='|/-\'
    local i=0
    while kill -0 "$pid" 2>/dev/null; do
        printf "\r${CLR_DIM}• %s %c${CLR_RESET}" "$msg" "${spin:i++%4:1}"
        sleep 0.1
    done

    wait "$pid"
    if [ $? -eq 0 ]; then
        printf "\r${CLR_OK}✓ %s${CLR_RESET}\n" "$msg"
    else
        printf "\r${CLR_ERR}✗ %s${CLR_RESET}\n" "$msg"
        exit 1
    fi
}

# ---------------- PLATFORM ----------------
PLATFORM="linux"
SUDO="sudo"

if [ -d "/data/data/com.termux" ]; then
    PLATFORM="termux"
    SUDO=""
    step "Environment: Termux"
elif [[ "$OSTYPE" == "darwin"* ]]; then
    PLATFORM="macos"
    SUDO=""
    step "Environment: macOS"
else
    step "Environment: Linux"
fi

# ---------------- UPDATE ----------------
if [ "$PLATFORM" = "termux" ]; then
    run "Updating system" pkg update -y
elif [ "$PLATFORM" = "linux" ]; then
    run "Updating system" $SUDO apt update -y
fi

# ---------------- TERMUX STORAGE ----------------
[ "$PLATFORM" = "termux" ] && run "Enabling storage access" termux-setup-storage

# ---------------- BASE PACKAGES ----------------
if [ "$PLATFORM" = "termux" ]; then
    run "Installing base tools" \
        pkg install -y python clang libffi openssl nano curl wget unzip git
elif [ "$PLATFORM" = "linux" ]; then
    run "Installing base tools" \
        $SUDO apt install -y python3 python3-pip nano curl wget unzip git
elif [ "$PLATFORM" = "macos" ]; then
    command -v brew >/dev/null || fail "Homebrew not installed"
    run "Installing base tools" \
        brew install python nano curl wget unzip git
fi

# ---------------- PYTHON (TERMUX-SAFE) ----------------
if [ "$PLATFORM" = "termux" ]; then
    PYTHON=$(command -v python3.11 || command -v python3)
else
    PYTHON=$(command -v python3)
fi

[ -z "$PYTHON" ] && fail "Python not found"
ok "Using $($PYTHON --version 2>&1)"

# ---------------- PROJECT ----------------
PROJECT_DIR="$HOME/CVV-Checkers"
REPO_URL="https://github.com/KianSantang777/CVV-Checkers"
ZIP_URL="$REPO_URL/archive/refs/heads/main.zip"
TMP_ZIP="$HOME/.cvv_checkers.zip"

if [ ! -d "$PROJECT_DIR" ]; then
    step "Project not found"

    if command -v git >/dev/null; then
        run "Cloning repository" git clone "$REPO_URL" "$PROJECT_DIR"
    else
        step "Git unavailable, using zip"

        if command -v curl >/dev/null; then
            run "Downloading source" curl -L "$ZIP_URL" -o "$TMP_ZIP"
        elif command -v wget >/dev/null; then
            run "Downloading source" wget "$ZIP_URL" -O "$TMP_ZIP"
        else
            fail "curl / wget required"
        fi

        run "Extracting source" unzip -q "$TMP_ZIP" -d "$HOME"
        mv "$HOME/CVV-Checkers-main" "$PROJECT_DIR" || fail "Move failed"
        rm -f "$TMP_ZIP"
    fi

    ok "Project ready"
else
    ok "Project directory exists"
fi

cd "$PROJECT_DIR" || fail "Cannot enter project directory"

# ---------------- PYTHON DEPS ----------------
[ ! -f requirements.txt ] && fail "requirements.txt missing"

run "Upgrading pip" $PYTHON -m pip install -U pip setuptools wheel
run "Installing dependencies" $PYTHON -m pip install -r requirements.txt

# ---------------- PERMISSIONS ----------------
chmod -R 755 "$PROJECT_DIR"
ok "Permissions set"

# ---------------- RUN ----------------
printf "\n${CLR_DIM}→ Launching auth.py (auto-restart enabled)${CLR_RESET}\n"

while true; do
    $PYTHON auth.py
    printf "${CLR_DIM}→ auth.py stopped, restarting in 5s${CLR_RESET}\n"
    sleep 5
done
