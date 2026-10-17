# Model-swap page for the DGX Sparks: json-inference's `inference serve-ui`, run
# from the checkout in ~/workspace/json-inference (the CLI already drives the
# Sparks over SSH from here). json-lab publishes it as http://models.json.lab
# (ingress limited to the LAN and WireGuard). Login: basic auth with INFERENCE_UI_USER /
# INFERENCE_UI_PASSWORD from 1Password (vault json-lab, item "env: json-lab .envrc"),
# rendered at start into $XDG_RUNTIME_DIR/inference-ui/ui-auth (0600, tmpfs) with the
# claude-json-lab service-account token in ~/.config/op/json-lab-token.
#
#   systemctl --user restart inference-ui     # after pulling json-inference
#   journalctl --user -u inference-ui -f
{ pkgs, ... }:
let
  renderAuth = pkgs.writeShellScript "inference-ui-auth" ''
    set -euo pipefail
    umask 077
    export OP_SERVICE_ACCOUNT_TOKEN="$(cat "$HOME/.config/op/json-lab-token")"
    d="$XDG_RUNTIME_DIR/inference-ui"; mkdir -p "$d"
    get() { ${pkgs._1password-cli}/bin/op item get "env: json-lab .envrc" --vault json-lab --fields "label=$1" --reveal; }
    { printf 'INFERENCE_UI_USER=%s\n' "$(get INFERENCE_UI_USER)"
      printf 'INFERENCE_UI_PASSWORD=%s\n' "$(get INFERENCE_UI_PASSWORD)"; } > "$d/ui-auth.tmp"
    mv "$d/ui-auth.tmp" "$d/ui-auth"
  '';
in
{
  systemd.user.services.inference-ui = {
    Unit.Description = "json-inference model-swap page (models.json.lab)";
    Service = {
      WorkingDirectory = "%h/workspace/json-inference";
      # Read when each command starts, so ExecStart sees what ExecStartPre rendered.
      EnvironmentFile = "-%t/inference-ui/ui-auth";
      ExecStartPre = "${renderAuth}";
      # ssh for the Sparks, git for the rev the CLI records in results/.
      # The k3s nodes: models.lab.json-lab.online's ingress (Authelia forward-auth) reaches
      # this port from them, so their Remote-User header is trusted; direct LAN access
      # still needs the basic-auth login.
      Environment = [
        "PATH=${pkgs.lib.makeBinPath [ pkgs.python3 pkgs.openssh pkgs.git pkgs.coreutils pkgs.bash ]}"
        "INFERENCE_UI_TRUSTED_PROXIES=192.168.124.10,192.168.124.11,192.168.124.12"
      ];
      ExecStart = "${pkgs.python3}/bin/python3 -m json_inference serve-ui --host 0.0.0.0 --port 8091";
      Restart = "always";
      RestartSec = 5;
    };
    Install.WantedBy = [ "default.target" ];
  };
}
