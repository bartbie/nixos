{
  pkgs,
  lib,
  ...
}: let
  mkLsd = prependArgs: {
    arg0 = lib.getExe' pkgs.lsd "lsd";
    inherit prependArgs;
  };
in {
  wrappers = {
    lsd = mkLsd [];
    ls = mkLsd [];
    lsa = mkLsd ["-a"];
    ll = mkLsd ["-l"];
    la = mkLsd ["-la"];
  };
  nixon.standalonePackages = ["lsd" "ls"];
}
