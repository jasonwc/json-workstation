{ pkgs, ... }:

{
  programs.zsh = {
    enable = true;
    initContent = ''
      export LSCOLORS="exfxcxdxbxegedabagacad"
      export CLICOLOR=true
      export LC_ALL=en_US.UTF-8
      export LANG=en_US.UTF-8

      export EDITOR='vim'
      export PROJECT_BASE_DIR="$HOME/workspace"
      export PROJECT_FOLDER="$HOME/workspace"

      HISTFILE=~/.zsh_history
      HISTSIZE=10000
      SAVEHIST=10000

      autoload -Uz compinit
      compinit

      setopt NO_BG_NICE # don't nice background tasks
      setopt NO_HUP
      setopt NO_LIST_BEEP
      setopt LOCAL_OPTIONS # allow functions to have local options
      setopt LOCAL_TRAPS # allow functions to have local traps
      setopt HIST_VERIFY
      setopt SHARE_HISTORY # share history between sessions ???
      setopt EXTENDED_HISTORY # add timestamps to history
      setopt PROMPT_SUBST
      setopt CORRECT
      setopt COMPLETE_IN_WORD
      setopt IGNORE_EOF
      setopt APPEND_HISTORY # adds history
      setopt INC_APPEND_HISTORY SHARE_HISTORY  # adds history incrementally and share it across sessions
      setopt HIST_IGNORE_ALL_DUPS  # don't record dupes in history
      setopt HIST_REDUCE_BLANKS

      zle -N newtab

      bindkey -e # emacs key bindings

      bindkey '^[^[[D' backward-word
      bindkey '^[^[[C' forward-word
      bindkey '^[[5D' beginning-of-line
      bindkey '^[[5C' end-of-line
      bindkey '^[[3~' delete-char
      bindkey '^[^N' newtab
      bindkey '^?' backward-delete-char
      bindkey "^[[3~" delete-char

      autoload -U up-line-or-beginning-search
      autoload -U down-line-or-beginning-search
      zle -N up-line-or-beginning-search
      zle -N down-line-or-beginning-search
      bindkey "^[[A" up-line-or-beginning-search # Up
      bindkey "^[[B" down-line-or-beginning-search # Down
    '';
    shellAliases =
      let
        update-command =
          if pkgs.stdenv.isDarwin
          then "darwin-rebuild"
          else "home-manager";
        update-args =
          if pkgs.stdenv.isDarwin
          then "switch --flake ."
          else "switch -b backup --flake .";
      in
      {
        ll = "ls -l";
        ls = "ls --color";
        k  = "kubectl";
        da = "direnv allow";
        update = ''
          cd ~/.system \
            && ${update-command} ${update-args} \
            && exec $SHELL
        '';
        update-code-extensions = ''
          vscode-update-exts \
            > ~/.system/modules/home/vscode/extensions.nix
        '';
      };
    history = {
      size = 10000;
    };
    localVariables = {
      RPROMPT = null;
    };
  };

  programs.starship = {
    enable = true;
    enableZshIntegration = true;
    settings = {
      add_newline = false;
      format = "$shlvl$shell$username$hostname$nix_shell$git_branch$git_commit$git_state$git_status$directory$jobs$cmd_duration$character";
      shlvl = {
        disabled = false;
        symbol = "ﰬ";
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
        style = "bright-green bold";
        ssh_only = true;
      };
      nix_shell = {
        symbol = "";
        format = "[$symbol$name]($style) ";
        style = "bright-purple bold";
      };
      git_branch = {
        only_attached = true;
        format = "[$symbol$branch]($style) ";
        symbol = "שׂ";
        style = "bright-yellow bold";
      };
      git_commit = {
        only_detached = true;
        format = "[ﰖ$hash]($style) ";
        style = "bright-yellow bold";
      };
      git_state = {
        style = "bright-purple bold";
      };
      git_status = {
        style = "bright-green bold";
      };
      directory = {
        read_only = " ";
        truncation_length = 0;
      };
      cmd_duration = {
        format = "[$duration]($style) ";
        style = "bright-blue";
      };
      jobs = {
        style = "bright-green bold";
      };
      character = {
        success_symbol = "[\\$](bright-green bold)";
        error_symbol = "[\\$](bright-red bold)";
      };
    };
  };
}
