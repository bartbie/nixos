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

  outputs = {...} @ inputs: let
    inherit (inputs.nixpkgs) lib;
  in {
    nixosModules = {
      nixon = import ./modules;
    };
    nixosConfigurations = import ./hosts inputs;
    lib = import ./lib {inherit lib;};
  };
}
