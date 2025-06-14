{
  flake,
  lib,
  ...
}: {
  imports = flake.lib.findImports {
    from = ./default.nix;
    depth = 1;
    defaultOnly = false;
  };
}
