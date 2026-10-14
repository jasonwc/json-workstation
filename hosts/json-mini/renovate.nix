# Self-hosted Renovate: weekly dependency-update PRs for the homelab repos, run from
# json-mini instead of the Renovate GitHub app. PRs are opened as the account `gh` is
# logged in as; the token comes from `gh auth token` at run time (the gh login lives in
# the desktop keyring), so it is never written to disk, the Nix store or a repo.
#
# Repos with their own renovate.json (json-lab) use it; the others run without an
# onboarding PR, with the defaults below (requireConfig = optional). Nothing automerges.
#
#   systemctl --user start renovate      # run now
#   journalctl --user -u renovate -f     # watch a run
{ pkgs, ... }:
let
  config = pkgs.writeText "renovate-config.json" (builtins.toJSON {
    platform = "github";
    autodiscover = false;
    repositories = [
      "jasonwc/json-lab"
      "jasonwc/json-agents"
      "jasonwc/json-inference"
      "jasonwc/json-workstation"
    ];
    onboarding = false;
    requireConfig = "optional";
    gitAuthor = "Renovate Bot <bot@renovateapp.com>";

    # Defaults for repos without a renovate.json (json-lab's own file overrides these).
    extends = [ "config:recommended" ];
    timezone = "America/Los_Angeles";
    schedule = [ "after 2am and before 6am" ];
    prConcurrentLimit = 5;
    labels = [ "dependencies" ];
    nix.enabled = true;
    lockFileMaintenance = {
      enabled = true;
      schedule = [ "before 6am on sunday" ];
    };
  });

  run = pkgs.writeShellScript "renovate-run" ''
    set -euo pipefail
    RENOVATE_TOKEN="$(gh auth token)" || { echo "gh auth token failed: is the keyring unlocked (log in to json-mini once after a reboot)?" >&2; exit 1; }
    export RENOVATE_TOKEN GITHUB_COM_TOKEN="$RENOVATE_TOKEN"
    exec renovate "$@"
  '';
in
{
  systemd.user.services.renovate = {
    Unit.Description = "Renovate dependency updates for the homelab repos";
    Service = {
      Type = "oneshot";
      ExecStart = "${run}";
      Environment = [
        "RENOVATE_CONFIG_FILE=${config}"
        "RENOVATE_BASE_DIR=%h/.cache/renovate"
        "LOG_LEVEL=info"
        # git and nix for cloning and flake.lock updates, npm for package-lock.json
        # maintenance (json-agents), gh for the token.
        "PATH=${pkgs.lib.makeBinPath [ pkgs.renovate pkgs.gh pkgs.git pkgs.nodejs pkgs.coreutils ]}:/nix/var/nix/profiles/default/bin"
      ];
      TimeoutStartSec = "2h";
    };
  };

  # Sunday 03:30 Pacific: inside json-lab's "after 2am and before 6am" window and the
  # Sunday lock-file maintenance window, so the run can open PRs.
  systemd.user.timers.renovate = {
    Unit.Description = "Weekly Renovate run";
    Timer = {
      OnCalendar = "Sun *-*-* 03:30:00 America/Los_Angeles";
      Persistent = true;
    };
    Install.WantedBy = [ "timers.target" ];
  };
}
