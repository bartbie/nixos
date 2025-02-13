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
  options.nixon.nix = {
    enable = mkEnableOption "nix";
    allowUnfree = mkEnableOptionTrue "unfree packages";
    package = mkPackageOption pkgs "nix" {default = ["lix"];};
  };
  config = lib.mkIf cfg.enable {
    nix = {
      inherit (cfg) package;
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
    nixpkgs.config = {inherit (cfg) allowUnfree;};
    system.switch = {
      enable = false;
      enableNg = true;
    };
  };
}
