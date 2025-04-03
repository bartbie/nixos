{
  pkgs,
  lib,
  ...
}: {
  wrappers.kanata = {
    arg0 = lib.getExe' pkgs.unstable.kanata "kanata";
    prependArgs = [
      "--cfg"
      ./config.kbd
    ];
  };
}
