{ pkgs, ... }:

{
  home.packages = with pkgs; [
    _1password-cli
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
    go
    htop
    hurl
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
    yq-go
  ];
}
