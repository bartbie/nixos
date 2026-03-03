{
  lib,
  final,
  ...
}:
let
  inherit (lib) types;

  fnStr = name: arg: "${name}(${arg})";

  # Unique submodule that maps itself
  mappedUniqSubmodule =
    submoduleType: fn:
    let
      sub = types.uniq submoduleType;
    in
    lib.mkOptionType {
      name = "mappedUniqSubmodule";
      description = "Unique submodule that maps itself";
      descriptionClass = "noun";
      check = sub.check;
      merge =
        loc: defs:
        defs
        # Merge as submodule first
        |> sub.merge loc
        # Then map
        |> fn;
      substSubModules = m: sub (sub.substSubModules m);
    };

  typed = type: lib.mkOption { inherit type; };
  typedOpt = t: typed (types.nullOr t) // { default = null; };

  typedApply = type: apply: lib.mkOption { inherit type apply; };

  addLenCheck = len: type: types.addCheck type (s: builtins.stringLength s == len);

  hexTypeWith =
    x:
    types.coercedTo (types.strMatching "#?[0-9a-fA-F]${x}") (
      s: s |> (lib.removePrefix "#") |> lib.toLower |> (a: "#" + a)
    ) (types.strMatching "#[0-9a-f]${x}");
  hexType = hexTypeWith "+";

  hexTypeWithLen = len: hexTypeWith "{${builtins.toString len}}";

  rgbaType = hexTypeWithLen 8;
  rgbType = hexTypeWithLen 6;

  degType = types.ints.unsigned;

  gradientType =
    mappedUniqSubmodule
      (types.submodule {
        options = {
          topColor = typed rgbaType;
          bottomColor = typed rgbaType;
          deg = typed degType;
        };
      })
      (
        {
          topColor,
          bottomColor,
          deg,
        }:
        lib.join " " [
          (topColor |> (lib.removePrefix "#") |> fnStr "rgba")
          (bottomColor |> (lib.removePrefix "#") |> fnStr "rgba")
          (builtins.toString deg + "deg")
        ]
      );

  namedEnum =
    attrs:
    (types.coercedTo (types.enum (builtins.attrNames attrs)) (x: attrs.${x}) (
      types.enum (builtins.attrValues attrs)
    ));
  namedEnumList =
    l: l |> lib.imap0 (i: v: lib.nameValuePair v i) |> builtins.listToAttrs |> namedEnum;

  coercedStr = types.coercedTo (types.oneOf [
    types.bool
    types.int
    types.str
    types.package
  ]) (x: if (builtins.typeOf x) == "bool" then lib.boolToString x else builtins.toString x) types.str;

  # extra bins to package with in env
  getExe =
    x:
    assert x ? meta;
    assert x.meta ? mainProgram;
    lib.getExe' x x.meta.mainProgram;

  hjkl-ldur =
    let
      mapping = {
        h = "l";
        j = "d";
        k = "u";
        l = "r";
      };
    in
    fn: lib.mapAttrsToList fn mapping;

  mapRange =
    from: to: fn:
    lib.range from to |> builtins.map fn;

  mapRowRange =
    from: to: fn:
    assert from >= 1;
    assert from <= 10;
    assert to <= 10;
    assert from <= to;
    mapRange from to (n: fn (lib.mod n 10) n);
  mapRow = mapRowRange 1 10;

  coercedToList = type: types.coercedTo type (x: [ x ]) (types.listOf type);

  toString = v: if builtins.isBool v then lib.boolToString v else builtins.toString v;

  enumAliased =
    mapping:
    let
      # { hyprVal = [ nixAlias... ] }
      # empty list → hyprVal itself is the only valid nix name
      normalized = lib.concatMapAttrs (
        hypr: aliases:
        let
          keys = if aliases == [ ] then [ hypr ] else aliases;
        in
        lib.genAttrs keys (_: hypr)
      ) mapping;
    in
    lib.mkOptionType {
      name = "enumAliased";
      description = "one of ${lib.concatStringsSep ", " (builtins.attrNames normalized)}";
      check = v: builtins.hasAttr v normalized;
      merge =
        loc: defs:
        let
          v = lib.mergeEqualOption loc defs;
        in
        normalized.${v};
    };

  mkSubmodule = final.dag.submoduleTypeWith;
in
{
  inherit
    mappedUniqSubmodule
    mkSubmodule
    typed
    typedOpt
    typedApply
    addLenCheck
    hexType
    hexTypeWithLen
    rgbaType
    rgbType
    degType
    gradientType
    getExe
    hjkl-ldur
    mapRange
    mapRow
    mapRowRange
    fnStr
    namedEnum
    namedEnumList
    coercedStr
    coercedToList
    toString
    enumAliased
    ;
}
