{
  lib,
  config,
  inputs,
  ...
}: {
  config.debug = false;
  config.flake = lib.mkIf (config.debug == true) {
    legacyPackages = inputs.nixpkgs.legacyPackages;
    lib = lib.mkForce lib;
  };
}
