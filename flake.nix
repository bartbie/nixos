{
  description = "Nixon: bartbie's multi-system config";

  nixConfig = {
    extra-substituters = [
      "https://bartbie.cachix.org"
    ];
    extra-trusted-public-keys = [
      "bartbie.cachix.org-1:sX0rzre7TKHN949pzOO5mWubI/6uXKIoMCzRZPnHbDI="
    ];
    extra-experimental-features = [
      "flakes"
      "nix-command"
      "pipe-operator"
    ];
  };

  outputs = inputs: inputs.flake-parts.lib.mkFlake { inherit inputs; } (inputs.import-tree ./modules);

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    systems.url = "github:nix-systems/default";
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
    impermanence = {
      url = "github:nix-community/impermanence";
      inputs.nixpkgs.follows = "";
      inputs.home-manager.follows = "";
    };
    wrapper-manager.url = "github:foo-dogsquared/nix-module-wrapper-manager-fds";
    deploy-rs.url = "github:serokell/deploy-rs";
    #
    flake-parts.url = "github:hercules-ci/flake-parts";
    import-tree.url = "github:vic/import-tree";
    easy-hosts.url = "github:bartbie/easy-hosts"; # our fork
    #
    bartbie-nvim = {
      url = "github:bartbie/nvim";
      inputs = {
        # TODO: remove after updating nixpkgs-unstable
        # nixpkgs.follows = "nixpkgs-unstable";
        flake-parts.follows = "flake-parts";
        import-tree.follows = "import-tree";
        systems.follows = "systems";
      };
    };
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    naersk = {
      url = "github:nix-community/naersk";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    quickshell = {
      url = "git+https://git.outfoxxed.me/outfoxxed/quickshell";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    # remove when upstream nixpkgs picks it up
    hyprland-guiutils = {
      url = "github:hyprwm/hyprland-guiutils";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    hypridle = {
      url = "github:hyprwm/hypridle";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
      inputs.systems.follows = "systems";
    };
    tuigreet = {
      url = "github:NotAShelf/tuigreet";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

  };
}
