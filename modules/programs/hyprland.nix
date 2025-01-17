{
  config,
  lib,
  pkgs,
  options,
  ...
}: let
  inherit (lib) mkOption types;
  cfg = config.user.hypr;
in {
  options.user = {
    hypr.enable = mkOption {
      type = types.bool;
      default = false;
      description = "Whether to enable hypr system configuration.";
    };
  };
  config = lib.mkIf cfg.enable {
    hardware.opengl.enable = true;
    hardware.nvidia.modesetting.enable = nvidia;

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
