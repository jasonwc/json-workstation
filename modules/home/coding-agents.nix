{ pkgs, lib, ... }:

{
  # claude-code is the native standalone build, pinned in ./claude-code-native.nix
  # rather than nixpkgs so we track Anthropic's release channel directly.
  # DISABLE_AUTOUPDATER keeps the bundled updater from drifting away from the pin
  # (and from recreating ~/.local/bin/claude, which would shadow this on PATH).
  home.sessionVariables.DISABLE_AUTOUPDATER = "1";

  # aider-chat pulls ffmpeg-full → kvazaar, whose check phase is broken on
  # aarch64-darwin and isn't in any binary cache. Linux-only.
  home.packages =
    with pkgs;
    [
      (callPackage ./claude-code-native.nix { })
      codex
      gemini-cli
      goose-cli
      opencode
      pi-coding-agent
    ]
    ++ lib.optional stdenv.isLinux aider-chat;
}
