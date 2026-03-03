{ lib, ... }:
let
  mkGlobal =
    type: default:
    lib.mkOption {
      inherit type default;
      readOnly = true;
    };
in
{
  options = {
    meta.defaultOwner = {
      username = mkGlobal lib.types.str "bartbie";
      git = {
        name = mkGlobal lib.types.str "bartbie";
        email = mkGlobal lib.types.str "bartbie37@gmail.com";
      };
    };
  };
}
