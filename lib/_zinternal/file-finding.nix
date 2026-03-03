/*
  To avoid infinite recursion created by findImports we stuff it and listRecursive here
  so lib.fs and lib.import can re-export them
*/
{ lib, ... }:
let
  fs = lib.fileset;

  listRecursive =
    {
      depth ? -1,
      filter ? (_: true),
      groupBy ? false,
      throwIfFile ? false,
    }:
    directory:
    let
      toPaths = builtins.map (x: if builtins.isAttrs x then x.path else x);
      passed = x: !builtins.isAttrs x;
      list =
        dep: dir:
        lib.pipe dir [
          builtins.readDir
          (lib.mapAttrsToList (
            name: type:
            let
              pathname = dir + "/${name}";
              check = filter {
                inherit name type;
                parent = dir;
                hasExt = ext: lib.hasSuffix ".${ext}" name;
              };
              prep =
                cond: x: y:
                if cond then
                  x
                else
                  {
                    path = y;
                  };
            in
            prep check (
              if type == "directory" && dep != 0 then (list (dep - 1) pathname) else pathname
            ) pathname
          ))
          lib.flatten
        ];
      res =
        if lib.pathIsDirectory directory then
          list depth directory
        else if throwIfFile then
          throw "path is a file: ${builtins.toString directory}"
        else
          [ directory ];
    in
    lib.pipe res [
      (builtins.groupBy (x: lib.boolToString (passed x)))
      (x: {
        true = x.true or [ ];
        false = x.false or [ ];
      })
      (builtins.mapAttrs (_: toPaths))
      (if groupBy then lib.id else (x: x.true))
    ];

  ffintersection = fn: path: (fs.intersection (fs.fileFilter fn path));

  ffilters = {
    isImportable = f: (f.hasExt "nix") && !(lib.hasPrefix "_" f.name);
    isNix = f: (f.hasExt "nix");
    isDefaultNix = f: f.name == "default.nix";
  };
in
{
  inherit
    listRecursive
    ffilters
    ;

  findImports =
    {
      from, # can be a folder or a file (it starts from its dir then)
      depth ? 0, # -1 - all, 0 - just contents of this directory, etc.
      ignored ? [ ], # list of ignored paths
      defaultOnly ? true, # import only folders (i.e default.nix files)
      ignoreFromIfFile ? true, # if from is a file, ignore it
    }:
    let
      is-file = !lib.pathIsDirectory from;
      ignore = ignored ++ (lib.optional (is-file && ignoreFromIfFile) from);
      root = if (!lib.pathIsDirectory from) then builtins.dirOf from else from;

      normalise = x: if lib.pathIsDirectory x then fs.maybeMissing (x + /default.nix) else x;

      ffi = lib.flip ffintersection root;
    in
    lib.pipe root [
      (listRecursive {
        inherit depth;
        filter = x: !lib.hasPrefix "_" x.name;
      })
      (builtins.map normalise)
      fs.unions
      (ffi (if defaultOnly then ffilters.isDefaultNix else ffilters.isImportable))
      (x: fs.difference x (fs.unions ignore))
      fs.toList
    ];

  importsToAttrs = lib.flip lib.pipe [
    (builtins.map (
      x:
      let
        name = lib.pipe x [
          (
            x:
            assert lib.assertMsg (builtins.isPath x) "${x} must be a path!";
            x
          )
          (y: "./${builtins.toString y}")
          lib.path.subpath.components
          (lib.takeEnd 2)
          builtins.head
          (lib.removeSuffix ".nix")
        ];
      in
      lib.nameValuePair name x
    ))
    builtins.listToAttrs
  ];
}
