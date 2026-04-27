{ pkgs, ... }:

{
  home.packages = with pkgs; [
    argocd
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
