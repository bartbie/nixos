{
  description = "Nixon: bartbie's NixOS config";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
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
  };

  outputs = {
    self,
    nixpkgs,
    systems,
    ...
  } @ inputs: let
    inherit (nixpkgs) lib;
    stdx = import ./lib {inherit lib;};

    eachSystemPkgs = let
      eachSystem = lib.genAttrs (import systems);
      overlays = [(stdx.mkUnstableOverlay inputs)];
    in
      f: eachSystem (system: f (import nixpkgs {inherit system overlays;}));

    mkNixonDefault = x: {
      nixon = x;
      default = x;
    };
  in {
    lib = stdx;
    formatter = eachSystemPkgs (pkgs: pkgs.alejandra);
    nixosConfigurations = import ./hosts inputs;
    nixosModules = mkNixonDefault (import ./modules);
  };
}
