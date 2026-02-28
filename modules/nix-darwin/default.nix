{ inputs, ... }:

{
  users.users.jasonwc.home = "/Users/jasonwc";

  home-manager.users.jasonwc = ../home-manager;
  home-manager.useUserPackages = true;
  home-manager.backupFileExtension =  "backup";

  homebrew.enable = true;
  homebrew.casks = [
    "spotify"
    "microsoft-edge"
    "loopback"
    "audio-hijack"
    "soundsource"
    "expressvpn"
    "notion"
    "tandem"
    "tuple"
    "miro"
    "zoom"
    "visual-studio-code"
    "iterm2"
    "warp"
    "slack"
  ];

  nix.settings.experimental-features = [
    "flakes"
    "nix-command"
  ];

  nixpkgs.config.allowUnfree = true;

  security.pam.services.sudo_local.touchIdAuth = true;

  programs.zsh.enable = true;

  system.defaults.dock.autohide = true;

  system.stateVersion = 4;
  nix.enable = false;
}


