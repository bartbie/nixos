{
  pkgs,
  lib,
  ...
}: {
  wrappers.kanata = {
    arg0 = lib.getExe' pkgs.unstable.kanata "kanata";
    prependArgs = [
      "--cfg"
      # for live-reload
      # "/etc/nixos/modules/wrapper-manager/kanata/config.kbd"
      ./config.kbd
    ];
  };
}
