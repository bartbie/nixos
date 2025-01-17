{
  config,
  lib,
  pkgs,
  options,
  ...
}: let
  inherit (lib) mkOption types;
  cfg = config.user.plasma5;
in {
  options.user = {
    plasma5.enable = mkOption {
      type = types.bool;
      default = false;
      description = "Whether to enable plasma5 system configuration.";
    };
  };
  config = lib.mkIf cfg.enable {
    services.xserver.displayManager.sddm.enable = true;
    services.xserver.desktopManager.plasma5.enable = true;
  };
}
