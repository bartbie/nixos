{
  lib,
  nixonLib,
  ...
}: let
  inherit (nixonLib) templatesPath;
  mk = path: name: {
    inherit name;
    path = templatesPath + path;
  };
in {
  flake.templates = {
  };
}
