{
  pkgs,
  lib,
  ...
}: {
  wrappers.zellij = {
    arg0 = lib.getExe' pkgs.zellij "zellij";
    env.ZELLIJ_CONFIG_FILE.value = ./config.kdl;
  };
}
