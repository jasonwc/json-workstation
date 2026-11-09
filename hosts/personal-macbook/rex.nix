{ pkgs, rex, ... }:

# Rex on JSON-MACBOOK16 as a dev server: a personal Rex server from the `rex` flake's
# prebuilt CLI, kept running by launchd, for Rex for Mac on JSON-PAPERBOOK (reached
# through modules/darwin/rex-tunnels.nix). services.rex in Rex's home-manager module
# is Linux-only (on a Mac the Rex app normally runs the server), so this is the
# launchd equivalent of hosts/json-mini/rex.nix.
#
# It listens on the CLI's default macOS socket,
# ~/Library/Application Support/rex/server.sock, so local `rex` commands (and, as far
# as we can tell, Rex for Mac if it's installed here later) use this same server.
# A user agent, not a daemon: it runs in the GUI login session, so programs in its
# sessions get the login keychain like Terminal does (gh, Claude Code, git).
#
# `update` reloads the agent when the package changes, which restarts the server and
# ends every session (unlike json-mini, where switches keep the old server running).
#
#   rex server status
#   tail /tmp/rex-server.err.log
#   launchctl kickstart -k gui/$(id -u)/com.user.rex-server   # restart (ends sessions)
let
  package = rex.packages.${pkgs.stdenv.hostPlatform.system}.rex;
in
{
  home-manager.users.jasonwc = {
    imports = [ rex.homeManagerModules.default ];
    programs.rex = {
      enable = true;
      inherit package;
    };
  };

  launchd.user.agents.rex-server = {
    serviceConfig = {
      Label = "com.user.rex-server";
      ProgramArguments = [
        "${package}/bin/rex"
        "server"
        "run"
        "--log-format"
        "text"
      ];
      RunAtLoad = true;
      KeepAlive = true;
      ThrottleInterval = 5;
      StandardErrorPath = "/tmp/rex-server.err.log";
      EnvironmentVariables = {
        HOME = "/Users/jasonwc";
        # As Rex's home-manager service does: the server and its programs find the
        # xterm-rex entry; the trailing colon keeps the system's default entries.
        TERMINFO_DIRS = "${package}/share/terminfo:";
      };
    };
  };
}
