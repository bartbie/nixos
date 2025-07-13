{
  config,
  lib,
  pkgs,
  options,
  ...
}: let
  inherit (lib) mkEnableOption;
  cfg = config.nixon.boot;
in {
  options.nixon.boot = {
    enable = mkEnableOption "boot";
  };
  config = lib.mkIf cfg.enable {
    boot = {
      loader = {
        systemd-boot = {
          enable = lib.mkDefault true;
          configurationLimit = 10;
        };
      };

      kernelPackages = lib.mkDefault pkgs.linuxPackages_latest;
    };
  };
}
