{ pkgs, ... }:

{
  home.packages = with pkgs; [
    elixir_1_17
    glab
    (google-cloud-sdk.withExtraComponents [
      google-cloud-sdk.components.gke-gcloud-auth-plugin
      google-cloud-sdk.components.cloud_sql_proxy
    ])
    google-cloud-sql-proxy
    ibmcloud-cli
    k9s
    kind
    krew
    kubectl
    kubernetes-helm
    kustomize
    mob
    postgresql
    terraform
    tflint
    tfsec
    tmuxinator
  ];
}
