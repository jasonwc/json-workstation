{
  nixpkgs,
  home-manager,
  nix-flatpak,
}:

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
    ../../modules/home/zoxide.nix
    ../../modules/home/packages.nix
    ../../modules/home/coding-agents.nix
    ../../modules/home/fonts.nix
    ../../modules/home/flatpak.nix
    ../../modules/home/authorized-keys.nix
    ../../modules/home/mux
    ../../modules/home/herdr
    (
      { pkgs, ... }:
      {
        home.username = "jasonwc";
        home.homeDirectory = "/home/jasonwc";
        home.stateVersion = "23.05";
        # home-manager master still reports 26.05 while nixpkgs-unstable has
        # moved to 26.11pre-git. Remove once HM bumps master past 26.05.
        home.enableNixpkgsReleaseCheck = false;
        nixpkgs.config.allowUnfree = true;
        programs.home-manager.enable = true;
        programs.git.settings.user.email = "jasonwccodes@gmail.com";

        home.packages = with pkgs; [
          qemu_kvm
          qemu-utils
        ];
      }
    )
  ];
}
