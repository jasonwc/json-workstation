{ pkgs, ... }:

{
  home.packages = with pkgs; [
    argocd
    bc
    cachix
    claude-code
    codex
    coreutils
    direnv
    docker
    envsubst
    fzf
    gawk
    gh
    git
    goose-cli
    htop
    jq
    k9s
    kind
    krew
    kubectl
    kubernetes-helm
    kustomize
    mob
    nodejs
    postgresql
    terraform
    tflint
    tfsec
    tmuxinator
    tree
    watch
  ];
}
