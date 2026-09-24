{ pkgs, ... }:

# Prometheus exporters scraped by json-lab's Prometheus (jobs `json-mini` on
# :9100 and `json-mini-gpu` on :9101). They run as systemd user services, so
# bootstrap.sh enables lingering to start them at boot without a login.
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
}
