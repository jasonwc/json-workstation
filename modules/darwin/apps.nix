{ ... }:

{
  homebrew.enable = true;
  homebrew.brews = [
    "dagger"
    "wireguard-tools"
  ];
  # GUI apps install via casks; the ones marked auto_updates keep themselves
  # current, so the list only controls install, not version.
  # Not installable here (no cask): Superconductor — get it manually from
  # https://www.superconductor.com/download or the Mac App Store.
  homebrew.casks = [
    "1password"
    "audio-hijack"
    "chatgpt"
    "claude"
    "conductor"
    "cursor"
    "discord"
    "google-chrome"
    "iterm2"
    "loop"
    "loopback"
    "notion"
    "obsidian"
    "slack"
    "soundsource"
    "spotify"
    "visual-studio-code"
    "warp"
    "zoom"
  ];
}
