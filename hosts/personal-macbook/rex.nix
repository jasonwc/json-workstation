{ ... }:

# Rex for Mac -> json-mini's personal Rex server (hosts/json-mini/rex.nix). That
# server listens only on its Unix socket, so this agent keeps an SSH forward of it
# open at a fixed local path. In Rex for Mac, Add Remote Host… and enter:
#   /Users/jasonwc/.ssh/rex-json-mini.sock
#
# Rex sees the SSH user, so no anonymous network listener is needed. launchd
# restarts ssh whenever it drops (sleep, network change, json-mini reboot);
# ServerAlive notices a dead link within ~90s. It authenticates with this Mac's
# json-macbook16 key non-interactively (BatchMode), so the key must be usable
# without a prompt (no passphrase, or one stored in the macOS keychain).
#
#   launchctl kickstart -k gui/$(id -u)/com.user.rex-json-mini   # reconnect now
#   tail /tmp/rex-json-mini.err.log                              # why it failed
let
  localSocket = "/Users/jasonwc/.ssh/rex-json-mini.sock";
  remoteSocket = "/run/user/1000/rex/server.sock";
in
{
  launchd.user.agents.rex-json-mini = {
    serviceConfig = {
      Label = "com.user.rex-json-mini";
      ProgramArguments = [
        # Apple's ssh, for keychain-stored key passphrases.
        "/usr/bin/ssh"
        "-N"
        "-o"
        "BatchMode=yes"
        "-o"
        "ExitOnForwardFailure=yes"
        "-o"
        "StreamLocalBindUnlink=yes"
        "-o"
        "ServerAliveInterval=30"
        "-o"
        "ServerAliveCountMax=3"
        "-L"
        "${localSocket}:${remoteSocket}"
        "jasonwc@json-mini.lan"
      ];
      RunAtLoad = true;
      KeepAlive = true;
      ThrottleInterval = 15;
      StandardErrorPath = "/tmp/rex-json-mini.err.log";
      EnvironmentVariables.HOME = "/Users/jasonwc";
    };
  };
}
