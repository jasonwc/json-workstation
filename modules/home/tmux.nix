{ pkgs, ... }:

{
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
}
