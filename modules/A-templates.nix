{
  lib,
  nixonLib,
  ...
}:
let
  inherit (nixonLib) templatesPath;
  mk = path: description: {
    inherit description;
    path = templatesPath + path;
  };
in
{
  flake.templates = {
    rust = mk /rust "basic rust template";
  };
}
