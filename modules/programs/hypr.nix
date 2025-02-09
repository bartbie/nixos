{
  config,
  lib,
  pkgs,
  options,
  ...
}: let
  inherit (lib) mkEnableOption;
  cfg = config.nixon.hypr;
in {
  options.nixon.hypr = {
    enable = mkEnableOption "hypr";
    nvidia.enable = mkEnableOption "nvidia";
  };
  config = lib.mkIf cfg.enable {
    hardware.opengl.enable = true;
    hardware.nvidia.modesetting.enable = cfg.nvidia.enable;

    environment.sessionVariables = {
      # If your cursor becomes invisible
      WLR_NO_HARDWARE_CURSORS = "1";
      # Hint electron apps to use wayland
      NIXOS_OZONE_WL = "1";
    };

    xdg.portal = {
      enable = true;
      extraPortals = [pkgs.xdg-desktop-portal-gtk];
      xdgOpenUsePortal = true;
      config = {
        common.default = ["gtk"];
        hyprland.default = ["gtk" "hyprland"];
      };
    };

    # enable hyprlock to perform authentication
    security.pam.services.hyprlock = {};
  };
}
