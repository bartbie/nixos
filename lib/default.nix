# TODO: split lib into smaller files
{lib}: let
  lib-inputs = {inherit lib final;};

  filterFnNonNix = f: (f.hasExt "nix") && !(lib.hasPrefix "_" f.name);

  mkUnstableOverlay = inputs: (final: _: {
    unstable = import inputs.nixpkgs-unstable {
      inherit (final) system config;
    };
  });

  eachSystemPkgs = inputs: overlays: f: let
    eachSystem = lib.genAttrs (import inputs.systems);
    mkPkgs = system: (import inputs.nixpkgs {inherit system overlays;});
  in
    eachSystem (system: f (mkPkgs system));

  final = {
    inherit
      eachSystemPkgs
      filterFnNonNix
      mkUnstableOverlay
      ;

    findImportDirs = root: ignored: let
      fs = lib.fileset;
    in
      lib.pipe root [
        builtins.readDir
        (lib.attrsets.filterAttrs (n: v: v == "directory" && !(lib.hasPrefix "_" n)))
        builtins.attrNames
        (builtins.map (d: root + /${d}/default.nix))
        fs.unions
        (fs.intersection (fs.fileFilter filterFnNonNix root))
        (x: fs.difference x (fs.unions ignored))
        fs.toList
      ];

    findImports = this: ignore: let
      fs = lib.fileset;
      root = builtins.dirOf this;
      ignored = [this] ++ (lib.flatten ignore);
    in
      lib.pipe root [
        (fs.fileFilter filterFnNonNix)
        (x: fs.difference x (fs.unions ignored))
        fs.toList
      ];

    boolToStringFlag = b:
      if b
      then "1"
      else "0";

    mkModprobeConfig = let
      # TODO: this only adds `options`, either rename or expand
      at = lib.attrsets;
      concat = lib.flip lib.pipe [
        (lib.concatStringsSep " ")
        lib.trim
      ];
    in
      lib.flip lib.pipe [
        (at.mapAttrs (_: concat))
        (at.filterAttrs (_: v: v != ""))
        (at.mapAttrsToList (n: v: "options ${n} ${v}"))
        lib.concatLines
      ];

    modulesPath = ../modules;
    libPath = ./.;
    scriptsPath = ../scripts;

    theme = import ./theme lib-inputs;

    nullish = cond: x:
      if cond
      then x
      else null;

    headOrNull = x: final.nullish (x != []) (builtins.head x);

    last = x: builtins.head (lib.reverseList x);

    lastOrNull = x: final.nullish (x != []) (final.last x);

    mapCond = cond-fn: map-fn:
      builtins.map (v:
        if (cond-fn v)
        then (map-fn v)
        else v);

    mapAttrsCond = cond-fn: map-fn:
      builtins.mapAttrs (n: v:
        if (cond-fn n v)
        then (map-fn n v)
        else v);

    filterMapAttrsRecursive = leaf-fn: filter-fn: map-fn: let
      mark = {_bartbie_remove = null;};
      marked = x: x ? _bartbie_remove;
    in
      lib.flip lib.pipe [
        (
          lib.attrsets.mapAttrsRecursiveCond leaf-fn
          (p: v: (
            if (filter-fn p v)
            then (map-fn p v)
            else mark
          ))
        )
        (lib.filterAttrsRecursive (n: v: !(marked v)))
      ];

    mkIfElse = cond: x: y:
      lib.mkMerge [
        (lib.mkIf cond x)
        (lib.mkIf (!cond) y)
      ];
  };
in
  final
