# Model-swap page for the DGX Sparks: json-inference's `inference serve-ui`, run
# from the checkout in ~/workspace/json-inference (the CLI already drives the
# Sparks over SSH from here). json-lab publishes it as http://models.json.lab
# (ingress limited to the LAN and WireGuard). Login: basic auth from
# ~/.config/json-inference/ui-auth (INFERENCE_UI_USER / INFERENCE_UI_PASSWORD,
# mode 600, outside any repo; the password is also in json-lab .envrc).
#
#   systemctl --user restart inference-ui     # after pulling json-inference
#   journalctl --user -u inference-ui -f
{ pkgs, ... }:
{
  systemd.user.services.inference-ui = {
    Unit.Description = "json-inference model-swap page (models.json.lab)";
    Service = {
      WorkingDirectory = "%h/workspace/json-inference";
      EnvironmentFile = "%h/.config/json-inference/ui-auth";
      # ssh for the Sparks, git for the rev the CLI records in results/.
      Environment = [ "PATH=${pkgs.lib.makeBinPath [ pkgs.python3 pkgs.openssh pkgs.git pkgs.coreutils pkgs.bash ]}" ];
      ExecStart = "${pkgs.python3}/bin/python3 -m json_inference serve-ui --host 0.0.0.0 --port 8091";
      Restart = "always";
      RestartSec = 5;
    };
    Install.WantedBy = [ "default.target" ];
  };
}
