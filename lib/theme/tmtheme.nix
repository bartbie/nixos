{
  lib,
  final,
  ...
}:
let
  inherit (final) theme;
  c = theme.termcolors.simple;
  p = theme.palette;

  mk =
    name: scope: settings:
    lib.mergeAttrsList [
      (lib.optionalAttrs (name != null) { inherit name; })
      (lib.optionalAttrs (scope != null) { inherit scope; })
      { inherit settings; }
    ];

  raw = {
    name = "Kanagawa";
    uuid = "592FC036-6BB7-4676-A2F5-2894D48C8E33";
    colorSpaceName = "sRGB";
    semanticClass = "theme.dark.kanagawa";
    settings = [
      (mk null null {
        inherit (theme.mapFGBG c.area.primary)
          background
          foreground
          ;
        caret = c.area.cursor.fg;
        invisibles = p.sumiInk6;
        lineHighlight = p.waveBlue2;
        selection = p.waveBlue2;
        findHighlight = p.waveBlue2;
        selectionBorder = "#222218"; # NOTE: not in palette!
        gutterForeground = p.sumiInk6;
      })
      (mk "Comment" "comment" {
        fontStyle = "italic";
        foreground = c.area.comment;
      })
      (mk "String" "string" {
        foreground = p.springGreen;
      })
      (mk "Number" "constant.numeric" {
        foreground = p.sakuraPink;
      })
      (mk "Built-in constant" "constant.language" {
        foreground = p.surimiOrange;
      })
      (mk "User-defined constant" [ "constant.character" "constant.other" ] {
        foreground = p.carpYellow;
      })
      (mk "Variable" "variable" {
        fontStyle = p.carpYellow;
      })
      (mk "Ruby's @variable" "variable.other.readwrite.instance" {
        fontStyle = "";
        foreground = p.carpYellow;
      })
      (mk "String interpolation"
        [
          "constant.character.escaped"
          "constant.character.escape"
          "string source"
          "string source.ruby"
        ]
        {
          fontStyle = "";
          foreground = p.boatYellow2;
        }
      )
      (mk "Keyword" "keyword" {
        foreground = p.oniViolet;
      })
      (mk "Storage" "storage" {
        fontStyle = "";
        foreground = p.oniViolet;
      })
      (mk "Storage type" "storage.type" {
        foreground = p.oniViolet;
      })
      (mk "Class name" "entity.name.class" {
        foreground = p.waveAqua2;
      })
      (mk "Inherited class" "entity.other.inherited-class" {
        foreground = p.waveAqua2;
      })
      (mk "Function name" "entity.name.function" {
        fontStyle = "";
        foreground = p.crystalBlue;
      })
      (mk "Function argument" "variable.parameter" {
        foreground = p.oniViolet2;
      })
      (mk "Tag name" "entity.name.tag" {
        fontStyle = "";
        foreground = p.springBlue;
      })
      (mk "Tag attribute" "entity.other.attribute-name" {
        fontStyle = "";
        foreground = p.carpYellow;
      })
      (mk "Library function" "support.function" {
        fontStyle = "";
        foreground = p.springBlue;
      })
      (mk "Library constant" "support.constant" {
        fontStyle = "";
        foreground = p.springBlue;
      })
      (mk "Library class/type" [ "support.type" "support.class" ] {
        foreground = p.waveAqua2;
      })
      (mk "Library variable" "support.other.variable" {
        foreground = p.surimiOrange;
      })
      (mk "Invalid" "invalid" {
        fontStyle = "";
        foreground = p.peachRed;
      })
      (mk "Invalid deprecated" "invalid.deprecated" {
        foreground = p.katanaGray;
      })
      (mk "JSON String" "meta.structure.dictionary.json string.quoted.double.json" {
        foreground = p.oniViolet;
      })
      (mk "diff.header" [ "meta.diff" "meta.diff.header" ] {
        foreground = p.crystalBlue;
      })
      (mk "diff.deleted" "markup.deleted" {
        background = p.winterRed;
      })
      (mk "diff.inserted" "markup.inserted" {
        background = p.winterGreen;
      })
      (mk "diff.changed" "markup.changed" {
        background = p.winterYellow;
      })
      (mk null "constant.numeric.line-number.find-in-files - match" {
        foreground = p.sumiInk6;
      })
      (mk null "entity.name.filename" {
        foreground = p.oldWhite;
      })
      (mk null "message.error" {
        foreground = p.lotusRed3;
      })
      (mk "JSON Punctuation"
        [
          "punctuation.definition.string.begin.json - meta.structure.dictionary.value.json"
          "punctuation.definition.string.end.json - meta.structure.dictionary.value.json"
        ]
        {
          foreground = p.springViolet2;
        }
      )
      (mk "JSON Structure" "meta.structure.dictionary.json string.quoted.double.json" {
        foreground = p.oniViolet;
      })
      (mk "JSON String" "meta.structure.dictionary.value.json string.quoted.double.json" {
        foreground = "#ffffff"; # NOTE: not in palette!
      })
      (mk "Regular Expressions" "string.regexp" {
        foreground = p.carpYellow;
      })
      (mk "Escape Characters" "constant.character.escape" {
        foreground = p.peachRed;
      })
    ];
  };

  plist = lib.generators.toPlist { } raw;
in
{
  inherit raw plist;
  writeTmTheme = pkgs: pkgs.writeText "kanagawa.tmTheme" plist;
}
