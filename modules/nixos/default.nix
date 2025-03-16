{
  flake,
  lib,
  ...
}: {
  imports = flake.lib.findImports ./default.nix [];
}
