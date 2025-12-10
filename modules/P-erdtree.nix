{
  lib,
  nixonLib,
  ...
}: let
  ui = [
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
  wrapped.tree = {
    tags = null;
    module = {pkgs, ...}: {
      drvName = "tree";
      packagesToSymlink = [pkgs.erdtree];
      wrappers =
        {
          tree = [ui];
          treeh = [ui show-hidden];
          tre = [ui depth-2];
          treh = [ui show-hidden depth-2];
        }
        |> builtins.mapAttrs (_: v: {prependArgs = lib.flatten v;})
        |> nixonLib.pkgh.mapArg0 pkgs.erdtree "erd";
    };
  };
}
