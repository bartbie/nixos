{
  nixpkgs,
  self,
  ...
}: let
  flake = self;
  inherit (nixpkgs) lib;

  list = import ./list.nix {inherit lib flake;};
in
  list
  // {
    inherit list;
    list-flat = flake.lib.attrsets.flattenAttrs list;
    base-all = {imports = builtins.attrValues list.base;};
    options = ./options.nix;
  }
