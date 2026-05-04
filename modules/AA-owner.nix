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
      keys = {
        ssh = mkGlobal (lib.types.listOf lib.types.str) [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKIg9rfjOQyZBf1HsrLD3PxG8dhbJbX6Spn9XHDJpJTj bartbie@lyndon"
        ];
      };
    };
    meta.defaultFlakePath = mkGlobal (lib.types.pathWith {
      inStore = false;
      absolute = true;
    }) "/etc/nixos";
  };
}
