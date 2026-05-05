{ pkgs, lib, ... }:

let
  rebuildCommand =
    if pkgs.stdenv.isDarwin
    then "sudo darwin-rebuild switch --flake ."
    else "home-manager switch -b backup --flake '.#'$(hostname)";

  # macOS 26 (Tahoe) has a SIGCHLD lost-wakeup race that hangs zsh in
  # signal_suspend whenever an interactive shell uses `$(...)` command
  # substitution under tmux. Affects compinit, starship's PROMPT='$(...)',
  # and direnv's `eval "$(direnv export zsh)"` precmd. The hooks below
  # avoid `$()` entirely: starship writes to a tempfile and we read it
  # back with `$(<file)` (zsh fast-path, no fork); direnv uses zsh's
  # `=()` process substitution (also tempfile-based, no command-substitution
  # wait). Linux hosts keep the upstream integrations and compinit.
  starshipBin = "${pkgs.starship}/bin/starship";
  direnvBin = "${pkgs.direnv}/bin/direnv";

  darwinShellHooks = ''
    autoload -Uz add-zsh-hook
    zmodload zsh/parameter
    zmodload zsh/datetime
    zmodload zsh/mathfunc

    # --- direnv hook (registered first so its env updates land before
    # starship renders) -------------------------------------------------
    _direnv_hook() {
      trap -- "" SIGINT
      source =(${direnvBin} export zsh)
      trap - SIGINT
    }
    add-zsh-hook precmd _direnv_hook
    add-zsh-hook chpwd _direnv_hook

    # --- starship hook -------------------------------------------------
    STARSHIP_PROMPT_FILE="''${TMPDIR:-/tmp}/.starship-prompt-$$"
    export STARSHIP_SHELL="zsh"
    VIRTUAL_ENV_DISABLE_PROMPT=1
    setopt promptsubst

    __starship_get_time() {
      (( STARSHIP_CAPTURED_TIME = int(rint(EPOCHREALTIME * 1000)) ))
    }

    _starship_precmd() {
      # Capture command status as the first thing so nothing else clobbers it.
      STARSHIP_CMD_STATUS=$? STARSHIP_PIPE_STATUS=(''${pipestatus[@]})
      if (( ''${+STARSHIP_START_TIME} )); then
        __starship_get_time && STARSHIP_DURATION=$(( STARSHIP_CAPTURED_TIME - STARSHIP_START_TIME ))
        unset STARSHIP_START_TIME
      else
        unset STARSHIP_DURATION STARSHIP_CMD_STATUS STARSHIP_PIPE_STATUS
      fi
      STARSHIP_JOBS_COUNT="''${#jobstates[*]}"
      ${starshipBin} prompt \
        --terminal-width=$COLUMNS \
        --keymap="''${KEYMAP:-}" \
        --status="''${STARSHIP_CMD_STATUS:-}" \
        --pipestatus="''${STARSHIP_PIPE_STATUS[*]:-}" \
        --cmd-duration="''${STARSHIP_DURATION:-}" \
        --jobs="$STARSHIP_JOBS_COUNT" \
        > $STARSHIP_PROMPT_FILE
      PROMPT=$(<$STARSHIP_PROMPT_FILE)
    }

    _starship_preexec() {
      __starship_get_time && STARSHIP_START_TIME=$STARSHIP_CAPTURED_TIME
    }

    _starship_zshexit() {
      [[ -n $STARSHIP_PROMPT_FILE ]] && rm -f $STARSHIP_PROMPT_FILE
    }

    add-zsh-hook precmd _starship_precmd
    add-zsh-hook preexec _starship_preexec
    add-zsh-hook zshexit _starship_zshexit
  '';
in
{
  home.sessionVariables = {
    EDITOR = "nvim";
    LANG = "en_US.UTF-8";
    LC_ALL = "en_US.UTF-8";
    CLICOLOR = "1";
    LSCOLORS = "exfxcxdxbxegedabagacad";
    PROJECT_BASE_DIR = "$HOME/workspace";
    PROJECT_FOLDER = "$HOME/workspace";
  };

  home.sessionPath = [ "$HOME/.cargo/bin" ];

  programs.zsh = {
    enable = true;
    # On Darwin compinit's compdump uses `$()` heavily and trips the
    # macOS 26 SIGCHLD lost-wakeup bug — including in non-interactive
    # `zsh -c`, so the activation-time prebake approach also hangs.
    # No tab completion on Darwin until zsh's signal_suspend is patched
    # (see docs/apple-feedback-FB18565075.md). Linux hosts are fine.
    enableCompletion = !pkgs.stdenv.isDarwin;

    history = {
      size = 10000;
      save = 10000;
      extended = true;
      ignoreAllDups = true;
      share = true;
    };

    shellAliases = {
      ll = "ls -l";
      ls = "ls --color";
      k = "kubectl";
      da = "direnv allow";
    };

    initContent = ''
      update() {
        cd ~/.system && ${rebuildCommand} && exec "$SHELL"
      }

      bindkey -e
      bindkey '^[^[[D' backward-word
      bindkey '^[^[[C' forward-word
      bindkey '^[[5D' beginning-of-line
      bindkey '^[[5C' end-of-line
      bindkey '^[[3~' delete-char

      autoload -U up-line-or-beginning-search
      autoload -U down-line-or-beginning-search
      zle -N up-line-or-beginning-search
      zle -N down-line-or-beginning-search
      bindkey "^[[A" up-line-or-beginning-search
      bindkey "^[[B" down-line-or-beginning-search
    '' + lib.optionalString pkgs.stdenv.isDarwin darwinShellHooks;
  };
}
