{
  config,
  lib,
  pkgs,
  options,
  ...
}: let
  inherit (lib) mkEnableOption;
  cfg = config.nixon.programs.steam;
in {
  options.nixon.programs.steam = {
    enable = mkEnableOption "steam";
  };
  config = lib.mkIf cfg.enable {
    programs = {
      steam.enable = true;
      steam.gamescopeSession.enable = true;
      gamemode.enable = true;
    };
    environment.systemPackages = builtins.attrValues {
      inherit
        (pkgs)
        mangohud
        protonup
        protonup-qt
        ;
      bottles = pkgs.bottles.override {removeWarningPopup = true;};
    };
    environment.sessionVariables = {
      STEAM_EXTRA_COMPAT_TOOLS_PATH = "$HOME/.steam/root/compatibilitytools.d";
    };
  };
}
