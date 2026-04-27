{ ... }:

{
  programs.git = {
    enable = true;
    signing.format = null;
    settings = {
      user = {
        name = "Jason Carter";
        email = "jasonwccodes@gmail.com";
      };
      alias = {
        ci = "commit";
        co = "checkout";
        s = "status";
        down = "pull --rebase";
        up = "push -u";
      };
      init.defaultBranch = "main";
      core.editor = "vim";
      push.autoSetupRemote = true;
      pull.rebase = true;
    };
    ignores = [ "*.swp" "*.swo" ".DS_Store" "*.un~" ];
  };
}
