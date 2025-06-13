{
  lib,
  final,
  ...
}: {
  findImportDirs = root: ignored: let
    fs = lib.fileset;
  in
    lib.pipe root [
      builtins.readDir
      (lib.attrsets.filterAttrs (n: v: v == "directory" && !(lib.hasPrefix "_" n)))
      builtins.attrNames
      (builtins.map (d: root + /${d}/default.nix))
      fs.unions
      (fs.intersection (fs.fileFilter final.isNixFile root))
      (x: fs.difference x (fs.unions ignored))
      fs.toList
    ];

  findImports = this: ignore: let
    fs = lib.fileset;
    root = builtins.dirOf this;
    ignored = [this] ++ (lib.flatten ignore);
  in
    lib.pipe root [
      (fs.fileFilter final.isNixFile)
      (x: fs.difference x (fs.unions ignored))
      fs.toList
    ];

  isNixFile = f: (f.hasExt "nix") && !(lib.hasPrefix "_" f.name);
}
