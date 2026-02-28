{ pkgs, lib,... }:

{
  nixpkgs = {
    config.allowUnfree = true;
  };

  home = {
    username = "jasonwc";
    homeDirectory = "/Users/jasonwc";
    packages = with pkgs; [
      bc
      coreutils
      gawk
      glab
      direnv
      docker
      cachix
      elixir_1_17
      fzf
      envsubst
      gh
      git
      (google-cloud-sdk.withExtraComponents [
        google-cloud-sdk.components.gke-gcloud-auth-plugin
        google-cloud-sdk.components.cloud_sql_proxy
      ])
      google-cloud-sql-proxy
      htop
      ibmcloud-cli
      jq
      k9s
      kind
      krew
      kustomize
      kubectl
      mob
      nodejs
      postgresql
      terraform
      tflint
      tfsec
      tmuxinator
      kubernetes-helm
      tree
      watch
      nerd-fonts.fira-code
      nerd-fonts.droid-sans-mono
      nerd-fonts.hack
      nerd-fonts.noto
    ];

    sessionVariables = {
      EDITOR = "nvim";
    };

    stateVersion = "23.05";
  };

  programs.zsh = {
    enable = true;
    initContent = ''
      export LSCOLORS="exfxcxdxbxegedabagacad"
      # export LSCOLORS="gxBxhxDxfxhxhxhxhxcxcx"
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

      # http://zsh.sourceforge.net/Doc/Release/Zsh-Line-Editor.html#Zle-Widgets
      # http://zsh.sourceforge.net/Doc/Release/Zsh-Line-Editor.html#Zle-Builtins
      # In addition to these names, either ‘emacs’ or ‘viins’ is also linked to the
      # name ‘main’. If one of the VISUAL or EDITOR environment variables contain the
      # string ‘vi’ when the shell starts up then it will be ‘viins’, otherwise it
      # will be ‘emacs’. bindkey’s -e and -v options provide a convenient way to
      # override this default choice.
      # bindkey -v # vim key bindings
    '';
    shellAliases =
      let
        update-command =
          if pkgs.stdenv.isLinux
          then "sudo nixos-rebuild"
          else "darwin-rebuild";
      in
      {
        ll = "ls -l";
        ls = "ls --color";
        k  = "kubectl";
        da = "direnv allow";
        update = ''
          cd ~/.system \
            && ${update-command} switch --flake . \
            && exec $SHELL
        '';
        update-code-extensions = ''
          vscode-update-exts \
            > ~/.system/modules/home-manager/vscode/extensions.nix
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
        symbol = "";
        format = "[$symbol$name]($style) ";
        style = "bright-purple bold";
      };
      git_branch = {
        only_attached = true;
        format = "[$symbol$branch]($style) ";
        symbol = "שׂ";
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
        read_only = " ";
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

  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;
  };

  programs.git = {
    enable = true;
    userName = "Jason Carter";
    userEmail = "jason@mechanical-orchard.com";
    aliases = {
      "ci" = "commit";
      "co" = "checkout";
      "s" = "status";
      "down" = "pull --rebase";
      "up" = "push -u";
    };
    ignores = ["*.swp" "*.swo" ".DS_Store" "*.un~"];
    extraConfig = {
      init = {defaultBranch = "main";};
      core = { editor = "vim"; };
      push.autoSetupRemote = true;
      pull.rebase = true;
      co-authors = {
        at  = "Anna Thornton <anna@mechanical-orchard.com>";
        sw  = "Scott Windsor <scott.windsor@mechanical-orchard.com>";
        cw  = "Caleb Washburn <caleb.washburn@mechanical-orchard.com>";
        dl  = "David Laing <david@mechanical-orchard.com>";
        gds = "Gareth Smith <gareth.smith@mechanical-orchard.com>";
        sm  = "Scott Muc <scott.muc@mechanical-orchard.com>";
        pj  = "Porter Joens <porter@mechanical-orchard.com>";
      };
    };
  };

  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
  };

  programs.ssh = {
    enable = true;
    controlPath = "none";
  };

  programs.tmux = {
    enable = true;
    shell = "${pkgs.zsh}/bin/zsh";
    terminal = "tmux-256color";
    historyLimit = 100000;
    plugins = with pkgs;
      [
        {
          plugin = tmuxPlugins.tokyo-night-tmux;
          extraConfig = ''
            set -g @theme_variation 'moon'
          '';
        }
      ];
    extraConfig = ''
      # mouse control (clickable windows, panes, resizable panes)
      set -g mouse on

      # set default terminal mode to 256 colors
      set -g default-terminal "screen-256color"

      # reload config file (change file location to your the tmux.conf you want to use)
      bind r source-file ~/.tmux.conf

      set -g mode-keys vi

      # Enable setting window titles
      set-option -g set-titles on

      # Place the stats bar at the top
      set-option -g status-position top

      # Update status bar every 5 seconds
      set -g status-interval 5


      # set prefix to control-z
      unbind C-b
      set -g prefix C-z
      bind z send-keys C-z
      bind C-z last-window

      set -g base-index 1
      set-window-option -g pane-base-index 1

      bind | split-window -h  # Split window vertically with |
      bind - split-window     # Split window horizontally with -

      bind h select-pane -L
      bind j select-pane -D
      bind k select-pane -U
      bind l select-pane -R
      bind ` select-window -t 0

      bind H resize-pane -L 5
      bind J resize-pane -D 5
      bind K resize-pane -U 5
      bind L resize-pane -R 5

      # prefix C-d to clear the scrolled off (hidden) buffer lines
      bind C-d clear-history

      # Search for previous error
      bind-key e copy-mode \; send-keys "?Error" C-m

      bind-key -T copy-mode-vi y send-keys -X copy-pipe "reattach-to-user-namespace pbcopy" \; display-message "Copied to clipboard"

      set -sg escape-time 2

      # scrollback buffer size increase
      set -g history-limit 100000

      # Use up and down arrows for temporary "maximize"
      unbind Up; bind Up resize-pane -Z; unbind Down; bind Down resize-pane -Z

      if-shell '[[ -e ~/.tmux.conf.local ]]' 'source-file ~/.tmux.conf.local'
    '';
  };

  programs.home-manager.enable = true;
}
