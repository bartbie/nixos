{lib}: let
  wrapInList = x:
    if lib.isList x
    then x
    else [x];

  filterFnNonNix = f: (f.hasExt "nix") && !(lib.hasPrefix "_" f.name);
in {
  inherit
    wrapInList
    filterFnNonNix
    ;

  findImports = this: ignore: let
    fs = lib.fileset;
    root = builtins.dirOf this;
    ignored = [this] ++ (wrapInList ignore);
  in
    fs.toList (fs.difference (fs.fileFilter filterFnNonNix root) (fs.unions ignored));

  mkUnstableOverlay = inputs: (final: _: {
    unstable = import inputs.nixpkgs-unstable {
      inherit (final) system config;
    };
  });
}
