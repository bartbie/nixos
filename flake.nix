{
  description = "bartbie's NixOS config";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager/release-24.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    darwin = {
      url = "github:lnl7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    bartbie-nvim = {
      url = "github:bartbie/nvim/dev";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    impermanence.url = "github:nix-community/impermanence";
  };

  outputs = {
    self,
    nixpkgs,
    nixpkgs-unstable,
    bartbie-nvim,
    home-manager,
    darwin,
    disko,
    impermanence,
    ...
  } @ inputs: let
    overlays = import ./common/overlays.nix inputs;
    modules = import ./common/modules.nix inputs;
    stdx = import ./stdx inputs;

    inherit (stdx.flakes) mkConfig mkWithoutHMConfig mergeList;

    bartbie-nixos = mkConfig {
      variant = "nixos";
      host = "nixos";
      system = "x86_64-linux";
      overlays = with overlays; [
        (unstable-pkgs true)
        mine-pkgs
      ];
      modules = with modules; [
        ./hosts/nixos
        allowUnfree
        hypr-cachix
      ];
      hm-users = {
        bartbie = {
          home = ./hosts/nixos/home.nix;
          modules = with modules; [
            allowUnfree
          ];
        };
      };
    };

    lyndon-no-impermanence-args = {
      variant = "nixos";
      host = "lyndon";
      system = "x86_64-linux";
      overlays = with overlays; [
        (unstable-pkgs true)
        mine-pkgs
      ];
      modules = with modules; [
        disko.nixosModules.default
        ./hosts/lyndon
        allowUnfree
        hypr-cachix
      ];
      hm-users = {
        bartbie = {
          home = ./hosts/lyndon/home.nix;
          modules = with modules; [
            allowUnfree
          ];
        };
      };
    };

    lyndon-no-impermanence = mkWithoutHMConfig (lyndon-no-impermanence-args // {config-name = "lyndon-no-imperm";});

    lyndon = let
      args = lyndon-no-impermanence-args;
    in
      mkConfig (args
        // {
          modules =
            args.modules
            ++ [
              impermanence.nixosModules.impermanence
              ./hosts/lyndon/impermanence.nix
            ];
        });

    # TODO
    # roosevelt-darwin = mkConfig {
    #   variant = "darwin";
    #   host = "roosevelt";
    #   system = "aarch64-darwin";
    #   modules = [
    #     ./hosts/roosevelt
    #     allowUnfree
    #   ];
    #   hm-users = {
    #     "todo" = {
    #       home = ./hosts/roosevelt/home.nix;
    #       modules = [
    #         allowUnfree
    #       ];
    #     };
    #   };
    # };

    configs = [
      bartbie-nixos
      lyndon
      lyndon-no-impermanence
      # roosevelt-darwin
    ];

    rest = {};
  in
    mergeList rest configs;
}
