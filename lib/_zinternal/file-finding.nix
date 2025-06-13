/*
To avoid infinite recursion created by findImports we stuff it and listRecursive here
so lib.fs and lib.import can re-export them
*/
{lib, ...}: let
  fs = lib.fileset;

  listRecursive = {
    depth ? -1,
    filter ? (_: true),
  }: dir: let
    _listRecursive = filter: let
      list = dep: dir:
        lib.pipe dir [
          builtins.readDir
          (
            lib.mapAttrsToList (
              name: type: let
                pathname = dir + "/${name}";
                check = filter {
                  inherit name type;
                  parent = dir;
                  hasExt = ext: lib.hasSuffix ".${ext}" name;
                };
                checkOrNull = x:
                  if check
                  then x
                  else null;
              in
                # PERF: check may be more exp than this cond so we do it in branches
                if type == "directory" && dep != 0
                then checkOrNull (list (dep - 1) pathname)
                else checkOrNull pathname
            )
          )
          lib.flatten
          (lib.filter (x: x != null))
        ];
    in
      list;
  in
    _listRecursive filter depth dir;

  ffintersection = fn: path: (fs.intersection (fs.fileFilter fn path));

  ffilters = {
    isImportable = f: (f.hasExt "nix") && !(lib.hasPrefix "_" f.name);
    isNix = f: (f.hasExt "nix");
    isDefaultNix = f: f.name == "default.nix";
  };
in {
  inherit
    listRecursive
    ffilters
    ;

  findImports = {
    from, # can be a folder or a file (it starts from its dir then)
    depth ? 0, # -1 - all, 0 - just contents of this directory, etc.
    ignored ? [], # list of ignored paths
    defaultOnly ? true, # import only folders (i.e default.nix files)
    ignoreFromIfFile ? true, # if from is a file, ignore it
  }: let
    is-file = !lib.pathIsDirectory from;
    ignore = ignored ++ (lib.optional (is-file && ignoreFromIfFile) from);
    root =
      if (!lib.pathIsDirectory from)
      then builtins.dirOf from
      else from;

    ffi = lib.flip ffintersection root;
  in
    lib.pipe root [
      (listRecursive {
        inherit depth;
        filter = x: !lib.hasPrefix "_" x.name;
      })
      fs.unions
      (ffi ffilters.isNix)
      (
        if defaultOnly
        then (ffi ffilters.isDefaultNix)
        else lib.id
      )
      (x: fs.difference x (fs.unions ignore))
      fs.toList
    ];
}
