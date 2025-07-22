{
  config,
  lib,
  pkgs,
  options,
  ...
}: let
  inherit (lib) mkEnableOption;
  cfg = config.nixon.security;
in {
  options.nixon.security = {
    enable = mkEnableOption "security";
  };
  config = lib.mkIf cfg.enable {
    security = {
      polkit.enable = true;
      rtkit.enable = true;
      protectKernelImage = false;
    };
  };
}
