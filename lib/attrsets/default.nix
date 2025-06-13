{
  lib,
  final,
  ...
}: {
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

  mapAttrsByPathToList = fn: at: let
    marker = "_bartbie_marker";
    convertToPaths = lib.attrsets.mapAttrsRecursive (p: v: {
      path = p;
      value = fn p v;
      # mark that this is in fact a leaf attrset made by us
      ${marker} = true;
    });
    toList = v:
      if builtins.hasAttr marker v
      then [v]
      else recurseToList v;
    recurseToList = lib.attrsets.foldlAttrs (acc: _: v: acc ++ (toList v)) [];
  in
    lib.pipe at [
      convertToPaths
      recurseToList
      (builtins.map (lib.flip builtins.removeAttrs [marker]))
    ];

  flattenAttrsByPathToList = final.mapAttrsByPathToList (_: v: v);

  collectAttrsPaths = lib.flip lib.pipe [
    final.flattenAttrsByPathToList
    (builtins.map (x: x.path))
  ];
  # for [string], map by lib.attrsets.showAttrPath

  flattenAttrs = at: let
    mapNVP = x: lib.nameValuePair (final.last x.path) x.value;
  in
    lib.pipe at [
      final.flattenAttrsByPathToList
      (builtins.map mapNVP)
      builtins.listToAttrs
    ];
}
