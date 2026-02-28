#!/usr/bin/env bash
set -euo pipefail

# Bootstrap script for JSON-STATION (WSL on Windows)
# Ensures systemd is enabled, installs Nix, and applies home-manager config.
#
# Usage:
#   git clone <repo> && cd json-workstation && bash hosts/json-station/bootstrap.sh

REPO_URL="https://github.com/jasonwc/json-workstation.git"
SYSTEM_DIR="$HOME/.system"

info()  { printf '\033[1;34m[info]\033[0m  %s\n' "$*"; }
warn()  { printf '\033[1;33m[warn]\033[0m  %s\n' "$*"; }
error() { printf '\033[1;31m[error]\033[0m %s\n' "$*" >&2; exit 1; }

# ---------- WSL systemd ----------

setup_wsl() {
  if [ ! -f /proc/sys/fs/binfmt_misc/WSLInterop ] 2>/dev/null; then
    info "Not running in WSL, skipping WSL-specific setup."
    return
  fi

  # Ensure systemd is enabled (required for Nix daemon)
  if ! systemctl is-system-running &>/dev/null; then
    info "Enabling systemd in WSL..."
    if [ ! -f /etc/wsl.conf ]; then
      sudo tee /etc/wsl.conf > /dev/null <<'WSL'
[boot]
systemd=true
WSL
      warn "systemd enabled — you need to restart WSL: wsl --shutdown (from PowerShell), then reopen."
      warn "Re-run this script after restarting."
      exit 0
    elif ! grep -q 'systemd=true' /etc/wsl.conf; then
      sudo tee -a /etc/wsl.conf > /dev/null <<'WSL'

[boot]
systemd=true
WSL
      warn "systemd enabled — you need to restart WSL: wsl --shutdown (from PowerShell), then reopen."
      warn "Re-run this script after restarting."
      exit 0
    fi
  fi

  info "WSL systemd is running."
}

# ---------- Nix ----------

install_nix() {
  if command -v nix &>/dev/null; then
    info "Nix is already installed, skipping."
    return
  fi

  info "Installing Nix via Determinate installer..."
  curl --proto '=https' --tlsv1.2 -sSf -L \
    https://install.determinate.systems/nix | sh -s -- install

  # Source nix in current shell
  if [ -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]; then
    . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
  fi
}

# ---------- Repo + home-manager ----------

setup_home_manager() {
  if [ ! -d "$SYSTEM_DIR" ]; then
    if [ -f "$(pwd)/flake.nix" ]; then
      info "Symlinking current directory to $SYSTEM_DIR..."
      ln -sf "$(pwd)" "$SYSTEM_DIR"
    else
      info "Cloning repo to $SYSTEM_DIR..."
      git clone "$REPO_URL" "$SYSTEM_DIR"
    fi
  else
    info "$SYSTEM_DIR already exists, skipping clone."
  fi

  info "Running home-manager switch..."
  nix run home-manager -- switch -b backup --flake "$SYSTEM_DIR#JSON-STATION"
}

# ---------- main ----------

main() {
  info "Bootstrapping JSON-STATION (WSL)"
  echo

  setup_wsl
  install_nix
  setup_home_manager

  echo
  info "Bootstrap complete!"
  info "You may want to restart your shell or log out/in for all changes to take effect."
}

main "$@"
