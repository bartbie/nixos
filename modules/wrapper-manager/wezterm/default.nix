{
  pkgs,
  lib,
  ...
}: {
  wrappers.wezterm = {
    arg0 = lib.getExe' pkgs.unstable.wezterm "wezterm";
    env.WEZTERM_CONFIG_FILE.value = "${./wezterm.lua}";
  };
}
