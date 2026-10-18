# Nightly refresh of Byrdpip's read-only copy of the homelab repos' Markdown docs (/docs in
# its sandbox on spireos). The script lives in json-agents (bin/repo-docs): it fetches each
# repo's origin/main in ~/workspace and pipes the committed .md files to spireos over ssh
# (this user's ~/.ssh key; the repos are private, so spireos can't fetch them itself).
# json-agents' deploy.sh runs the same script on every Byrdpip deploy.
#
#   systemctl --user start repo-docs     # run now
#   journalctl --user -u repo-docs       # last runs
{ pkgs, ... }:
{
  systemd.user.services.repo-docs = {
    Unit.Description = "Refresh Byrdpip's /docs from the homelab repos";
    Service = {
      Type = "oneshot";
      ExecStart = "%h/workspace/json-agents/bin/repo-docs";
      Environment = [
        "WORKSPACE=%h/workspace"
        "PATH=${pkgs.lib.makeBinPath [ pkgs.bash pkgs.git pkgs.openssh pkgs.gnutar pkgs.gnugrep pkgs.findutils pkgs.coreutils ]}"
      ];
      TimeoutStartSec = "10min";
    };
  };

  systemd.user.timers.repo-docs = {
    Unit.Description = "Nightly refresh of Byrdpip's /docs";
    Timer = {
      OnCalendar = "*-*-* 04:17:00";
      Persistent = true;
    };
    Install.WantedBy = [ "timers.target" ];
  };
}
