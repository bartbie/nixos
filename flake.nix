{
  description = "bartbie's NixOS config";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    bartbie-nvim = {
      url = "github:bartbie/nvim/dev";
      # bartbie-nvim already follows unstable
    };
  };

  outputs = {
    self,
    nixpkgs,
    nixpkgs-unstable,
    bartbie-nvim,
    ...
  } @ inputs: let
    overlays = import ./overlays.nix inputs;

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
      ];
    };
  };
}
