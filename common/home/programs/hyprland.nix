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
    wayland.windowManager.hyprland = {
      enable = true;
      package = pkgs.hyprland.override {
        enableNvidiaPatches = nvidia;
      };
    };
    home.sessionVariables = {
      # If your cursor becomes invisible
      WLR_NO_HARDWARE_CURSORS = "1";
      # Hint electron apps to use wayland
      NIXOS_OZONE_WL = "1";
    };
  };
}
