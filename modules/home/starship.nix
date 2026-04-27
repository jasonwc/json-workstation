{ pkgs, ... }:

{
  programs.starship = {
    enable = true;
    # On Darwin we use a custom zsh hook (see zsh.nix) that avoids `$(...)`
    # to dodge the macOS 26 SIGCHLD lost-wakeup bug. Linux hosts use upstream.
    enableZshIntegration = !pkgs.stdenv.isDarwin;
    settings = {
      add_newline = false;
      format = "$shlvl$shell$username$hostname$nix_shell$git_branch$git_commit$git_state$git_status$directory$jobs$cmd_duration$character";

      shlvl = {
        disabled = false;
        symbol = "";
        style = "bright-red bold";
      };
      shell = {
        disabled = false;
        format = "$indicator";
        fish_indicator = "";
        bash_indicator = "[BASH](bright-white) ";
        zsh_indicator = "[ZSH](bright-white) ";
      };
      username = {
        style_user = "bright-white bold";
        style_root = "bright-red bold";
      };
      hostname = {
        ssh_only = true;
        style = "bright-green bold";
      };
      nix_shell = {
        symbol = "";
        format = "[$symbol$name]($style) ";
        style = "bright-purple bold";
      };
      git_branch = {
        only_attached = true;
        symbol = "";
        format = "[$symbol$branch]($style) ";
        style = "bright-yellow bold";
      };
      git_commit = {
        only_detached = true;
        format = "[$hash]($style) ";
        style = "bright-yellow bold";
      };
      git_state.style = "bright-purple bold";
      git_status.style = "bright-green bold";
      directory = {
        read_only = " ";
        truncation_length = 0;
      };
      cmd_duration = {
        format = "[$duration]($style) ";
        style = "bright-blue";
      };
      jobs.style = "bright-green bold";
      character = {
        success_symbol = "[\\$](bright-green bold)";
        error_symbol = "[\\$](bright-red bold)";
      };
    };
  };
}
