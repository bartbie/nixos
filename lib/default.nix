{lib}: let
  wrapInList = x:
    if lib.isList x
    then x
    else [x];

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
    wrapInList
    filterFnNonNix
    mkUnstableOverlay
    ;

  findImports = this: ignore: let
    fs = lib.fileset;
    root = builtins.dirOf this;
    ignored = [this] ++ (wrapInList ignore);
  in
    fs.toList (fs.difference (fs.fileFilter filterFnNonNix root) (fs.unions ignored));

  eachSystemPkgsFull = inputs: eachSystemPkgs inputs [inputs.self.overlays._dependencies];
  boolToStringFlag = b:
    if b
    then "1"
    else "0";

  mkModprobeConfig = let
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
