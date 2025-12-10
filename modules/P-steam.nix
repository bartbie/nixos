{
  flake.modules.nixos.pc = {pkgs, ...}: {
    programs = {
      steam.enable = true;
      steam.gamescopeSession.enable = true;
      gamemode.enable = true;
    };
    environment.systemPackages = builtins.attrValues {
      inherit
        (pkgs)
        mangohud
        protonup-ng
        protonup-qt
        ;
      bottles = pkgs.bottles.override {removeWarningPopup = true;};
    };
    environment.sessionVariables = {
      STEAM_EXTRA_COMPAT_TOOLS_PATH = "$HOME/.steam/root/compatibilitytools.d";
    };
  };
}
