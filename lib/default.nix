{lib}: let
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
in {
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
}
