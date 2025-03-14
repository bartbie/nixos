{
  config,
  lib,
  pkgs,
  options,
  inputs,
  ...
}: let
  inherit (lib) mkEnableOption mkPackageOption mkOption;
  cfg = config.nixon.nix;
  mkEnableOptionTrue = x: (mkEnableOption x) // {default = true;};
in {
  imports = [
    inputs.lix-module.nixosModules.default
  ];
  options.nixon.nix = {
    enable = mkEnableOption "nix";
    allowUnfree = mkEnableOptionTrue "unfree packages";
    # INFO: lix.enable was added upstream AFTER 2.92, so we don't have access to it yet
    # lix.enable = mkEnableOptionTrue "lix";
    # package = mkPackageOption pkgs "nix" {
    #   nullable = true;
    #   default = null;
    # };
  };
  config = lib.mkIf cfg.enable {
    # assertions = [
    #   {
    #     assertion = cfg.lix.enable -> cfg.package == null;
    #     message = "Don't set package manually when enabling lix";
    #   }
    # ];
    # inherit (cfg) lix;
    nix = {
      gc.automatic = false;
      settings = {
        auto-optimise-store = true;
        max-jobs = "auto";
        sandbox = true;
        warn-dirty = false;
        flake-registry = "/etc/nix/registry.json";
        commit-lockfile-summary = "chore: Update flake.lock";
        extra-experimental-features = ["flakes" "nix-command" "recursive-nix" "ca-derivations"];
      };
      registry = {
        nixpkgs.flake = inputs.nixpkgs;
        nixpkgs-unstable.flake = inputs.nixpkgs-unstable;
      };
    };
    # // lib.optionalAttrs (cfg.package != null && !cfg.lix.enable) {inherit (cfg) package;};
    nixpkgs.config = {inherit (cfg) allowUnfree;};
    system.switch = {
      enable = false;
      enableNg = true;
    };
  };
}
