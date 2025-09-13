{
  description = "Nixon: bartbie's multi-system config";

  nixConfig = {
    extra-experimental-features = ["flakes" "nix-command" "pipe-operator" "no-url-literals"];
  };

  outputs = inputs:
    inputs.flake-parts.lib.mkFlake {inherit inputs;} (inputs.import-tree ./modules);

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    systems.url = "github:nix-systems/default";
    #
    lix-module = {
      url = "https://git.lix.systems/lix-project/nixos-module/archive/2.93.2-1.tar.gz";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    darwin = {
      url = "github:lnl7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    #
    hardware.url = "github:nixos/nixos-hardware";
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    impermanence.url = "github:nix-community/impermanence";
    wrapper-manager.url = "github:foo-dogsquared/nix-module-wrapper-manager-fds";
    #
    flake-parts.url = "github:hercules-ci/flake-parts";
    import-tree.url = "github:vic/import-tree";
    easy-hosts.url = "github:bartbie/easy-hosts"; # our fork
    #
    bartbie-nvim = {
      url = "github:bartbie/nvim";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
  };
}
