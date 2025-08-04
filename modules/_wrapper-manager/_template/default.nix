{
  pkgs,
  lib,
  ...
}: {
  wrappers._TEMPLATE = {
    arg0 = lib.getExe' pkgs._TEMPLATE "_TEMPLATE";
    prependArgs = [];
  };
}
