{ pkgs, ... }:

{
  programs.direnv = {
    enable = true;
    # On Darwin we use a custom zsh hook (see zsh.nix) that avoids `$(...)`
    # to dodge the macOS 26 SIGCHLD lost-wakeup bug. Linux hosts use upstream.
    enableZshIntegration = !pkgs.stdenv.isDarwin;
    nix-direnv.enable = true;
  };
}
