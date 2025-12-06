#!/bin/bash
set -e

REQUIRED_PY_VERSION="3.12"
MAIN_SCRIPT="auth.py"

PACKAGES=(
  requests termcolor bs4 aiofiles distro websocket-client
  aiohttp asyncio faker colorama pyfiglet pycryptodome
  psutil urllib3 python-socketio tqdm
  requests[socks] httpx[http2]
)


PYTHON_BIN=$(command -v python3.12 || command -v python3 || command -v python)
[ -z "$PYTHON_BIN" ] && echo "Python not found" && exit 1

PY_VERSION=$($PYTHON_BIN - <<'PY'
import sys
print(f"{sys.version_info.major}.{sys.version_info.minor}")
PY
)

awk "BEGIN{exit !($PY_VERSION >= $REQUIRED_PY_VERSION)}" \
  || echo "Warning: Python $REQUIRED_PY_VERSION+ recommended"


$PYTHON_BIN -m ensurepip --upgrade >/dev/null 2>&1 || true
$PYTHON_BIN -m pip install --upgrade -q pip


$PYTHON_BIN -m pip install -q tqdm


clear
printf "%s\n" \
"=============================================" \
" Python Dependency Installer " \
"============================================="


TMP_SCRIPT=$(mktemp)

cat > "$TMP_SCRIPT" <<EOF
from tqdm import tqdm
import subprocess, sys

packages = """$(printf "%s\n" "${PACKAGES[@]}")""".splitlines()

for pkg in tqdm(packages, desc="Installing packages", ncols=72):
    subprocess.run(
        [sys.executable, "-m", "pip", "install", "--upgrade", "-q", pkg],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL
    )
EOF

$PYTHON_BIN "$TMP_SCRIPT"
rm -f "$TMP_SCRIPT"


INSTALL_DIR="$(pwd)"
CMD_NAME="run"

if command -v pkg >/dev/null 2>&1; then
  BIN_DIR="$PREFIX/bin"
else
  BIN_DIR="/usr/local/bin"
fi

[ ! -w "$BIN_DIR" ] && SUDO="sudo" || SUDO=""

$SUDO tee "$BIN_DIR/$CMD_NAME" >/dev/null <<EOF
#!/bin/bash
cd "$INSTALL_DIR" || exit 1
exec $PYTHON_BIN "$MAIN_SCRIPT" "\$@"
EOF

$SUDO chmod +x "$BIN_DIR/$CMD_NAME"


clear
printf "%s\n" \
"=============================================" \
" Installation complete" \
" Command available: run" \
"============================================="

[ -f "$MAIN_SCRIPT" ] && exec $PYTHON_BIN "$MAIN_SCRIPT"
