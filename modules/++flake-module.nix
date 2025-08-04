{
  inputs,
  lib,
  self,
  ...
}: {
  systems = import inputs.systems;
  imports = [
    inputs.flake-parts.flakeModules.flakeModules
    inputs.flake-parts.flakeModules.modules
  ];
  flake = {
    nixonLib = import ../lib {inherit lib;};
    lib = self.nixonLib;
  };
  _module.args = {
    inherit (self) nixonLib;
    inherit (self.nixonLib) theme;
  };
  perSystem = {pkgs, ...}: {
    # TODO: checkout nix-treefmt-rfc
    formatter = pkgs.alejandra;
  };
}
# outputs = {
#   self,
#   nixpkgs,
#   systems,
#   ...
# } @ inputs: let
#   inherit (nixpkgs) lib;
#   nixonLib = import ./lib {inherit lib;};
#   mkNixonDefault = x: {
#     nixon = x;
#     default = x;
#   };
#   host-configs = import ./hosts inputs;
#   forSystems = nixonLib.pkgh.forSystems (import inputs.systems) self;
# in
#   host-configs
#   // {
#     inherit nixonLib;
#     lib = nixonLib;
#     nixosModules = mkNixonDefault (import ./modules/nixos); overlays = import ./packages inputs; #
#     wrapperManagerModules = import ./modules/wrapper-manager inputs;
#     _repl = {
#       inherit lib self;
#       lib-unstable = inputs.nixpkgs-unstable.lib;
#     };
#   }
#   // (forSystems ({
#       self',
#       inputs',
#       ...
#     } @ args: let
#       pkgs = import nixpkgs {
#         config.allowUnfree = true;
#         overlays = [self.overlays.forOutputs];
#       };
#     in {
#       formatter = pkgs.alejandra;
#       packages = pkgs.nixon;
#       devShells = import ./devShells (args // inputs // {inherit pkgs;});
#     }));

