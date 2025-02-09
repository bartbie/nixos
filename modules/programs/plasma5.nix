{
  config,
  lib,
  pkgs,
  options,
  ...
}: let
  inherit (lib) mkEnableOption;
  cfg = config.nixon.plasma5;
in {
  options.nixon = {
    plasma5.enable = mkEnableOption "plasma5";
  };
  config = lib.mkIf cfg.enable {
    services.xserver.displayManager.sddm.enable = true;
    services.xserver.desktopManager.plasma5.enable = true;
  };
}
