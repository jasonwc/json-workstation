{
  nixpkgs,
  home-manager,
  nix-flatpak,
}:

let
  system = "x86_64-linux";
  pkgs = nixpkgs.legacyPackages.${system};
in
home-manager.lib.homeManagerConfiguration {
  inherit pkgs;
  modules = [
    nix-flatpak.homeManagerModules.nix-flatpak
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
    ../../modules/home/flatpak.nix
    (
      { lib, pkgs, ... }:
      {
        home.username = "jasonwc";
        home.homeDirectory = "/home/jasonwc";
        home.stateVersion = "23.05";
        nixpkgs.config.allowUnfree = true;
        programs.home-manager.enable = true;
        programs.git.settings.user.email = "jasonwccodes@gmail.com";

        # SSH keys permitted to connect as jasonwc@json-mini.
        # Mirrors https://github.com/jasonwc.keys — keep in sync when keys are
        # added or removed there. Label the device per key so revoking a single
        # device is straightforward.
        #
        # Installed as a real file (not a /nix/store symlink) because sshd's
        # StrictModes rejects authorized_keys whose canonical path traverses a
        # group-writable directory, and /nix/store is group-writable by nixbld.
        home.activation.authorizedKeys =
          let
            authorizedKeys = pkgs.writeText "authorized_keys" ''
              ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICYYwg4749v5nSEEMzsAcCfH9Kfo6Te7CWQ/gK0Pzvkm
              ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOog27hZwOVc7DKG1nSZ/ZkXrKS0NmgCyQQuNeWj/FcY
              ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGB9OGRRM87FLp6HThSCKH18KkRoWSW1aDdZKH2L++fx
              # JSON-MACBOOK16
              ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJkc531zhg99+bUOxbCGlSosg7CLoqB849yTO/SiC9x1 jasonwccodes@gmail.com
              ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDMxZ8r4RXfZUyLO6YoNMtgV3/VxCa1MR43UKiWqLt0mndksVz53XNcFZ26rWiRki4b6tayUCjxi8ji8Oh9Q4ljH143rV4nVTSrKW+2DhZyZFugf0HGtZxgM8f4H0Bpc6NvPj/GKeTHlQxgWICL15bjPJ/6pYnH+eqK1RvZUlXlDzcQdz3xGBzgriyi71JU0tx9EYWkTefYNHCW1km9ztQZtEiWm75LrNLzp+44AXM4g8A3HpTzS6YAcfKFBsZZ7GpLLdUwm/XDekgR/VN9QqQXxuyl1Scww4DbwdgfwlwOZ0mh8sYwf1ycOgmPlfpH2Oic7G7ftU/1ciNvFUlMgTeTVzyTl85nvcTP3n1jFWUOhuwdJMYZk8feM3oTnY8H5C1D8nva1RR02d36BFzp9+0tf1UxhBJR+Lh1Srd3i2PNImcgexU9y1laSnE1uncpzX7VMKVZeMA1i7RPWbXok49h2U/OXM8KBW4GqAl0+0qYKSXDsoJqGSsaSVSdMxiBF6c=
            '';
          in
          lib.hm.dag.entryAfter [ "writeBoundary" ] ''
            install -D -m 600 ${authorizedKeys} $HOME/.ssh/authorized_keys
          '';
      }
    )
  ];
}
