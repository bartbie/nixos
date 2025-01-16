{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.mine.hyprland;
in {
  options = with lib; {
    mine.hyprland.nvidia = mkOption {
      type = types.bool;
      default = false;
      description = "Enable nvidia support.";
    };
  };
  config = let
    inherit (cfg) nvidia;
  in {
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
