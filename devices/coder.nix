{ nixpkgs, home-manager }:

let
  system = "x86_64-linux";
  pkgs = nixpkgs.legacyPackages.${system};
in
home-manager.lib.homeManagerConfiguration {
  inherit pkgs;
  modules = [
    ../modules/home-manager
    {
      home.username = pkgs.lib.mkForce "coder";
      home.homeDirectory = pkgs.lib.mkForce "/home/coder";
    }
  ];
}
