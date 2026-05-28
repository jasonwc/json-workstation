{
  description = "Jason's Nix packages and system configurations.";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";

    # Pinned to a trunk eval Hydra has cached codex for, since the
    # nixpkgs-unstable channel often advances past darwin codex builds that
    # timed out on Hydra. Bump to a newer eval (see hydra.nixos.org →
    # nixpkgs:trunk:codex.aarch64-darwin) when a newer codex is desired.
    nixpkgs-codex.url = "github:nixos/nixpkgs/059edbdafe650eb34c2f504f8b7d9f831f5b2583";

    darwin = {
      url = "github:lnl7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-flatpak.url = "github:gmodena/nix-flatpak/?ref=v0.7.0";
  };

  outputs =
    inputs@{ flake-parts, ... }:
    let
      inherit (inputs)
        darwin
        home-manager
        nix-flatpak
        nixpkgs
        nixpkgs-codex
        ;

      codexOverlay = final: prev: {
        codex = nixpkgs-codex.legacyPackages.${prev.stdenv.hostPlatform.system}.codex;
      };
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
            inherit darwin home-manager codexOverlay;
          };
          "JSON-PAPERBOOK" = import ./hosts/paperbook {
            inherit darwin home-manager codexOverlay;
          };
        };
        homeConfigurations = {
          "JSON-Mini" = import ./hosts/json-mini {
            inherit nixpkgs home-manager nix-flatpak codexOverlay;
          };
          "JSON-STATION" = import ./hosts/json-station {
            inherit nixpkgs home-manager codexOverlay;
          };
        };
      };
    };
}
