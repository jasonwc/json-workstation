{ pkgs, ... }:

{
  home.packages = with pkgs; [
    bc
    cachix
    coreutils
    direnv
    docker
    envsubst
    fzf
    gawk
    gh
    git
    htop
    jq
    nodejs
    tree
    watch
  ];
}
