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

        home.packages = with pkgs; [
          qemu_kvm
          qemu-utils
        ];

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
              ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICYYwg4749v5nSEEMzsAcCfH9Kfo6Te7CWQ/gK0Pzvkm json-station
              ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOog27hZwOVc7DKG1nSZ/ZkXrKS0NmgCyQQuNeWj/FcY json-shared
              ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGB9OGRRM87FLp6HThSCKH18KkRoWSW1aDdZKH2L++fx json-pi
              ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJkc531zhg99+bUOxbCGlSosg7CLoqB849yTO/SiC9x1 json-macbook16
            '';
          in
          lib.hm.dag.entryAfter [ "writeBoundary" ] ''
            install -D -m 600 ${authorizedKeys} $HOME/.ssh/authorized_keys
          '';
      }
    )
  ];
}
