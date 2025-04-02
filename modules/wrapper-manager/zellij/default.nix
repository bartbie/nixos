{
  pkgs,
  lib,
  ...
}: {
  wrappers.zellij = {
    arg0 = lib.getExe' pkgs.unstable.zellij "zellij";
    env.ZELLIJ_CONFIG_FILE.value = ./config.kdl;
  };
}
