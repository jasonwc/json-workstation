{ inputs, ... }:

let inherit (inputs)
  darwin
  home-manager
  nixpkgs;
in
{
  flake = {
    darwinConfigurations = {
      "JSON-MACBOOK14" = import ./work-macbook.nix { inherit darwin home-manager; };
    };
    homeConfigurations = {
      "coder" = import ./coder.nix { inherit nixpkgs home-manager; };
    };
  };
}
