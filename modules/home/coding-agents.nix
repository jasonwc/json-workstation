{ pkgs, ... }:

{
  home.packages = with pkgs; [
    aider-chat
    claude-code
    codex
    gemini-cli
    goose-cli
    opencode
    pi-coding-agent
  ];
}
