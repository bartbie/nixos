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
    host-configs = import ./hosts inputs;
    forSystems = self.lib.pkgh.forSystems (import inputs.systems) self;
  in
    host-configs
    // {
      lib = import ./lib {inherit lib;};
      nixonLib = self.lib;
      nixosModules = mkNixonDefault (import ./modules/nixos);
      overlays = import ./packages inputs;
      #
      wrapperManagerModules = import ./modules/wrapper-manager inputs;
      _repl = {
        inherit lib self;
        lib-unstable = inputs.nixpkgs-unstable.lib;
      };
    }
    // (forSystems ({
        system,
        self',
        inputs',
        ...
      } @ args: let
        pkgs = import nixpkgs {
          config.allowUnfree = true;
          overlays = [self.overlays.nixon self.overlays.forDevShells];
        };
      in {
        formatter = inputs'.nixpkgs.legacyPackages.alejandra;
        devShells = import ./devShells args;
        packages = let this = self.overlays.nixon this pkgs; in this;
      }));
}
