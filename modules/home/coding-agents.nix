{ pkgs, lib, ... }:

{
  # claude-code and codex are native standalone builds, pinned in
  # ./claude-code-native.nix and ./codex-native.nix rather than nixpkgs so we
  # track the vendors' release channels directly.
  # DISABLE_AUTOUPDATER keeps Claude Code's bundled updater from drifting away
  # from the pin (and from recreating ~/.local/bin/claude, which would shadow
  # this on PATH).
  home.sessionVariables.DISABLE_AUTOUPDATER = "1";

  # aider-chat pulls ffmpeg-full → kvazaar, whose check phase is broken on
  # aarch64-darwin and isn't in any binary cache. Linux-only.
  home.packages =
    with pkgs;
    [
      (callPackage ./claude-code-native.nix { })
      (callPackage ./codex-native.nix { })
      gemini-cli
      goose-cli
      opencode
      pi-coding-agent
    ]
    ++ lib.optional stdenv.isLinux aider-chat;
}
