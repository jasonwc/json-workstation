{ pkgs, ... }:

let
  # Polls the current power source every 10s and appends a line to
  # /var/log/dev-server-power.log only when it changes. Lets us catch
  # brief AC drops (loose cable, flaky brick) that pmset's main log
  # buries inside thousands of unrelated assertions.
  powerWatchScript = pkgs.writeShellScript "dev-server-power-watch" ''
    set -eu
    LOG=/var/log/dev-server-power.log
    STATE=/var/run/dev-server-power.state
    current=$(/usr/bin/pmset -g batt | /usr/bin/head -1 | /usr/bin/awk -F\' '{print $2}')
    last=""
    if [ -r "$STATE" ]; then
      last=$(cat "$STATE")
    fi
    if [ "$current" != "$last" ]; then
      printf '%s source=%s\n' "$(/bin/date -u +%Y-%m-%dT%H:%M:%SZ)" "$current" >> "$LOG"
      printf '%s' "$current" > "$STATE"
    fi
  '';
in
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
    echo "[dev-server] Applying power management (server-style, AC + battery)..."
    # AC profile: behave like a server — never sleep, keep network alive,
    # never hibernate or enter standby/autopoweroff (deep-sleep modes that
    # tear down the network stack and disrupt SSH).
    /usr/bin/pmset -c \
      sleep 0 \
      displaysleep 30 \
      disksleep 0 \
      womp 1 \
      autorestart 1 \
      powernap 1 \
      tcpkeepalive 1 \
      hibernatemode 0 \
      standby 0 \
      autopoweroff 0
    # Battery profile: if AC briefly drops (loose plug, blip), don't fall
    # off the network. Display can still sleep to save power.
    /usr/bin/pmset -b \
      sleep 0 \
      displaysleep 10 \
      disksleep 0 \
      tcpkeepalive 1 \
      hibernatemode 0 \
      standby 0 \
      autopoweroff 0

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

    echo "[dev-server] Ensuring power watchdog log exists..."
    /usr/bin/touch /var/log/dev-server-power.log
    /bin/chmod 644 /var/log/dev-server-power.log
  '';

  launchd.daemons.dev-server-power-watch = {
    serviceConfig = {
      Label = "com.user.dev-server-power-watch";
      ProgramArguments = [ "${powerWatchScript}" ];
      StartInterval = 10;
      RunAtLoad = true;
      StandardErrorPath = "/var/log/dev-server-power-watch.err.log";
    };
  };
}
