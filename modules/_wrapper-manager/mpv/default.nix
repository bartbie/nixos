{
  pkgs,
  lib,
  ...
}: let
  pkg = pkgs.mpv;
  exe = lib.getExe' pkg "mpv";
  args = [
    "--profile=gpu-hq"
    "--hwdec=auto"
  ];
in {
  wrappers.mpv = {
    arg0 = exe;
    prependArgs = args;
  };
  wrappers.mpvf = {
    arg0 = exe;
    prependArgs =
      args
      ++ [
        "-fs"
      ];
  };
}
