{
  config,
  lib,
  pkgs,
  options,
  ...
}: let
  inherit (lib) mkEnableOption;
  cfg = config.nixon.programs._TEMPLATE;
in {
  options.nixon.programs._TEMPLATE = {
    enable = mkEnableOption "_TEMPLATE";
  };
  config =
    lib.mkIf cfg.enable {
    };
}
