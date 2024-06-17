{
  description = "bartbie's NixOS config";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager/release-23.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    bartbie-nvim = {
      url = "github:bartbie/nvim/dev";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
  };

  outputs = {
    self,
    nixpkgs,
    nixpkgs-unstable,
    bartbie-nvim,
    home-manager,
    ...
  } @ inputs: let
    overlays = import ./overlays.nix inputs;

    home = opts: {home-manager = opts;};

    add-ol = overlays: {...}: {
      nixpkgs.overlays = overlays;
    };
  in {
    nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./hosts/nixos
        (add-ol (with overlays; [
          (unstable-pkgs true)
          mine-pkgs
        ]))
        home-manager.nixosModules.home-manager
        (home {
          useGlobalPkgs = true;
          useUserPackages = true;
          users.bartbie = import ./hosts/nixos/home.nix;
        })
      ];
    };
    # Standalone home-manager configuration entrypoint
    # Available through 'home-manager --flake .#your-username@your-hostname'
    homeConfigurations = {
      "bartbie@nixos" = home-manager.lib.homeManagerConfiguration {
        pkgs = import nixpkgs {system = "x86_64-linux";};
        modules = [
          ./hosts/nixos/home.nix
          {nixpkgs.config.allowUnfree = true;}
        ];
      };
    };
  };
}
