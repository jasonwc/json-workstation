{ pkgs, ... }:

# Work session tooling: a fixed 5-window tmux layout (main · shell · servers ·
# agents · k9s) launched per directory, plus an iTerm fan-out and a sesh-backed
# picker. smug owns the layout; sesh provides the fuzzy switcher.
#
#   mux [dir]          open/attach the session for a directory (default: cwd)
#   mux-iterm [parent] one iTerm tab per subfolder of parent ($MUX_ROOT/~/workspace)
#   mux-pick           fuzzy-pick a session (tmux) or dir (zoxide) and connect
#
# In tmux, prefix + S opens the picker in a popup.

let
  mux = pkgs.writeShellApplication {
    name = "mux";
    runtimeInputs = [
      pkgs.smug
      pkgs.tmux
    ];
    text = builtins.readFile ./mux.sh;
  };

  mux-iterm = pkgs.writeShellApplication {
    name = "mux-iterm";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.findutils
      mux
    ];
    text = builtins.readFile ./mux-iterm.sh;
  };

  mux-pick = pkgs.writeShellApplication {
    name = "mux-pick";
    runtimeInputs = [
      pkgs.sesh
      pkgs.fzf
      pkgs.jq
      pkgs.tmux
      mux
    ];
    text = builtins.readFile ./mux-pick.sh;
  };
in
{
  home.packages = [
    pkgs.smug
    pkgs.sesh
    mux
    mux-iterm
    mux-pick
  ];

  xdg.configFile."smug/mux.yml".source = ./mux.yml;

  programs.tmux.extraConfig = ''
    bind S display-popup -E -w 70% -h 60% "mux-pick"
  '';
}
