{
  config,
  lib,
  pkgs,
  options,
  ...
}: let
  inherit (lib) mkEnableOption;
  cfg = config.nixon.wayland;
in {
  options.nixon.wayland = {
    enable = mkEnableOption "wayland";
  };
  config = lib.mkIf cfg.enable {
    hardware.graphics.enable = true;
    environment.sessionVariables = {
      NIXOS_OZONE_WL = "1";
    };

    xdg.portal = {
      enable = true;
      extraPortals = [pkgs.xdg-desktop-portal-gtk];
      xdgOpenUsePortal = true;
      config = {
        common.default = ["gtk"];
        hyprland.default = ["hyprland" "gtk"];
      };
    };
  };
}
