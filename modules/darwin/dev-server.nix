{ ... }:

{
  # Dev-server tweaks for JSON-MACBOOK16: enable SSH, prevent sleep on AC,
  # harden sshd. Imported only from hosts/personal-macbook/default.nix —
  # JSON-PAPERBOOK does not get this treatment.

  environment.etc."ssh/sshd_config.d/99-dev-server.conf".text = ''
    # Managed by nix-darwin (modules/darwin/dev-server.nix)
    PasswordAuthentication no
    PermitRootLogin no
    PubkeyAuthentication yes
    X11Forwarding no
    MaxAuthTries 3
    ClientAliveInterval 60
    ClientAliveCountMax 3
  '';

  system.activationScripts.postActivation.text = ''
    echo "[dev-server] Applying power management (no sleep on AC)..."
    /usr/bin/pmset -c sleep 0 displaysleep 30 disksleep 0 womp 1 autorestart 1

    echo "[dev-server] Ensuring Remote Login (SSH) is enabled..."
    if ! /usr/sbin/systemsetup -getremotelogin 2>/dev/null | /usr/bin/grep -q "On"; then
      /usr/sbin/systemsetup -setremotelogin -f on
    fi

    echo "[dev-server] Reloading sshd to pick up sshd_config.d..."
    /bin/launchctl kickstart -k system/com.openssh.sshd 2>/dev/null || true
  '';
}
