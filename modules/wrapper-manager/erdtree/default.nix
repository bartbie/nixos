{
  pkgs,
  lib,
  ...
}: let
  mkErdNoDef = prependArgs: {
    arg0 = lib.getExe' pkgs.erdtree "erd";
    inherit prependArgs;
  };
  mkErd = args: mkErdNoDef (lib.flatten [default args]);

  default = [
    "--suppress-size"
    "--icons"
    "--layout"
    "inverted"
  ];
  # show hidden and ignored but ignore .git
  show-hidden = [
    "--hidden"
    "--no-git"
    "--no-ignore"
  ];
  # depth limit 2
  depth-2 = ["-L" "2"];
in {
  wrappers = {
    erd = mkErdNoDef [];
    tree = mkErdNoDef default;
    treeh = mkErd [show-hidden];
    tre = mkErd [depth-2];
    treh = mkErd [show-hidden depth-2];
  };
}
