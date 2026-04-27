{ darwin, home-manager }:

darwin.lib.darwinSystem {
  system = "aarch64-darwin";
  modules = [
    home-manager.darwinModules.home-manager
    ../../modules/darwin
    ../../modules/darwin/apps.nix
    {
      users.users.jasonwc.home = "/Users/jasonwc";
      home-manager.backupFileExtension = "backup";
      home-manager.useUserPackages = true;
      home-manager.users.jasonwc = { ... }: {
        imports = [
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
        ];
        home.username = "jasonwc";
        home.homeDirectory = "/Users/jasonwc";
        home.stateVersion = "23.05";
        nixpkgs.config.allowUnfree = true;
        programs.home-manager.enable = true;
      };
    }
  ];
}
