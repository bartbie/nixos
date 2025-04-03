{
  config,
  lib,
  pkgs,
  options,
  ...
}: let
  inherit (lib) mkEnableOption;
  cfg = config.nixon.programs.hypr;
in {
  options.nixon.programs.hypr = {
    enable = mkEnableOption "hypr";
  };
  config = lib.mkIf cfg.enable {
    programs.hyprland.enable = true;
  };
}
