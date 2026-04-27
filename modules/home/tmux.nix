{ pkgs, ... }:

{
  programs.tmux = {
    enable = true;
    shell = "${pkgs.zsh}/bin/zsh";
    terminal = "tmux-256color";
    historyLimit = 100000;
    prefix = "C-z";
    keyMode = "vi";
    mouse = true;
    escapeTime = 2;
    baseIndex = 1;
    customPaneNavigationAndResize = true;
    resizeAmount = 5;

    plugins = with pkgs; [
      {
        plugin = tmuxPlugins.tokyo-night-tmux;
        extraConfig = ''
          set -g @theme_variation 'moon'
        '';
      }
    ];

    extraConfig = ''
      set-window-option -g pane-base-index 1
      set-option -g set-titles on
      set-option -g status-position top
      set -g status-interval 5

      bind r source-file ~/.config/tmux/tmux.conf \; display-message "tmux config reloaded"

      bind z send-keys C-z
      bind C-z last-window
      bind | split-window -h
      bind - split-window
      bind ` select-window -t 0

      bind C-d clear-history
      bind-key e copy-mode \; send-keys "?Error" C-m
      bind-key -T copy-mode-vi y send-keys -X copy-pipe-and-cancel "pbcopy" \; display-message "Copied to clipboard"

      unbind Up;   bind Up   resize-pane -Z
      unbind Down; bind Down resize-pane -Z
    '';
  };
}
