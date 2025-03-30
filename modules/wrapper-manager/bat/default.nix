{
  pkgs,
  lib,
  wrapperManagerLib,
  flake,
  ...
}: let
  prefix = "share/bat/config";
  theme = pkgs.writeTextDir "${prefix}/themes/kanagawa.tmTheme" flake.lib.theme.tm-theme.plist;

  symlinked = pkgs.symlinkJoin {
    name = "bat-config";
    paths = [theme];
  };

  bat = {
    arg0 = lib.getExe' pkgs.unstable.bat "bat";
    env = {
      BAT_CONFIG_DIR.value = "${symlinked}/${prefix}";
      BAT_THEME.value = "kanagawa";
    };
  };
in {
  wrappers = {
    inherit bat;
    cat = bat;
  };
}
