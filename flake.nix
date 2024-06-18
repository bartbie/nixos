{
  description = "bartbie's NixOS config";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager/release-23.11";
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
  };

  outputs = {
    self,
    nixpkgs,
    nixpkgs-unstable,
    bartbie-nvim,
    home-manager,
    darwin,
    ...
  } @ inputs: let
    overlays = import ./overlays.nix inputs;
    modules = import ./modules.nix inputs;
    stdx-flakes = import ./stdx/flakes.nix inputs;

    inherit (stdx-flakes) mkConfig addOverlays shallowMergeList;
    inherit (nixpkgs.lib.attrsets) optionalAttrs;

    bartbie-nixos = mkConfig {
      variant = "nixos";
      host = "nixos";
      system = "x86_64-linux";
      modules = with modules; [
        ./hosts/nixos
        allowUnfree
        (addOverlays (with overlays; [
          (unstable-pkgs true)
          mine-pkgs
        ]))
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
      # roosevelt-darwin
    ];

    rest = {};
  in
    shallowMergeList rest configs;
}
