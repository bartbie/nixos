{
  lib,
  final,
  ...
} @ inputs: let
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

  # mapColors = fn:
  #   lib.attrsets.mapAttrs (_: lib.attrsets.mapAttrs fn);
  mapColors' = fn:
    lib.attrsets.mapAttrs (_: lib.attrsets.mapAttrs' fn);

  # flattenColors = lib.flip lib.pipe [
  #   builtins.attrValues
  #   (builtins.foldl' (acc: elem: acc // elem) {})
  # ];

  joinAB = as: as.ansi // as.brights;
  pickAB = as: {inherit (as) ansi brights;};

  # name -> "#hex"
  mapHex = let
    mapA = lib.flip lib.pipe [
      (final.filterMapAttrsRecursive
        (as: as ? "hex" -> (builtins.isAttrs as.hex))
        (_: v: (v ? "hex"))
        (_: v: v.hex))
    ];
  in
    x:
      if builtins.isAttrs x
      then (mapA {inherit x;}).x or {}
      else builtins.map mapHex x;

  mapHex' = let
    mapA = lib.flip lib.pipe [
      (final.filterMapAttrsRecursive
        (as: as ? "hex" -> (builtins.isAttrs as.hex))
        (_: _: true)
        (_: v:
          if (v ? "hex")
          then v.hex
          else v))
    ];
  in
    x:
      if builtins.isAttrs x
      then (mapA {inherit x;}).x or {}
      else builtins.map mapHex x;

  colorsToList = lib.flip lib.pipe [
    builtins.attrValues
    (builtins.sort (x: y: x.id < y.id))
    mapHex
  ];

  mapFGBG = {
    fg ? null,
    bg ? null,
    ...
  }:
    lib.mergeAttrsList [
      (lib.optionalAttrs (fg != null) {foreground = fg;})
      (lib.optionalAttrs (bg != null) {background = bg;})
    ];

  raw = {
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
    indexed = {
      "16" = raw.rest.Orange;
      "17" = raw.rest."Peach Red";
    };
    area = {
      primary = {
        bg = color palette.sumiInk3;
        fg = raw.brights."Bright White";
      };
      selection = {
        bg = color palette.waveBlue1;
      };
      cursor = {
        bg = raw.ansi.White;
        fg = raw.ansi.White;
        border = raw.ansi.White;
      };
      comment = raw.brights."Bright Black";
      split = color palette.sumiInk0;
      scrollbar = {
        thumb = raw.area.split;
      };
    };
    rest = {
      "Orange" = color palette.surimiOrange;
      "Pink" = color palette.sakuraPink;
      "Peach Red" = color palette.peachRed;
    };
  };

  termcolors = {
    inherit raw;
    simple = lib.mergeAttrsList [
      termcolors.hex
      {inherit (termcolors.ab) lists;}
      (mapHex' termcolors.ab.renamed)
    ];
    hex = mapHex' termcolors.raw;
    ab = {
      joined = joinAB termcolors.raw;
      by-index = mapColors' (name: v: lib.nameValuePair (builtins.toString v.id) (v // {inherit name;})) (pickAB termcolors.raw);
      lists = lib.attrsets.mapAttrs (_: colorsToList) (pickAB termcolors.raw);
      renamed = let
        rename = lib.flip lib.pipe [
          (lib.strings.splitString " ")
          final.last
          lib.toLower
        ];
      in
        mapColors' (n: v: lib.nameValuePair (rename n) v) (pickAB termcolors.raw);
    };
  };
in {
  inherit
    mapFGBG
    joinAB
    pickAB
    mapHex
    mapColors'
    termcolors
    palette
    ;
}
