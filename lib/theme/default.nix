{lib, ...} @ inputs: let
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
  palette = import ./palette.nix inputs;

  colorWithId = hex: id: {inherit hex id;};
  color = hex: {inherit hex;};

  colorsToList = lib.flip lib.pipe [
    lib.attrsToList
    (builtins.map (x: {
      inherit (x) value;
      name = lib.toInt x.name;
    }))
    (builtins.sort (x: y: x.name < y.name))
    (builtins.map (x: x.value))
  ];

  _all = {
    ansi = {
      Black = colorWithId "#090618" 1;
      Red = colorWithId palette.autumnRed 2;
      Green = colorWithId palette.autumnGreen 3;
      Yellow = colorWithId palette.boatYellow2 4;
      Blue = colorWithId palette.crystalBlue 5;
      Magenta = colorWithId palette.oniViolet 6;
      Cyan = colorWithId palette.waveAqua1 7;
      White = colorWithId palette.oldWhite 8;
    };
    brights = {
      "Bright Black" = colorWithId palette.fujiGray 9;
      "Bright Red" = colorWithId palette.lotusRed3 10;
      "Bright Green" = colorWithId palette.springGreen 11;
      "Bright Yellow" = colorWithId palette.carpYellow 12;
      "Bright Blue" = colorWithId palette.springBlue 13;
      "Bright Magenta" = colorWithId palette.springViolet1 14;
      "Bright Cyan" = colorWithId palette.waveAqua2 15;
      "Bright White" = colorWithId palette.fujiWhite 16;
    };
    # stuff that idk if should have id used by terminals etc
    rest = {
      "Orange" = color palette.surimiOrange;
      "Pink" = color palette.sakuraPink;
      "Peach Red" = color palette.peachRed;
      "selection background" = color palette.waveBlue1;
      "split" = color palette.sumiInk0;
      background = color palette.sumiInk3;
      foreground = _all.brights."Bright White";
    };
  };
  mapColors = fn:
    lib.attrsets.mapAttrs (_: lib.attrsets.mapAttrs fn);
  mapColors' = fn:
    lib.attrsets.mapAttrs (_: lib.attrsets.mapAttrs' fn);

  flattenColors = lib.flip lib.pipe [
    builtins.attrValues
    (builtins.foldl' (acc: elem: acc // elem) {})
  ];

  colors = {
    inherit _all;
    _without-rest = _all.ansi // _all.brights;

    by-name = mapColors (_: v: v.hex) _all;
    by-index = mapColors' (n: v: lib.nameValuePair (builtins.toString v.id) v.hex) {inherit (_all) ansi brights;};
    by-name-flat = flattenColors colors.by-name;
    by-index-flat = flattenColors colors.by-index;
    list = lib.attrsets.mapAttrs (_: colorsToList) colors.by-index;
  };
in {
  inherit
    mapColors
    mapColors'
    flattenColors
    colors
    palette
    ;
}
