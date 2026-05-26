{ darwin, home-manager, codexOverlay }:

darwin.lib.darwinSystem {
  system = "aarch64-darwin";
  modules = [
    home-manager.darwinModules.home-manager
    ../../modules/darwin
    ../../modules/darwin/apps.nix
    ../../modules/darwin/colima.nix
    ../../modules/darwin/dev-server.nix
    {
      nixpkgs.overlays = [ codexOverlay ];

      networking.hostName = "JSON-MACBOOK16";
      networking.localHostName = "JSON-MACBOOK16";
      networking.computerName = "JSON-MACBOOK16";

      users.users.jasonwc.home = "/Users/jasonwc";
      home-manager.backupFileExtension = "backup";
      home-manager.useUserPackages = true;
      # Required so system-level nixpkgs.overlays (e.g. codexOverlay) reach
      # home.packages. Without this, home-manager builds its own pkgs from
      # the nixpkgs input and silently ignores system overlays.
      home-manager.useGlobalPkgs = true;
      home-manager.users.jasonwc =
        { ... }:
        {
          imports = [
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
            ../../modules/home/authorized-keys.nix
            ../../modules/home/colima.nix
          ];
          home.username = "jasonwc";
          home.homeDirectory = "/Users/jasonwc";
          home.stateVersion = "23.05";
          programs.home-manager.enable = true;
          programs.git.settings.user.email = "jasonwccodes@gmail.com";
          programs.colima = {
            enable = true;
            configFile = ./colima.yaml;
          };
        };
    }
  ];
}
