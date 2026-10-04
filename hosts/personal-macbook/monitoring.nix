{ pkgs, ... }:

# Monitoring endpoints json-lab reads: Prometheus exporters (jobs
# `json-macbook16` on :9100 and `json-macbook16-gpu` on :9101) and Glances
# (:61208) for Homepage. Same ports as json-mini.
#
# They are launchd daemons (not user agents) running as jasonwc, so they start
# at boot even when nobody is logged in to the GUI, like json-mini's lingering
# systemd user services.
let
  user = "jasonwc";

  # The binaries that accept the LAN connections. The macOS application
  # firewall blocks unsigned (ad-hoc signed Nix) binaries by default, so each
  # one is allowed explicitly on activation. Glances is a Python script, so the
  # listening process is its interpreter.
  listeners = [
    "${pkgs.prometheus-node-exporter}/bin/node_exporter"
    "${pkgs.macmon}/bin/macmon"
    pkgs.python3.interpreter
  ];

  daemon = label: args: {
    serviceConfig = {
      Label = "com.user.${label}";
      ProgramArguments = args;
      UserName = user;
      RunAtLoad = true;
      KeepAlive = true;
      ThrottleInterval = 5;
      EnvironmentVariables.HOME = "/Users/${user}";
      StandardErrorPath = "/tmp/${label}.err.log";
    };
  };
in
{
  launchd.daemons.node-exporter = daemon "node-exporter" [
    "${pkgs.prometheus-node-exporter}/bin/node_exporter"
    "--web.listen-address=:9100"
  ];

  # Apple-silicon SoC metrics (CPU/GPU/ANE power, temperatures, frequencies,
  # RAM) via IOReport, no sudo or powermetrics needed. Prometheus format on
  # /metrics.
  launchd.daemons.macmon = daemon "macmon" [
    "${pkgs.macmon}/bin/macmon"
    "serve"
    "--port"
    "9101"
  ];

  # Glances REST API (no web UI) for json-lab's Homepage tile. Homepage
  # widgets can't read Prometheus.
  launchd.daemons.glances = daemon "glances" [
    "${pkgs.glances}/bin/glances"
    "-w"
    "--disable-webui"
    "--bind"
    "0.0.0.0"
    "--port"
    "61208"
  ];

  system.activationScripts.postActivation.text = ''
    echo "[monitoring] Allowing exporters through the application firewall..."
    for bin in ${toString listeners}; do
      /usr/libexec/ApplicationFirewall/socketfilterfw --add "$bin" >/dev/null
      /usr/libexec/ApplicationFirewall/socketfilterfw --unblockapp "$bin" >/dev/null
    done
  '';
}
