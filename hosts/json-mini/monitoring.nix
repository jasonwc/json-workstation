{ pkgs, ... }:

# Monitoring endpoints json-lab reads: Prometheus exporters (jobs `json-mini`
# on :9100 and `json-mini-gpu` on :9101) and Glances (:61208) for Homepage.
# They run as systemd user services, so bootstrap.sh enables lingering to start
# them at boot without a login.
{
  systemd.user.services.node-exporter = {
    Unit.Description = "Prometheus node exporter";
    Service = {
      ExecStart = "${pkgs.prometheus-node-exporter}/bin/node_exporter --web.listen-address=:9100";
      Restart = "always";
      RestartSec = 5;
    };
    Install.WantedBy = [ "default.target" ];
  };

  systemd.user.services.amdgpu-exporter = {
    Unit.Description = "Prometheus exporter for the Radeon 890M iGPU";
    Service = {
      ExecStart = "${pkgs.python3}/bin/python3 ${./amdgpu_exporter.py}";
      Environment = [ "PORT=9101" ];
      Restart = "always";
      RestartSec = 5;
    };
    Install.WantedBy = [ "default.target" ];
  };

  # Glances REST API (no web UI) for json-lab's Homepage: CPU/memory in the
  # top bar, the Radeon 890M on its tile. Homepage widgets can't read Prometheus.
  systemd.user.services.glances = {
    Unit.Description = "Glances REST API for Homepage";
    Service = {
      ExecStart = "${pkgs.glances}/bin/glances -w --disable-webui --bind 0.0.0.0 --port 61208";
      Restart = "always";
      RestartSec = 5;
    };
    Install.WantedBy = [ "default.target" ];
  };
}
