{lib, ...}: let
  common = {
    pkgs,
    pkgs-unstable,
    theme,
    ...
  }: {
    single = {
      package = pkgs-unstable.bat;
      wrapper = {
        env = {
          BAT_CONFIG_DIR.value = pkgs.writeTextDir "/themes/kanagawa.tmTheme" theme.tm-theme.plist;
          BAT_THEME.value = "kanagawa";
        };
      };
    };
  };
in {
  wrapped.bat = {
    tags = null;
    module = {
      imports = [common];
      single.programName = "bat";
    };
  };
  wrapped.cat = {
    tags = null;
    module = {
      imports = [common];
      single.programName = "cat";
    };
  };
}
