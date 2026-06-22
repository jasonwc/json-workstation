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
  # Dev-server tweaks for JSON-MACBOOK16: server-style power management (never
  # sleep on AC, survive brief power loss) plus a power-loss watchdog. SSH
  # itself is provided by modules/darwin/ssh-server.nix, imported here.
  # Imported only from hosts/personal-macbook/default.nix — other hosts that
  # want plain SSH import ssh-server.nix directly instead.
  imports = [ ./ssh-server.nix ];

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
