#!/usr/bin/env bash
set -euo pipefail

# Bootstrap script for JSON-MINI (Pop!_OS workstation)
# Sets up SSH server, installs Nix, and applies home-manager config.
#
# Usage:
#   curl -fsSL <raw-github-url> | bash
#   — or —
#   git clone <repo> && cd json-workstation && bash hosts/json-mini/bootstrap.sh

REPO_URL="https://github.com/jasonwc/json-workstation.git"
SYSTEM_DIR="$HOME/.system"

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

# ---------- SSH server ----------

setup_ssh() {
  info "Installing OpenSSH server..."
  sudo apt-get update -qq
  sudo apt-get install -y -qq openssh-server

  info "Configuring sshd..."
  sudo tee /etc/ssh/sshd_config.d/99-json-mini.conf > /dev/null <<'SSHD'
# JSON-MINI hardened SSH config
PasswordAuthentication no
PermitRootLogin no
PubkeyAuthentication yes
AuthorizedKeysFile .ssh/authorized_keys
X11Forwarding no
MaxAuthTries 3
ClientAliveInterval 60
ClientAliveCountMax 3
SSHD

  # Ensure the user has an authorized_keys file
  mkdir -p "$HOME/.ssh"
  chmod 700 "$HOME/.ssh"
  touch "$HOME/.ssh/authorized_keys"
  chmod 600 "$HOME/.ssh/authorized_keys"

  info "Fetching public keys from GitHub (jasonwc)..."
  local gh_keys
  gh_keys=$(curl -fsSL https://github.com/jasonwc.keys)
  if [ -n "$gh_keys" ]; then
    while IFS= read -r key; do
      if ! grep -qF "$key" "$HOME/.ssh/authorized_keys"; then
        echo "$key" >> "$HOME/.ssh/authorized_keys"
      fi
    done <<< "$gh_keys"
    info "GitHub public keys added to authorized_keys."
  else
    warn "Could not fetch keys from GitHub — add your public key manually!"
  fi

  info "Enabling and starting sshd..."
  sudo systemctl enable ssh
  sudo systemctl restart ssh
}

# ---------- Disable sleep ----------

disable_sleep() {
  info "Disabling all sleep/suspend/hibernate targets..."
  sudo systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target

  info "Configuring GNOME/Pop to never blank screen or suspend..."
  # These work whether or not a graphical session is active
  gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type 'nothing' 2>/dev/null || true
  gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-battery-type 'nothing' 2>/dev/null || true
  gsettings set org.gnome.desktop.session idle-delay 0 2>/dev/null || true
  gsettings set org.gnome.desktop.screensaver lock-enabled false 2>/dev/null || true

  info "Sleep and screen blanking disabled — machine will stay on indefinitely."
}

# ---------- Flatpak ----------

setup_flatpak() {
  if command -v flatpak &>/dev/null; then
    info "Flatpak is already installed."
  else
    info "Installing Flatpak..."
    sudo apt-get install -y -qq flatpak
  fi

  if ! flatpak remote-list | grep -q flathub; then
    info "Adding Flathub remote..."
    flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
  fi
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
    if [ -d "$(pwd)/flake.nix" ] || [ -f "$(pwd)/flake.nix" ]; then
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
  nix run home-manager -- switch -b backup --flake "$SYSTEM_DIR#JSON-MINI"

  # Set zsh as default shell
  local zsh_path
  zsh_path="$(command -v zsh 2>/dev/null || echo "")"
  if [ -n "$zsh_path" ]; then
    if [ "$SHELL" != "$zsh_path" ]; then
      info "Changing default shell to zsh..."
      if ! grep -qF "$zsh_path" /etc/shells; then
        echo "$zsh_path" | sudo tee -a /etc/shells > /dev/null
      fi
      sudo chsh -s "$zsh_path" "$USER"
    else
      info "Default shell is already zsh."
    fi
  else
    warn "zsh not found — skipping shell change."
  fi
}

# ---------- main ----------

main() {
  info "Bootstrapping JSON-MINI (Pop!_OS)"
  echo

  need_sudo
  setup_ssh
  disable_sleep
  setup_flatpak
  install_nix
  setup_home_manager

  echo
  info "Bootstrap complete!"
  info "Log out and back in (or reboot) for the zsh default shell to take effect."
}

main "$@"
