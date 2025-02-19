{
  config,
  lib,
  pkgs,
  options,
  ...
}: let
  inherit (lib) mkEnableOption;
  cfg = config.nixon.programs.starship;
in {
  options.nixon.programs.starship = {
    enable = mkEnableOption "starship";
  };
  config = lib.mkIf cfg.enable {
    programs.starship = {
      package = pkgs.nixon.starship;
      enable = true;
    };
  };
}
