{ lib, pkgs, ... }:

{
  # SSH keys permitted to connect as jasonwc — mirrors
  # https://github.com/jasonwc.keys. Label each key per device so revoking a
  # single one is straightforward.
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
        ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOottRYlkVYu5PJ1EpLO9mu62uUAZ04M5Ig1L4tIyxgT json-paperbook
      '';
    in
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      mkdir -p "$HOME/.ssh"
      chmod 700 "$HOME/.ssh"
      install -m 600 ${authorizedKeys} "$HOME/.ssh/authorized_keys"
    '';
}
