{
  lib,
  inputs,
  config,
  ...
}:
lib.mergeAttrsList [
  # lib
  (let
    inherit (config.flake) nixonLib;
    inherit (nixonLib) theme;
  in {
    nixonArgs = {inherit nixonLib theme;};
  })

  # nixpkgs
  (let
    mkNixpkgs = system:
      import inputs.nixpkgs {
        inherit system;
        inherit (config.overlays) stable;
      };
    mkNixpkgsUnstable = system:
      import inputs.nixpkgs-unstable {
        inherit system;
        inherit (config.overlays) unstable;
      };
  in {
    perSystem = {system, ...}: {
      nixonArgs = {
        pkgs = mkNixpkgs system;
        pkgs-unstable = mkNixpkgsUnstable system;
      };
    };

    hosts.shared = {pkgs, ...}: {
      nixpkgs = {
        overlays = config.overlays.stable;
      };
      nixonArgs = let
        # SAFETY:
        # set system from config.nixpkgs, otherwise infrec from specialArgs
        # system = config.nixpkgs.localSystem;
        inherit (pkgs) system;
      in {
        inherit system;
        pkgs-unstable = mkNixpkgsUnstable system;
      };
    };
  })
]
