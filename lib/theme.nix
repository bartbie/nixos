{lib}: let
  /*
  color_01: '#090618'    # Black (Host)
  color_02: '#C34043'    # Red (Syntax string)
  color_03: '#76946A'    # Green (Command)
  color_04: '#C0A36E'    # Yellow (Command second)
  color_05: '#7E9CD8'    # Blue (Path)
  color_06: '#957FB8'    # Magenta (Syntax var)
  color_07: '#6A9589'    # Cyan (Prompt)
  color_08: '#C8C093'    # White

  color_09: '#727169'    # Bright Black
  color_10: '#E82424'    # Bright Red (Command error)
  color_11: '#98BB6C'    # Bright Green (Exec)
  color_12: '#E6C384'    # Bright Yellow
  color_13: '#7FB4CA'    # Bright Blue (Folder)
  color_14: '#938AA9'    # Bright Magenta
  color_15: '#7AA89F'    # Bright Cyan
  color_16: '#DCD7BA'    # Bright White

  background: '#1F1F28'  # Background
  foreground: '#DCD7BA'  # Foreground (Text)

  cursor: '#DCD7BA'      # Cursor
  */
  _all = {
    ansi = {
      Black = {
        hex = "#090618";
        id = 1;
      };
      Red = {
        hex = "#C34043";
        id = 2;
      };
      Green = {
        hex = "#76946A";
        id = 3;
      };
      Yellow = {
        hex = "#C0A36E";
        id = 4;
      };
      Blue = {
        hex = "#7E9CD8";
        id = 5;
      };
      Magenta = {
        hex = "#957FB8";
        id = 6;
      };
      Cyan = {
        hex = "#6A9589";
        id = 7;
      };
      White = {
        hex = "#C8C093";
        id = 8;
      };
    };
    brights = {
      "Bright Black" = {
        hex = "#727169";
        id = 9;
      };
      "Bright Red" = {
        hex = "#E82424";
        id = 10;
      };
      "Bright Green" = {
        hex = "#98BB6C";
        id = 11;
      };
      "Bright Yellow" = {
        hex = "#E6C384";
        id = 12;
      };
      "Bright Blue" = {
        hex = "#7FB4CA";
        id = 13;
      };
      "Bright Magenta" = {
        hex = "#938AA9";
        id = 14;
      };
      "Bright Cyan" = {
        hex = "#7AA89F";
        id = 15;
      };
      "Bright White" = {
        hex = "#DCD7BA";
        id = 16;
      };
    };
    # stuff that idk if should have id used by terminals etc
    rest = {
      "Orange" = {
        hex = "#FFA066";
      };
      "Pink" = {
        hex = "#7AA89F";
      };
    };
  };
  mapColors = fn:
    lib.attrsets.mapAttrs (lib.attrsets.mapAttrs fn);
  mapColors' = fn:
    lib.attrsets.mapAttrs (lib.attrsets.mapAttrs' fn);

  flattenColors = lib.attrsets.mapAttrsToList (_: lib.id);
  colors = {
    inherit _all;
    _without-rest = _all.ansi // _all.brights;

    by-name = mapColors (_: v: v.hex) _all;
    by-index = mapColors' (n: v: lib.nameValuePair (builtins.toString v.id) v.hex) colors._without-rest;
    by-name-flat = flattenColors colors.by-name;
    by-index-flat = flattenColors colors.by-index;
  };
in {
  inherit
    mapColors
    mapColors'
    flattenColors
    colors
    ;
}
