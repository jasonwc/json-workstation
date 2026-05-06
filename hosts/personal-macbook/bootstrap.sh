#!/usr/bin/env bash
set -euo pipefail

# Bootstrap script for JSON-MACBOOK16 (personal Mac + dev SSH server, aarch64-darwin)
# Assumes:
#   - Xcode Command Line Tools are installed
#   - This repo is already cloned somewhere (this script lives inside it)
#
# Usage:
#   cd /path/to/json-workstation && bash hosts/personal-macbook/bootstrap.sh

SYSTEM_DIR="$HOME/.system"
HOSTNAME="JSON-MACBOOK16"

# ---------- helpers ----------

info()  { printf '\033[1;34m[info]\033[0m  %s\n' "$*"; }
warn()  { printf '\033[1;33m[warn]\033[0m  %s\n' "$*"; }
error() { printf '\033[1;31m[error]\033[0m %s\n' "$*" >&2; exit 1; }

need_sudo() {
  if ! sudo -n true 2>/dev/null; then
    info "This script needs sudo for system-level changes."
    sudo -v
  fi
}

# ---------- preflight ----------

check_arch() {
  local arch
  arch=$(uname -m)
  if [ "$arch" != "arm64" ]; then
    error "Expected Apple Silicon (arm64), got: $arch"
  fi
}

check_xcode() {
  if ! xcode-select -p &>/dev/null; then
    error "Xcode Command Line Tools not installed. Run: xcode-select --install"
  fi
  info "Xcode CLT detected at $(xcode-select -p)"
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

  if [ -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]; then
    # shellcheck disable=SC1091
    . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
  fi
}

# ---------- FlakeHub binary cache ----------
# cache.flakehub.com has much better aarch64-darwin coverage than
# cache.nixos.org. The trusted-public-keys ship in Determinate's default
# /etc/nix/nix.conf, so we only need to add it as a substituter.
# Lives in nix.custom.conf because Determinate replaces nix.conf on updates.

setup_flakehub_cache() {
  local conf="/etc/nix/nix.custom.conf"
  if ! sudo test -f "$conf"; then
    info "Creating $conf..."
    sudo install -m 644 /dev/null "$conf"
  fi
  if sudo grep -qE '^extra-substituters[[:space:]]*=.*cache\.flakehub\.com' "$conf"; then
    info "FlakeHub cache already configured in $conf."
  else
    info "Adding FlakeHub cache to $conf..."
    echo "extra-substituters = https://cache.flakehub.com" | sudo tee -a "$conf" > /dev/null
  fi
}

# ---------- Repo symlink ----------

link_repo() {
  local repo_dir
  repo_dir="$(cd "$(dirname "$0")/../.." && pwd)"

  if [ -L "$SYSTEM_DIR" ] && [ "$(readlink "$SYSTEM_DIR")" = "$repo_dir" ]; then
    info "$SYSTEM_DIR already symlinked to $repo_dir."
  elif [ -e "$SYSTEM_DIR" ]; then
    warn "$SYSTEM_DIR exists but isn't a symlink to $repo_dir — leaving it alone."
  else
    info "Symlinking $repo_dir -> $SYSTEM_DIR..."
    ln -s "$repo_dir" "$SYSTEM_DIR"
  fi
}

# ---------- nix-darwin ----------

apply_darwin() {
  if command -v darwin-rebuild &>/dev/null; then
    info "Running darwin-rebuild switch..."
    darwin-rebuild switch --flake "$SYSTEM_DIR#$HOSTNAME"
  else
    info "First run — applying via 'nix run nix-darwin'..."
    sudo nix --extra-substituters https://cache.flakehub.com \
      run nix-darwin -- switch --flake "$SYSTEM_DIR#$HOSTNAME"
  fi
}

# ---------- main ----------

main() {
  info "Bootstrapping $HOSTNAME (personal Mac + dev SSH server)"
  echo

  check_arch
  check_xcode
  need_sudo
  install_nix
  setup_flakehub_cache
  link_repo
  apply_darwin

  echo
  info "Bootstrap complete!"
  info "Verify SSH: 'ssh jasonwc@$(hostname).local' from another machine."
  info "Future updates: run 'update' (aliased to darwin-rebuild switch)."
}

main "$@"
