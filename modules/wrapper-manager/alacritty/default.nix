{
  pkgs,
  lib,
  theme,
  flake,
  ...
}: let
  colors = let
    inherit (theme.termcolors) simple;
  in {
    primary = theme.mapFGBG simple.area.primary;
    selection = theme.mapFGBG simple.area.selection;
    normal = simple.ansi;
    bright = simple.brights;
    indexed_colors =
      lib.attrsets.mapAttrsToList (n: v: {
        index = lib.toInt n;
        color = v;
      })
      simple.indexed;
  };
  config = {
    inherit colors;
  };
in {
  wrappers.alacritty = {
    arg0 = lib.getExe' pkgs.alacritty "alacritty";
    prependArgs = [
      "--config-file"
      ((pkgs.formats.toml {}).generate "alacritty.toml" config)
    ];
  };
}
