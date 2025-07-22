{
  config,
  lib,
  pkgs,
  options,
  ...
}: let
  inherit (lib) mkEnableOption;
  cfg = config.nixon.programs.gnome-keyring;
in {
  options.nixon.programs.gnome-keyring = {
    enable = mkEnableOption "gnome-keyring";
  };
  config = lib.mkIf cfg.enable {
    services.gnome.gnome-keyring.enable = true;
  };
}
