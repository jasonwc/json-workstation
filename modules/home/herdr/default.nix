{ pkgs, ... }:

# herdr — a terminal agent multiplexer, evaluated as a replacement for the
# tmux + smug + sesh `mux` flow (modules/home/mux) when driving Claude Code
# across forester groves (~/workspace/paper-forest).
#
# Why it earns its place next to tmux: herdr detects per-agent state
# (idle/working/blocked/done) by reading pane output and raises a desktop
# notification when an agent needs input — the thing tmux is blind to. Its
# object model is session > workspace > tab > pane, with git worktrees as a
# first-class object.
#
# Scope note: herdr's `worktree` is single-repo. A forester *grove* is a
# bundle of ~40 member-repo worktrees, so forester still owns grove creation;
# herdr replaces the mux/tmux layer on top, one workspace per grove.
#
# Config lives in ./config.toml and is tuned to match ../tmux.nix keybindings
# (prefix C-z, hjkl panes, tokyo-night theme). This module runs alongside the
# `mux` module during the pilot; neither depends on the other.
#
# Agent detection: herdr identifies Claude (incl. via `paper start claude`,
# which exec's the agent) and tracks idle/working from screen output with zero
# config — verified on the native Nix binary. Known gap: its screen heuristic
# does NOT flag Claude's approval/permission/trust dialogs as `blocked` (they
# read as `idle`), so background "agent needs input" notifications are
# unreliable for those prompts as of herdr 0.7.x.
#
# The opt-in claude integration hook does NOT fix that gap — its v7 hook only
# reports the session id on SessionStart (for `resume_agents_on_restore`), not
# live state. Install it only if you want conversation-resume after a herdr
# server restart. It merges additively into ~/.claude/settings.json (a plain
# file, not HM-managed) beside the peon-ping hooks — verified no clobber — but
# is left manual so a `switch` never mutates the live Claude Code config:
#   herdr integration install claude    # adds ~/.claude/hooks/herdr-agent-state.sh
#   herdr integration uninstall claude  # fully reverses it

{
  home.packages = [ pkgs.herdr ];

  xdg.configFile."herdr/config.toml".source = ./config.toml;
}
