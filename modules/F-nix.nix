{inputs, ...}: {
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
          extra-experimental-features = ["flakes" "nix-command" "pipe-operator"];
        };
        registry = {
          nixpkgs.flake = inputs.nixpkgs;
          nixpkgs-unstable.flake = inputs.nixpkgs-unstable;
        };
      };
      system.switch = {
        enable = true; # ng from 25.11 forward
      };
    };
    allowUnfree = {
      nixpkgs.config = {allowUnfree = true;};
    };
    nh = {
      programs.nh = {
        enable = true;
        clean.enable = false;
        flake = "/etc/nixos";
      };
    };
  };
}
