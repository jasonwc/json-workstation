{ nixpkgs, home-manager, nix-flatpak }:

let
  system = "x86_64-linux";
  pkgs = nixpkgs.legacyPackages.${system};
in
home-manager.lib.homeManagerConfiguration {
  inherit pkgs;
  modules = [
    nix-flatpak.homeManagerModules.nix-flatpak
    ../../modules/home/zsh.nix
    ../../modules/home/starship.nix
    ../../modules/home/tmux.nix
    ../../modules/home/git.nix
    ../../modules/home/editor.nix
    ../../modules/home/ssh.nix
    ../../modules/home/direnv.nix
    ../../modules/home/packages.nix
    ../../modules/home/coding-agents.nix
    ../../modules/home/fonts.nix
    ../../modules/home/flatpak.nix
    {
      home.username = "jasonwc";
      home.homeDirectory = "/home/jasonwc";
      home.stateVersion = "23.05";
      nixpkgs.config.allowUnfree = true;
      programs.home-manager.enable = true;
      programs.git.settings.user.email = "jasonwccodes@gmail.com";
    }
  ];
}
