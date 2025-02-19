{
  self,
  nixpkgs,
  wrapper-manager,
  ...
}: pkgs: let
  inherit (nixpkgs) lib;
  fs = lib.fileset;

  importDirs = root: ignored:
    lib.pipe root [
      builtins.readDir
      (lib.attrsets.filterAttrs (n: v: v == "directory" && !(lib.hasPrefix "_" n)))
      builtins.attrNames
      (builtins.map (d: root + /${d}/default.nix))
      fs.unions
      (fs.intersection (fs.fileFilter self.lib.filterFnNonNix root))
      (x: fs.difference x (fs.unions ignored))
      fs.toList
    ];

  wrapped = let
    modules = importDirs ./wrapped [];
  in
    (wrapper-manager.lib.eval {inherit pkgs modules;}).config.build.packages;

  scripts = {};
in
  scripts // wrapped
