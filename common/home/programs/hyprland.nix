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
    inherit (pkgs) unstable;
  in {
    wayland.windowManager.hyprland = {
      enable = true;
      package = unstable.hyprland.override {
        enableNvidiaPatches = nvidia;
      };
      settings = {
        "$mod" = "SUPER";
      };
    };

    programs.hyprlock = {
      enable = true;
      package = unstable.hyprlock;
    };
    services.hypridle = {
      enable = true;
      package = unstable.hypridle;
    };
    services.hyprpaper = {
      enable = true;
      package = unstable.hyprpaper;
    };
    services.mako.enable = true;
  };
}
