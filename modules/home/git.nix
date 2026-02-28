{ ... }:

{
  programs.git = {
    enable = true;
    settings = {
      alias = {
        "ci" = "commit";
        "co" = "checkout";
        "s" = "status";
        "down" = "pull --rebase";
        "up" = "push -u";
      };
      init = { defaultBranch = "main"; };
      core = { editor = "vim"; };
      push.autoSetupRemote = true;
      pull.rebase = true;
    };
    ignores = ["*.swp" "*.swo" ".DS_Store" "*.un~"];
  };
}
