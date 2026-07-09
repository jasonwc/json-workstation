{
  darwin,
  home-manager,
  peon-ping,
}:

darwin.lib.darwinSystem {
  system = "aarch64-darwin";
  modules = [
    home-manager.darwinModules.home-manager
    ../../modules/darwin
    ../../modules/darwin/apps.nix
    ../../modules/darwin/colima.nix
    ../../modules/darwin/ssh-server.nix
    {
      networking.hostName = "JSON-PAPERBOOK";
      networking.localHostName = "JSON-PAPERBOOK";
      networking.computerName = "JSON-PAPERBOOK";

      homebrew.casks = [
        "linear"
        "loom"
      ];

      # Datadog's lapdog comes from a third-party tap. Homebrew now requires
      # tap trust, which lives in ~/.homebrew/trust.json and can't be declared
      # here — one-time per machine:
      #   brew trust --formula datadog/lapdog/lapdog
      homebrew.taps = [ "datadog/lapdog" ];
      homebrew.brews = [ "datadog/lapdog/lapdog" ];

      users.users.jasonwc.home = "/Users/jasonwc";
      home-manager.backupFileExtension = "backup";
      home-manager.useUserPackages = true;
      # Required so system-level nixpkgs.overlays reach home.packages.
      # Without this, home-manager builds its own pkgs from the nixpkgs
      # input and silently ignores system overlays.
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
            ../../modules/home/authorized-keys.nix
            ../../modules/home/colima.nix
            ../../modules/home/mux
            ../../modules/home/herdr
            peon-ping.homeManagerModules.default
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

          # Warcraft peon voice lines on Claude Code events. The flake exposes
          # no overlay, so point `package` at its own per-system build.
          programs.peon-ping = {
            enable = true;
            claudeCodeIntegration = true;
            package = peon-ping.packages.${pkgs.stdenv.hostPlatform.system}.default;
            installPacks = [ "peon" ];
            # config.json is a read-only Nix-store symlink here, so the `peon`
            # CLI / config skill can't persist changes — settings must live in
            # the flake. Default volume is 0.5.
            settings = {
              volume = 0.3;
              # Make "an agent is waiting on YOU" unmistakable vs. the routine
              # completion banners. These three keys are the Claude Code
              # input-needed events: permission = approval prompts, question =
              # elicitation dialogs, idle = "your move" idle prompts. Banners
              # only surface when the terminal isn't focused (peon is
              # focus-aware), so this fires exactly when you've tabbed away.
              # Completion/error banners keep their defaults (unset keys).
              notification_templates = {
                permission = "🔔 WAITING — {project} needs your approval";
                question = "🔔 WAITING — {project} needs your input";
                idle = "🔔 WAITING — {project} is idle, your move";
              };
            };
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
