{
  description = "Jason's Nix packages and system configurations.";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";

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

  outputs = inputs@{ flake-parts, ... }:
    let
      inherit (inputs) darwin home-manager nix-flatpak nixpkgs;
    in
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "aarch64-darwin"
        "aarch64-linux"
        "x86_64-darwin"
        "x86_64-linux"
      ];
      perSystem = { pkgs, ... }: {
        formatter = pkgs.nixfmt-rfc-style;
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            nixfmt-rfc-style
          ];
        };
      };
      flake = {
        darwinConfigurations = {
          "JSON-MACBOOK14" = import ./hosts/work-macbook { inherit darwin home-manager; };
          "JSON-MACBOOK16" = import ./hosts/personal-macbook { inherit darwin home-manager; };
        };
        homeConfigurations = {
          "JSON-MINI" = import ./hosts/json-mini { inherit nixpkgs home-manager nix-flatpak; };
          "JSON-STATION" = import ./hosts/json-station { inherit nixpkgs home-manager; };
        };
      };
    };
}
