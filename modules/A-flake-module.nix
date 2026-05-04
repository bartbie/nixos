{
  inputs,
  lib,
  self,
  ...
}:
{
  systems = import inputs.systems;
  imports = [
    inputs.flake-parts.flakeModules.modules
    inputs.flake-parts.flakeModules.easyOverlay
  ];
  flake = {
    nixonLib = import ../lib { inherit lib; };
    lib = self.nixonLib;
  };
  perSystem =
    {
      config,
      pkgs,
      ...
    }:
    {
      overlayAttrs = config.packages;
    };
}
