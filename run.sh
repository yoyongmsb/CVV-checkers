#!/bin/bash

# ==========================================================
# Universal Installer: Termux / Linux / macOS
# Author : Kian Santang
# GitHub : https://github.com/KianSantang777/CVV-Checkers
# ==========================================================

set -e

# -------------- COLOR CODES --------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# -------------- LOGGING FUNCTIONS --------------
log_info() {
    echo -e "${YELLOW}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[OK]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

# -------------- SPINNER FUNCTION --------------
spinner() {
    local pid=$!
    local delay=0.1
    local spinstr='|/-\'
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    wait $pid
    return $?
}

# -------------- PLATFORM DETECTION --------------
PLATFORM=""
SUDO=""
PYTHON_CMD=""

if [ -d "/data/data/com.termux" ]; then
    PLATFORM="termux"
    SUDO=""
    log_info "Detected environment: Termux (Android)"
elif [[ "$OSTYPE" == "darwin"* ]]; then
    PLATFORM="macos"
    SUDO=""
    log_info "Detected environment: macOS"
else
    PLATFORM="linux"
    SUDO="sudo"
    log_info "Detected environment: Linux"
fi

# -------------- UPDATE SYSTEM --------------
log_info "Updating system..."
(
    if [ "$PLATFORM" = "termux" ]; then
        pkg update -y && pkg upgrade -y
    elif [ "$PLATFORM" = "linux" ]; then
        $SUDO apt update -y && $SUDO apt upgrade -y
    fi
) & spinner
log_success "System updated."

# -------------- STORAGE PERMISSION FOR TERMUX --------------
if [ "$PLATFORM" = "termux" ]; then
    log_info "Requesting Termux storage permission..."
    termux-setup-storage || log_error "Failed to request storage permission."
    log_success "Storage permission granted."
fi

# -------------- INSTALL REQUIRED PACKAGES --------------
log_info "Installing required packages..."
(
    if [ "$PLATFORM" = "termux" ]; then
        pkg install -y python git nano
    elif [ "$PLATFORM" = "linux" ]; then
        $SUDO apt install -y python3 python3-pip git nano software-properties-common
    elif [ "$PLATFORM" = "macos" ]; then
        if ! command -v brew >/dev/null 2>&1; then
            log_error "Homebrew not found. Please install Homebrew from https://brew.sh"
        fi
        brew install python git nano
    fi
) & spinner
log_success "Packages installed."

# -------------- PYTHON VERSION CHECK --------------
log_info "Detecting Python interpreter..."
PYTHON_CMD=$(command -v python3.12 || command -v python3 || true)

if [ -z "$PYTHON_CMD" ]; then
    if [ "$PLATFORM" = "linux" ]; then
        log_info "Installing Python 3.12..."
        (
            $SUDO add-apt-repository -y ppa:deadsnakes/ppa
            $SUDO apt update -y
            $SUDO apt install -y python3.12 python3.12-venv python3.12-distutils
        ) & spinner
        PYTHON_CMD=$(command -v python3.12)
    else
        log_error "No compatible Python found. Please install Python manually."
    fi
fi

log_success "Using Python: $($PYTHON_CMD -V 2>&1)"

# -------------- VALIDATE PROJECT DIRECTORY --------------
PROJECT_DIR="$HOME/CVV-Checkers"
if [ ! -d "$PROJECT_DIR" ]; then
    log_error "Project directory not found: $PROJECT_DIR"
fi
cd "$PROJECT_DIR"

# -------------- INSTALL PYTHON DEPENDENCIES --------------
if [ ! -f "requirements.txt" ]; then
    log_error "requirements.txt not found in $PROJECT_DIR"
fi

log_info "Installing Python dependencies..."
(
    $PYTHON_CMD -m pip install --upgrade pip
    $PYTHON_CMD -m pip install -r requirements.txt
) & spinner
log_success "Dependencies installed."

# -------------- SET PERMISSIONS --------------
log_info "Setting directory permissions..."
chmod -R 755 "$PROJECT_DIR"
log_success "Permissions set."

# -------------- RUN APPLICATION IN LOOP --------------
log_info "Launching auth.py (auto-restart enabled)"
while true; do
    $PYTHON_CMD "$PROJECT_DIR/auth.py"
    log_info "auth.py stopped. Restarting in 5 seconds..."
    sleep 5
done
