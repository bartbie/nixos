{
  lib,
  config,
  inputs,
  ...
}: {
  config.debug = false;
  config.flake = lib.mkIf (config.debug == true) {
    # legacyPackages = inputs.nixpkgs.legacyPackages;
    lib = lib.mkForce lib;
  };
  config.perSystem = {
    system,
    pkgs,
    pkgs-unstable,
    ...
  }: {
    debug = {
      inherit pkgs pkgs-unstable system;
      nixpkgs = inputs.nixpkgs.legacyPackages.${system};
      nixpkgs-unstable = inputs.nixpkgs-unstable.legacyPackages.${system};
    };
  };
}
