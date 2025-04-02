{
  config,
  lib,
  pkgs,
  options,
  ...
}: let
  inherit (lib) mkEnableOption;
  cfg = config.nixon._TEMPLATE;
in {
  options.nixon._TEMPLATE = {
    enable = mkEnableOption "_TEMPLATE";
  };
  config =
    lib.mkIf cfg.enable {
    };
}
