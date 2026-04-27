{ pkgs, lib, ... }:

{
  # aider-chat pulls ffmpeg-full → kvazaar, whose check phase is broken on
  # aarch64-darwin and isn't in any binary cache. Linux-only.
  home.packages =
    with pkgs;
    [
      claude-code
      codex
      gemini-cli
      goose-cli
      opencode
      pi-coding-agent
    ]
    ++ lib.optional stdenv.isLinux aider-chat;
}
