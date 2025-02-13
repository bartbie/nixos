{lib, ...}: {
  imports = lib.stdx.findImports ./default.nix [];
}
