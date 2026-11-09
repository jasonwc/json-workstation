{
  description = "Jason's Nix packages and system configurations.";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";

    darwin = {
      url = "github:nix-darwin/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # peon-ping: Warcraft-style coding-event sound packs wired into Claude Code
    # hooks. Its home-manager module installs packs declaratively (a pinned
    # og-packs archive) and merges hooks into ~/.claude/settings.json.
    peon-ping = {
      url = "github:PeonPing/peon-ping";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-flatpak.url = "github:gmodena/nix-flatpak/?ref=v0.7.0";

    # Rex (Superlogical's multiplexer, private beta): prebuilt binary plus a home-manager
    # module. Preview channel: there's no stable release yet (stable.tar.gz 404s). The lock
    # records the immutable per-release URL; `nix flake update rex` moves to the newest.
    rex = {
      url = "https://pkgs.superlogical.com/rex/nix/preview.tar.gz";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{ flake-parts, ... }:
    let
      inherit (inputs)
        darwin
        home-manager
        nix-flatpak
        nixpkgs
        peon-ping
        rex
        ;
    in
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "aarch64-darwin"
        "aarch64-linux"
        "x86_64-darwin"
        "x86_64-linux"
      ];
      perSystem =
        { pkgs, ... }:
        {
          formatter = pkgs.nixfmt;
          devShells.default = pkgs.mkShell {
            packages = with pkgs; [
              nixfmt
            ];
          };
        };
      flake = {
        darwinConfigurations = {
          "JSON-MACBOOK16" = import ./hosts/personal-macbook {
            inherit darwin home-manager;
          };
          "JSON-PAPERBOOK" = import ./hosts/paperbook {
            inherit darwin home-manager peon-ping;
          };
        };
        homeConfigurations = {
          "JSON-Mini" = import ./hosts/json-mini {
            inherit nixpkgs home-manager nix-flatpak rex;
          };
          "JSON-STATION" = import ./hosts/json-station {
            inherit nixpkgs home-manager;
          };
        };
      };
    };
}
