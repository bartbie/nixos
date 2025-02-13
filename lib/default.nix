{lib}: let
  wrapInList = x:
    if lib.isList x
    then x
    else [x];
in {
  inherit wrapInList;

  findImports = this: ignore: let
    fs = lib.fileset;
    filterNonNix = f: (f.hasExt "nix") && !(lib.hasPrefix "_" f.name);
    root = builtins.dirOf this;
    ignored = [this] ++ (wrapInList ignore);
  in
    fs.toList (fs.difference (fs.fileFilter filterNonNix root) (fs.unions ignored));
}
