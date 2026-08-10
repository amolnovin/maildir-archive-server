#!/usr/bin/env bash
# ============================================================
#  Maildir Archive Server
#  Install Docker Engine inside WSL2 - no Docker Desktop needed
#
#  Run this INSIDE your WSL distribution (Ubuntu/Debian):
#      bash install-docker-wsl.sh
# ============================================================

set -euo pipefail

ok()   { printf '\033[32m[OK]\033[0m    %s\n' "$1"; }
info() { printf '\033[36m[INFO]\033[0m  %s\n' "$1"; }
warn() { printf '\033[33m[WARN]\033[0m  %s\n' "$1"; }
err()  { printf '\033[31m[ERROR]\033[0m %s\n' "$1"; }

echo "=========================================="
echo "  Docker Engine for WSL2 (no Desktop)"
echo "=========================================="
echo

# ---- 0. Sanity checks ----
if ! grep -qiE "(microsoft|wsl)" /proc/version 2>/dev/null; then
    err "This does not look like WSL."
    err "Run this script inside your WSL distro, not on plain Linux/Windows."
    exit 1
fi
ok "Running inside WSL."

if [ "$(id -u)" -eq 0 ]; then
    err "Do not run this as root. Run as your normal user; it will use sudo."
    exit 1
fi

if ! command -v sudo >/dev/null 2>&1; then
    err "sudo is not installed in this distro."
    exit 1
fi

. /etc/os-release 2>/dev/null || true
info "Distribution: ${PRETTY_NAME:-unknown}"

case "${ID:-}" in
    ubuntu|debian) ;;
    *)
        warn "This script is tested on Ubuntu/Debian."
        warn "Detected '${ID:-unknown}'. The official installer may still work."
        read -r -p "Continue anyway? (y/N) " a
        [ "$a" = "y" ] || exit 0
        ;;
esac
echo

# ---- 1. Enable systemd so dockerd starts automatically ----
info "Step 1/5 - enabling systemd in WSL..."
NEED_RESTART=0
if [ -f /etc/wsl.conf ] && grep -q "systemd=true" /etc/wsl.conf; then
    ok "systemd is already enabled in /etc/wsl.conf"
else
    sudo tee -a /etc/wsl.conf >/dev/null <<'EOF'

[boot]
systemd=true
EOF
    ok "Added systemd=true to /etc/wsl.conf"
    NEED_RESTART=1
fi

if [ "$(ps -p 1 -o comm= 2>/dev/null)" != "systemd" ]; then
    NEED_RESTART=1
fi
echo

# ---- 2. Install Docker Engine ----
info "Step 2/5 - installing Docker Engine..."
if command -v docker >/dev/null 2>&1; then
    ok "Docker is already installed: $(docker --version 2>/dev/null || echo unknown)"
else
    info "Downloading the official installer from get.docker.com ..."
    tmp="$(mktemp -d)"
    if ! curl -fsSL https://get.docker.com -o "$tmp/get-docker.sh"; then
        err "Download failed. Check your internet connection or proxy."
        exit 1
    fi
    sudo sh "$tmp/get-docker.sh"
    rm -rf "$tmp"
    ok "Docker Engine installed."
fi
echo

# ---- 3. Compose plugin ----
info "Step 3/5 - checking Docker Compose v2..."
if docker compose version >/dev/null 2>&1; then
    ok "$(docker compose version)"
else
    warn "Compose plugin missing, installing it..."
    sudo apt-get update -qq
    sudo apt-get install -y docker-compose-plugin
    ok "Compose plugin installed."
fi
echo

# ---- 4. Let this user run docker without sudo ----
info "Step 4/5 - adding '$USER' to the docker group..."
if id -nG "$USER" | tr ' ' '\n' | grep -qx docker; then
    ok "Already a member of the docker group."
else
    sudo groupadd -f docker
    sudo usermod -aG docker "$USER"
    ok "Added. This takes effect after WSL restarts."
    NEED_RESTART=1
fi
echo

# ---- 5. Start the daemon ----
info "Step 5/5 - starting the Docker daemon..."
if [ "$(ps -p 1 -o comm= 2>/dev/null)" = "systemd" ]; then
    sudo systemctl enable --now docker >/dev/null 2>&1 || true
    if sudo systemctl is-active --quiet docker; then
        ok "Docker is running under systemd and will start automatically."
    else
        warn "systemd could not start docker yet; a WSL restart is needed."
        NEED_RESTART=1
    fi
else
    sudo service docker start >/dev/null 2>&1 || true
    if sudo service docker status >/dev/null 2>&1; then
        ok "Docker started via service (systemd not active yet)."
    else
        warn "Could not start Docker yet; a WSL restart is needed."
    fi
    NEED_RESTART=1
fi
echo

# nftables/iptables issue seen on Debian in WSL
if command -v update-alternatives >/dev/null 2>&1; then
    if update-alternatives --query iptables >/dev/null 2>&1; then
        if ! sudo iptables -L >/dev/null 2>&1; then
            warn "iptables is not working; switching to iptables-legacy..."
            sudo update-alternatives --set iptables /usr/sbin/iptables-legacy || true
            NEED_RESTART=1
        fi
    fi
fi

echo "=========================================="
if [ "$NEED_RESTART" -eq 1 ]; then
    echo "  ACTION REQUIRED - restart WSL"
    echo "=========================================="
    echo
    echo "  1. Close this window."
    echo "  2. In Windows PowerShell or CMD run:"
    echo "         wsl --shutdown"
    echo "  3. Open your WSL distro again."
    echo "  4. Verify with:"
    echo "         docker run --rm hello-world"
else
    echo "  Done"
    echo "=========================================="
    echo
    echo "  Verify with:"
    echo "         docker run --rm hello-world"
fi
echo
echo "  Then start this project from Windows with:"
echo "         start-wsl.bat"
echo "  or from inside WSL:"
echo "         cd /mnt/d/maildir-archive-server   (your project path)"
echo "         docker compose up -d --build"
echo
