{
  config,
  lib,
  pkgs,
  options,
  ...
}: let
  inherit (lib) mkOption types;
  cfg = config.user.direnv;
in {
  options.user.direnv = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Whether to enable direnv system configuration.";
    };
  };
  config = lib.mkIf cfg.enable {
    programs.direnv = {
      enable = true;
      nix-direnv.enable = true;
    };
  };
}
