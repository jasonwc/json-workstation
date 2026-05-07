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

    # macOS Tahoe (Darwin 25+) gates systemsetup -{get,set}remotelogin behind
    # Full Disk Access. The nix-darwin activation script doesn't have FDA, so
    # treat this as best-effort: if we can't read or toggle, print a hint and
    # move on rather than failing the whole rebuild.
    echo "[dev-server] Ensuring Remote Login (SSH) is enabled..."
    remote_status=$(/usr/sbin/systemsetup -getremotelogin 2>&1 || true)
    if echo "$remote_status" | /usr/bin/grep -q "On"; then
      :
    elif echo "$remote_status" | /usr/bin/grep -qi "Full Disk Access"; then
      echo "[dev-server] Cannot read Remote Login state without Full Disk Access; enable SSH manually in System Settings → General → Sharing → Remote Login."
    else
      /usr/sbin/systemsetup -setremotelogin on 2>&1 || \
        echo "[dev-server] Could not toggle Remote Login automatically; enable it manually in System Settings → General → Sharing → Remote Login."
    fi

    echo "[dev-server] Reloading sshd to pick up sshd_config.d..."
    /bin/launchctl kickstart -k system/com.openssh.sshd 2>/dev/null || true
  '';
}
