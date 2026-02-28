{ pkgs, ... }:

{
  home.packages = with pkgs; [
    awscli2
    azure-cli
    elixir_1_18
    glab
    (google-cloud-sdk.withExtraComponents [
      google-cloud-sdk.components.gke-gcloud-auth-plugin
      google-cloud-sdk.components.cloud_sql_proxy
    ])
    google-cloud-sql-proxy
    ibmcloud-cli
  ];
}
