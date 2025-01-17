{
  config,
  lib,
  pkgs,
  options,
  ...
}: let
  inherit (lib) mkOption types;
  cfg = config.user.audio;
in {
  options.user.audio = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Whether to enable audio system configuration.";
    };
    bluetooth.enable = mkOption {
      type = types.bool;
      default = false;
      description = "Whether to enable audio system configuration.";
    };
  };
  config = lib.mkIf cfg.enable {
    security.rtkit.enable = true;
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      jack.enable = true;
    };
  };
  hardware.bluetooth = lib.mkIf cfg.bluetooth.enable {
    enable = true;
    powerOnBoot = false;
  };
}
