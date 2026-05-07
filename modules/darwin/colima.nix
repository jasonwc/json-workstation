{ pkgs, ... }:

{
  # Colima runs the Docker engine inside a Lima VM and exposes a socket at
  # ~/.colima/default/docker.sock. The docker CLI itself is installed via
  # modules/home/packages.nix and is shared with Linux hosts; this module
  # only adds the engine + autostart on macOS.
  #
  # --vm-type=vz uses Apple's Virtualization.framework (much faster than
  # QEMU on Apple Silicon, requires macOS 13+).

  environment.systemPackages = [ pkgs.colima ];

  environment.variables.DOCKER_HOST = "unix:///Users/jasonwc/.colima/default/docker.sock";

  launchd.user.agents.colima = {
    serviceConfig = {
      Label = "com.user.colima";
      ProgramArguments = [
        "${pkgs.colima}/bin/colima"
        "start"
        "--vm-type=vz"
        "--cpu"
        "4"
        "--memory"
        "8"
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
