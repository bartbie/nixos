{
  lib,
  final,
  self,
  ...
}: let
  attr = lib.attrsets;
in {
  filterMapRec = leaf-fn: filter-fn: map-fn: let
    mark = {_bartbie_remove = null;};
    marked = x: x ? _bartbie_remove;
  in
    lib.flip lib.pipe [
      (
        attr.mapAttrsRecursiveCond leaf-fn
        (p: v: (
          if (filter-fn p v)
          then (map-fn p v)
          else mark
        ))
      )
      (lib.filterAttrsRecursive (n: v: !(marked v)))
    ];

  flatten = at: let
    mapNVP = x: lib.nameValuePair (final.last x.path) x.value;
  in
    lib.pipe at [
      self.bypath.flattenToList
      (builtins.map mapNVP)
      builtins.listToAttrs
    ];

  flattenAttrs = self.flatten;
  optionalAttr = name: at:
    lib.optionalAttrs (attr.hasAttr name at) {${name} = at.${name};};

  bypath = {
    mapToList = self.bypath.mapToListCond (_: true);

    mapToListCond = cond: fn: at: let
      marker = "_bartbie_marker";
      convertToPaths = attr.mapAttrsRecursiveCond cond (p: v: {
        path = p;
        value = fn p v;
        # mark that this is in fact a leaf attrset made by us
        ${marker} = true;
      });
      toList = v:
        if builtins.hasAttr marker v
        then [v]
        else recurseToList v;
      recurseToList = attr.foldlAttrs (acc: _: v: acc ++ (toList v)) [];
    in
      lib.pipe at [
        convertToPaths
        recurseToList
        (builtins.map (lib.flip builtins.removeAttrs [marker]))
      ];

    flattenToList = self.bypath.mapToList (_: v: v);
    flattenToListCond = cond: self.bypath.mapToListCond cond (_: v: v);

    collectPaths = lib.flip lib.pipe [
      self.bypath.flattenToList
      (builtins.map (x: x.path))
    ];
    # for [string], map by lib.attrsets.showAttrPath
  };
}
