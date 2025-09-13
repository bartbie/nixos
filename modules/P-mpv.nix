{nixonLib, ...}: let
  args = [
    "--profile=gpu-hq"
    "--hwdec=auto"
  ];
in {
  wrapped.mpv.module = {pkgs, ...}: {
    wrappers = nixonLib.pkgh.mapArg0 pkgs.mpv "mpv" {
      mpv.prependArgs = args;
      mpvf.prependArgs = args ++ ["-fs"];
    };
  };
}
