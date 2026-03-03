{
  flake.modules.nixos.wayland =
    { pkgs, ... }:
    {
      hardware.graphics.enable = true;
      environment.sessionVariables = {
        NIXOS_OZONE_WL = "1";
      };

      xdg.portal = {
        enable = true;
        extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
        xdgOpenUsePortal = true;
        config = {
          common.default = [ "gtk" ];
          hyprland.default = [
            "hyprland"
            "gtk"
          ];
        };
      };
    };
}
