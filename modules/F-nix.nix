{
  inputs,
  self,
  nixonLib,
  ...
}:
{
  flake.modules.nixos = {
    base = {
      nix = {
        gc.automatic = false;
        settings = {
          auto-optimise-store = true;
          max-jobs = "auto";
          sandbox = true;
          warn-dirty = false;
          flake-registry = "/etc/nix/registry.json";
          commit-lockfile-summary = "chore: Update flake.lock";
          extra-experimental-features = [
            "flakes"
            "nix-command"
            "pipe-operator"
          ];
          substituters = [
            "https://cache.nixos.org?priority=10"
            "https://nix-community.cachix.org?priority=20"
          ];
          trusted-public-keys = [
            "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
          ];
          max-substitution-jobs = 128;
          http-connections = 128;
        };
        registry = {
          nixpkgs.flake = inputs.nixpkgs;
          nixpkgs-unstable.flake = inputs.nixpkgs-unstable;
          nixon.flake = self;
        };
      };
      system.switch = {
        enable = true; # ng from 25.11 forward
      };
    };
    allow-unfree = {
      nixpkgs.config = {
        allowUnfree = true;
      };
    };
    nh =
      { config, ... }:
      {
        programs.nh = {
          enable = true;
          clean.enable = false;
          flake = config.meta.flakePath;
        };
      };
  };
}
