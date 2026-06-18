{
  darwin,
  home-manager,
  codexOverlay,
}:

darwin.lib.darwinSystem {
  system = "aarch64-darwin";
  modules = [
    home-manager.darwinModules.home-manager
    ../../modules/darwin
    ../../modules/darwin/apps.nix
    ../../modules/darwin/colima.nix
    {
      nixpkgs.overlays = [ codexOverlay ];

      networking.hostName = "JSON-PAPERBOOK";
      networking.localHostName = "JSON-PAPERBOOK";
      networking.computerName = "JSON-PAPERBOOK";

      homebrew.casks = [
        "linear"
        "loom"
      ];

      users.users.jasonwc.home = "/Users/jasonwc";
      home-manager.backupFileExtension = "backup";
      home-manager.useUserPackages = true;
      # Required so system-level nixpkgs.overlays (e.g. codexOverlay) reach
      # home.packages. Without this, home-manager builds its own pkgs from
      # the nixpkgs input and silently ignores system overlays.
      home-manager.useGlobalPkgs = true;
      home-manager.users.jasonwc =
        { pkgs, ... }:
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
            ../../modules/home/colima.nix
            ../../modules/home/mux
          ];
          home.username = "jasonwc";
          home.homeDirectory = "/Users/jasonwc";
          home.stateVersion = "23.05";
          # home-manager master still reports 26.05 while nixpkgs-unstable has
          # moved to 26.11pre-git. Remove once HM bumps master past 26.05.
          home.enableNixpkgsReleaseCheck = false;
          programs.home-manager.enable = true;
          programs.git.settings.user.email = "jason@papercompute.com";
          programs.colima = {
            enable = true;
            configFile = ./colima.yaml;
          };

          home.packages = with pkgs; [
            kubectx
            awscli2
            flarectl
            fluxcd
            netlify-cli
            dbeaver-bin
            beekeeper-studio
            zellij
          ];
        };
    }
  ];
}
