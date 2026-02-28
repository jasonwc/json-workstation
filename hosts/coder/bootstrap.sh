#!/usr/bin/env bash
set -euo pipefail

# Bootstrap script for Coder workspaces
# Cleans up pre-installed direnv/cachix, installs home-manager config, sets shell to zsh.
#
# Usage:
#   cd ~/.system && bash hosts/coder/bootstrap.sh

SYSTEM_DIR="$HOME/.system"

info()  { printf '\033[1;34m[info]\033[0m  %s\n' "$*"; }

# Remove pre-installed nix profile packages that conflict with home-manager
info "Removing conflicting nix profile packages..."
nix profile remove direnv 2>/dev/null || true
nix profile remove cachix 2>/dev/null || true

info "Running home-manager switch..."
nix run home-manager -- switch -b backup --flake "$SYSTEM_DIR#coder"

info "Setting default shell to zsh..."
sudo chsh -s /home/coder/.nix-profile/bin/zsh coder

info "Bootstrap complete! Restart your shell or log out/in."
