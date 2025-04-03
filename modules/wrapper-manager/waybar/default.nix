{
  pkgs,
  lib,
  ...
}: {
  wrappers.waybar = {
    arg0 = lib.getExe' pkgs.waybar "waybar";
    prependArgs = [];
  };
}
