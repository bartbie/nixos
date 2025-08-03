{
  description = "Nixon: bartbie's NixOS config";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    hardware.url = "github:nixos/nixos-hardware";
    systems.url = "github:nix-systems/default";
    lix-module = {
      url = "https://git.lix.systems/lix-project/nixos-module/archive/2.93.2-1.tar.gz";
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
    wrapper-manager.url = "github:foo-dogsquared/nix-module-wrapper-manager-fds";
    bartbie-nvim = {
      url = "github:bartbie/nvim/rocks";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
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
    configs = import ./hosts inputs;
  in
    {
      lib = import ./lib {inherit lib;};
      formatter = self.lib.pkgh.eachSystemPkgs inputs [] (pkgs: pkgs.alejandra);
      nixosModules = mkNixonDefault (import ./modules/nixos);
      inherit (import ./packages inputs) packages overlays devShells;
      #
      nixonLib = self.lib;
      wrapperManagerModules = import ./modules/wrapper-manager inputs;
      _repl = {
        inherit lib self;
        lib-unstable = inputs.nixpkgs-unstable.lib;
      };
    }
    // configs;
}
