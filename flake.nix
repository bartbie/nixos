{
  description = "Nixon: bartbie's NixOS config";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    hardware.url = "github:nixos/nixos-hardware";
    lix-module = {
      url = "https://git.lix.systems/lix-project/nixos-module/archive/2.92.0-1.tar.gz";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    darwin = {
      url = "github:lnl7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    impermanence.url = "github:nix-community/impermanence";
    bartbie-nvim = {
      url = "github:bartbie/nvim/rocks";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    wrapper-manager.url = "github:foo-dogsquared/nix-module-wrapper-manager-fds";
    systems.url = "github:nix-systems/default";
  };

  outputs = {
    self,
    nixpkgs,
    systems,
    ...
  } @ inputs: let
    inherit (nixpkgs) lib;
    mkNixonDefault = x: {
      nixon = x;
      default = x;
    };
  in {
    lib = import ./lib {inherit lib;};
    formatter = self.lib.eachSystemPkgs inputs [] (pkgs: pkgs.alejandra);
    nixosConfigurations = import ./hosts inputs;
    nixosModules = mkNixonDefault (import ./modules/nixos);
    inherit (import ./packages inputs) packages overlays devShells;
    wrapperManagerModules = mkNixonDefault (import ./modules/wrapper-manager);
  };
}
