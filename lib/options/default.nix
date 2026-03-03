{
  lib,
  final,
  self,
  ...
}:
let
  inherit (lib) types;
  mkMarker =
    default: type:
    lib.mkOption {
      inherit type default;
      internal = true;
      readOnly = true;
    };
  mkMarkerWith = default: fn: mkMarker default (fn types);
in
{
  inherit
    mkMarker
    mkMarkerWith
    ;
}
