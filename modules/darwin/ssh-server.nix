{ ... }:

{
  # SSH access for nix-darwin hosts: enable Remote Login (sshd), harden the
  # daemon, and reload it on activation. Pulls in no power-management policy —
  # hosts that also want server-style "never sleep" behavior layer
  # modules/darwin/dev-server.nix on top, which imports this module.
  #
  # Authorized keys are installed separately at the home-manager layer via
  # modules/home/authorized-keys.nix; import both to make a host ssh'able.

  environment.etc."ssh/sshd_config.d/99-ssh-hardening.conf".text = ''
    # Managed by nix-darwin (modules/darwin/ssh-server.nix)
    PasswordAuthentication no
    PermitRootLogin no
    PubkeyAuthentication yes
    X11Forwarding no
    MaxAuthTries 3
    ClientAliveInterval 60
    ClientAliveCountMax 3
  '';

  system.activationScripts.postActivation.text = ''
    # macOS Tahoe (Darwin 25+) gates systemsetup -{get,set}remotelogin behind
    # Full Disk Access. The nix-darwin activation script doesn't have FDA, so
    # treat this as best-effort: if we can't read or toggle, print a hint and
    # move on rather than failing the whole rebuild.
    echo "[ssh-server] Ensuring Remote Login (SSH) is enabled..."
    remote_status=$(/usr/sbin/systemsetup -getremotelogin 2>&1 || true)
    if echo "$remote_status" | /usr/bin/grep -q "On"; then
      :
    elif echo "$remote_status" | /usr/bin/grep -qi "Full Disk Access"; then
      echo "[ssh-server] Cannot read Remote Login state without Full Disk Access; enable SSH manually in System Settings → General → Sharing → Remote Login."
    else
      /usr/sbin/systemsetup -setremotelogin on 2>&1 || \
        echo "[ssh-server] Could not toggle Remote Login automatically; enable it manually in System Settings → General → Sharing → Remote Login."
    fi

    echo "[ssh-server] Reloading sshd to pick up sshd_config.d..."
    /bin/launchctl kickstart -k system/com.openssh.sshd 2>/dev/null || true
  '';
}
