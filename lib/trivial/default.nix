{
  lib,
  final,
  ...
}: {
  boolToStringFlag = b:
    if b
    then "1"
    else "0";

  nullish = cond: x:
    if cond
    then x
    else null;

  headOrNull = x: final.nullish (x != []) (builtins.head x);

  last = x: builtins.head (lib.reverseList x);

  lastOrNull = x: final.nullish (x != []) (final.last x);

  mapCond = cond-fn: map-fn:
    builtins.map (v:
      if (cond-fn v)
      then (map-fn v)
      else v);

  mapAttrsCond = cond-fn: map-fn:
    builtins.mapAttrs (n: v:
      if (cond-fn n v)
      then (map-fn n v)
      else v);

  mkIfElse = cond: x: y:
    lib.mkMerge [
      (lib.mkIf cond x)
      (lib.mkIf (!cond) y)
    ];

  nullOr = val: def:
    if val != null
    then val
    else def;

  ifLet = pat: v:
    final.nullish (lib.attrsets.matchAttrs pat v) v;

  match = v: l: let
    second = x: builtins.elemAt x 1;
    matches = pair: lib.attrsets.matchAttrs (builtins.head pair) (second pair);
  in
    lib.pipe l [
      (lib.lists.findFirst matches null)
      (lib.mapNullable second)
    ];
}
