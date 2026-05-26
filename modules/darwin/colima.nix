{ pkgs, ... }:

{
  # Colima runs the Docker engine inside a Lima VM and exposes a socket at
  # ~/.colima/default/docker.sock. The docker CLI itself is installed via
  # modules/home/packages.nix and is shared with Linux hosts; this module
  # only adds the engine + autostart on macOS.
  #
  # All colima runtime tunables (cpu, memory, vmType, docker daemon ulimits,
  # in-VM provision scripts) live in modules/home/colima.nix as a declarative
  # ~/.colima/default/colima.yaml, so the launchd agent below just runs
  # `colima start` and lets the yaml drive behavior.

  environment.systemPackages = [ pkgs.colima ];

  environment.variables.DOCKER_HOST = "unix:///Users/jasonwc/.colima/default/docker.sock";

  # Raise the system-wide file descriptor limit that launchd hands to every
  # process it spawns. macOS ships with `launchctl limit maxfiles 256
  # unlimited`, which is what GUI-launched apps and login shells inherit.
  # 256 is far below what Colima + nested Kind control-plane containers need
  # on the host side (the Lima process opens many sockets/fds per container).
  # kern.maxfilesperproc on this hardware is 184320, so 65536 stays well
  # under the kernel cap while giving every process plenty of headroom.
  launchd.daemons.limit-maxfiles = {
    serviceConfig = {
      Label = "limit.maxfiles";
      ProgramArguments = [
        "/bin/launchctl"
        "limit"
        "maxfiles"
        "65536"
        "184320"
      ];
      RunAtLoad = true;
      ServiceIPC = false;
    };
  };

  launchd.user.agents.colima = {
    serviceConfig = {
      Label = "com.user.colima";
      ProgramArguments = [
        "${pkgs.colima}/bin/colima"
        "start"
      ];
      RunAtLoad = true;
      KeepAlive = false;
      StandardOutPath = "/tmp/colima.out.log";
      StandardErrorPath = "/tmp/colima.err.log";
      EnvironmentVariables = {
        HOME = "/Users/jasonwc";
        PATH = "${pkgs.colima}/bin:${pkgs.coreutils}/bin:/usr/bin:/bin";
      };
    };
  };
}
