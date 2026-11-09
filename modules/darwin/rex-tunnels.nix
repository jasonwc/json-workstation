{ config, lib, ... }:

# SSH forwards of remote Rex servers' Unix sockets, so Rex for Mac can use them.
# Neither server has a network listener (Rex can't authenticate plain TCP/HTTP
# callers); over SSH, Rex sees the SSH user. Each host picks its targets with
# `rexTunnels.hosts`; each target gets a launchd agent that keeps the forward open
# at a fixed local path. In Rex for Mac, Add Remote Host… and enter, e.g.:
#   /Users/jasonwc/.ssh/rex-json-mini.sock
#
# JSON-PAPERBOOK reaches both targets only while on the Firewalla WireGuard VPN;
# off it, the agents just keep retrying.
#
# launchd restarts ssh whenever it drops (sleep, network/VPN change, remote reboot);
# ServerAlive notices a dead link within ~90s. It authenticates with the Mac's own
# key (modules/home/authorized-keys.nix) non-interactively (BatchMode), so the key
# must be usable without a prompt (no passphrase, or one stored in the keychain).
#
#   launchctl kickstart -k gui/$(id -u)/com.user.rex-<target>   # reconnect now
#   tail /tmp/rex-<target>.err.log                              # why it failed
let
  targets = {
    # hosts/json-mini/rex.nix
    json-mini = {
      destination = "jasonwc@json-mini.lan";
      socket = "/run/user/1000/rex/server.sock";
    };
    # hosts/personal-macbook/rex.nix. `json-macbook16` is the pinned-IP Host in
    # modules/home/ssh.nix.
    json-macbook16 = {
      destination = "json-macbook16";
      socket = "/Users/jasonwc/Library/Application Support/rex/server.sock";
    };
  };

  agent = name: target: {
    serviceConfig = {
      Label = "com.user.rex-${name}";
      ProgramArguments = [
        # Apple's ssh, for keychain-stored key passphrases.
        "/usr/bin/ssh"
        "-N"
        "-o"
        "BatchMode=yes"
        "-o"
        "ConnectTimeout=10"
        "-o"
        "ExitOnForwardFailure=yes"
        "-o"
        "StreamLocalBindUnlink=yes"
        "-o"
        "ServerAliveInterval=30"
        "-o"
        "ServerAliveCountMax=3"
        "-L"
        "/Users/jasonwc/.ssh/rex-${name}.sock:${target.socket}"
        target.destination
      ];
      RunAtLoad = true;
      KeepAlive = true;
      ThrottleInterval = 15;
      StandardErrorPath = "/tmp/rex-${name}.err.log";
      EnvironmentVariables.HOME = "/Users/jasonwc";
    };
  };
in
{
  options.rexTunnels.hosts = lib.mkOption {
    type = lib.types.listOf (lib.types.enum (lib.attrNames targets));
    default = [ ];
    description = "Remote Rex servers to keep an SSH socket forward open to.";
  };

  config.launchd.user.agents = lib.listToAttrs (
    map (name: lib.nameValuePair "rex-${name}" (agent name targets.${name})) config.rexTunnels.hosts
  );
}
