{ pkgs, lib, ... }:

{
  imports = [
    ./deepseek-harness.nix
    ./json-lab-inference.nix
  ];

  # claude-code, codex, opencode and pi are upstream prebuilt binaries, pinned
  # in ./*-native.nix rather than nixpkgs so we track the vendors' release
  # channels directly. scripts/bump-agents.sh moves them all to latest.
  # DISABLE_AUTOUPDATER keeps Claude Code's bundled updater from drifting away
  # from the pin (and from recreating ~/.local/bin/claude, which would shadow
  # this on PATH).
  home.sessionVariables.DISABLE_AUTOUPDATER = "1";

  home.packages =
    with pkgs;
    [
      (callPackage ./claude-code-native.nix { })
      (callPackage ./codex-native.nix { })
      (callPackage ./opencode-native.nix { })
      (callPackage ./pi-native.nix { })
      antigravity-cli # Gemini CLI's successor; the binary is `agy`
      cursor-cli # the binary is `cursor-agent`
      github-copilot-cli # the binary is `copilot`
    ];
}
