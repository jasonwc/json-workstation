{ ... }:

{
  nix.settings.experimental-features = [
    "flakes"
    "nix-command"
  ];

  nixpkgs.config.allowUnfree = true;

  system.primaryUser = "jasonwc";

  security.pam.services.sudo_local.touchIdAuth = true;

  programs.zsh.enable = true;

  system.defaults.dock.autohide = true;

  system.stateVersion = 4;
  nix.enable = false;
}
