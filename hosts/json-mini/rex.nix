# Rex (Superlogical's multiplexer, private beta): a personal Rex server on json-mini, from
# the `rex` flake input's home-manager module. It runs as this user (systemd user service
# `rex`) and survives logout because json-mini has lingering on (`loginctl enable-linger`).
#
# Personal mode, not the .deb's shared/login servers: those are system units plus PAM,
# /etc/rex and a `rex` group, which home-manager can't manage on Pop!_OS, and only one
# person uses this box.
#
# No network listener: the server is on its Unix socket only. Reach it from a Mac by
# forwarding that socket over SSH and adding the local end in Rex for Mac
# (Add Remote Host…) or with `rex hosts add`:
#   ssh -N json-mini -L ~/.ssh/rex-json-mini.sock:/run/user/1000/rex/server.sock
# Rex can't authenticate plain TCP/HTTP callers (`allowAnonymous` = shell as jasonwc for
# anyone on the LAN), so don't add one; Rex for iOS needs Tailscale (services.rex.tailscale).
#
#   rex server status                  # socket path, version
#   journalctl --user -u rex           # server log
#   systemctl --user restart rex       # pick up a new version after `update` (ends sessions)
{ ... }:
{
  programs.rex.enable = true;
  services.rex.enable = true;
}
