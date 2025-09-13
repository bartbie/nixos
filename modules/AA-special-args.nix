{
  lib,
  inputs,
  config,
  ...
}:
# lib
(let
  inherit (config.flake) nixonLib;
  inherit (nixonLib) theme;
in {
  nixonArgs = {inherit nixonLib theme;};
})
//
# nixpkgs
(let
  nixpkgs-settings = {
    overlays = [];
  };
  mkNixpkgs = system:
    import inputs.nixpkgs (nixpkgs-settings // {inherit system;});
  mkNixpkgsUnstable = system:
    import inputs.nixpkgs-unstable (nixpkgs-settings // {inherit system;});
in {
  perSystem = {system, ...}: {
    nixonArgs = {
      pkgs = mkNixpkgs system;
      pkgs-unstable = mkNixpkgsUnstable system;
    };
  };

  hosts.shared = {pkgs, ...}: {
    nixpkgs = nixpkgs-settings;
    nixonArgs = let
      # # SAFETY: set system from config.nixpkgs, otherwise infrec from specialArgs
      # system = config.nixpkgs.localSystem;
      inherit (pkgs) system;
    in {
      inherit system;
      pkgs-unstable = mkNixpkgsUnstable system;
    };
  };
})
