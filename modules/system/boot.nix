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
      kernelPackages = lib.mkDefault pkgs.linuxPackages_6_12;
      loader.systemd-boot = {
        configurationLimit = 10;
      };
    };
  };
}
