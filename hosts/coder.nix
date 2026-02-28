{ nixpkgs, home-manager }:

let
  system = "x86_64-linux";
  pkgs = nixpkgs.legacyPackages.${system};
in
home-manager.lib.homeManagerConfiguration {
  inherit pkgs;
  modules = [
    ../modules/home/shell.nix
    ../modules/home/git.nix
    ../modules/home/editor.nix
    ../modules/home/tmux.nix
    ../modules/home/ssh.nix
    ../modules/home/direnv.nix
    ../modules/home/packages.nix
    ../modules/home/fonts.nix
    ../modules/home/work
    {
      home.username = "coder";
      home.homeDirectory = "/home/coder";
      home.stateVersion = "23.05";
      home.sessionVariables.EDITOR = "nvim";
      home.backupFileExtension = "backup";
      nixpkgs.config.allowUnfree = true;
      programs.home-manager.enable = true;
    }
  ];
}
