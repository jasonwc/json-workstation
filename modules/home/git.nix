{ ... }:

{
  programs.git = {
    enable = true;
    aliases = {
      "ci" = "commit";
      "co" = "checkout";
      "s" = "status";
      "down" = "pull --rebase";
      "up" = "push -u";
    };
    ignores = ["*.swp" "*.swo" ".DS_Store" "*.un~"];
    extraConfig = {
      init = { defaultBranch = "main"; };
      core = { editor = "vim"; };
      push.autoSetupRemote = true;
      pull.rebase = true;
    };
  };
}
