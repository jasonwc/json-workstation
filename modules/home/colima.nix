{ pkgs, lib, config, ... }:

let
  cfg = config.programs.colima;
in
{
  options.programs.colima = {
    enable = lib.mkEnableOption "managed ~/.colima/default/colima.yaml";

    configFile = lib.mkOption {
      type = lib.types.path;
      description = ''
        Path to the colima.yaml that should be installed at
        ~/.colima/default/colima.yaml. Edit the file in the repo, run
        `update`, then `colima restart` to apply.
      '';
      example = lib.literalExpression "./colima.yaml";
    };
  };

  config = lib.mkIf cfg.enable {
    # colima rewrites this file in place on start (normalizing comments and
    # defaults), so we install a writable copy instead of a read-only symlink
    # into the Nix store. Our values are reapplied on every switch; colima's
    # in-place normalizations live until the next switch.
    home.activation.colimaConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      $DRY_RUN_CMD install -d -m 0755 ${config.home.homeDirectory}/.colima/default
      $DRY_RUN_CMD install -m 0644 ${cfg.configFile} ${config.home.homeDirectory}/.colima/default/colima.yaml
    '';
  };
}
