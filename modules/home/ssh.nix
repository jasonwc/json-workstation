{ ... }:

{
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    settings."*" = {
      controlPath = "none";
    };
  };
}
