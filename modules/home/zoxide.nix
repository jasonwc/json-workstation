{ pkgs, lib, ... }:

let
  # On Darwin, zoxide's chpwd hook calls `\command zoxide add -- "$(__zoxide_pwd)"`
  # on every cd. That `$(...)` substitution would hang under tmux due to the
  # macOS 26 SIGCHLD lost-wakeup bug (see zsh.nix). Patch it to use $PWD
  # directly — chpwd fires after cd, so $PWD is already the new directory and
  # no subshell is needed.
  zoxideInitDarwin = pkgs.runCommand "zoxide-init.zsh" { } ''
    ${pkgs.zoxide}/bin/zoxide init zsh \
      | sed 's|"\$(__zoxide_pwd)"|"\$PWD"|g' > $out
  '';
in
{
  programs.zoxide = {
    enable = true;
    # On Darwin we source a patched init script below to avoid `$(...)` in
    # the chpwd hook. Linux hosts use the upstream integration.
    enableZshIntegration = !pkgs.stdenv.isDarwin;
  };

  programs.zsh.initContent = lib.optionalString pkgs.stdenv.isDarwin ''
    source ${zoxideInitDarwin}
  '';
}
