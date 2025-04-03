{
  pkgs,
  lib,
  wrapperManagerLib,
  ...
}: {
  wrappers.clipse = {
    arg0 = lib.getExe' pkgs.clipse "clipse";
    prependArgs = [];
    pathAdd = wrapperManagerLib.getBin [pkgs.wl-clipboard];
  };
}
