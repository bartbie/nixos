{
  config,
  lib,
  pkgs,
  options,
  ...
}: let
  inherit (lib) mkEnableOption;
  cfg = config.nixon.packages;
in {
  options.nixon.packages = {
    enable = mkEnableOption "packages";
  };
  config = lib.mkIf cfg.enable {
    environment.systemPackages = builtins.attrValues pkgs.systemPackages;
  };
}
