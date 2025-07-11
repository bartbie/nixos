{
  self,
  nixpkgs,
  ...
} @ inputs': let
  inputs = inputs' // {flake = self;};
  inherit (nixpkgs) lib;

  unstable-overlay = self.lib.pkgh.mkUnstableOverlay inputs;
  rust-overlay = self.inputs.rust-overlay.overlays.default;

  common-overlays = [
    unstable-overlay
    self.inputs.bartbie-nvim.overlays.default
  ];

  packages-overlays = [
    # this way wrappers can use each other
    self.overlays.nixon
    rust-overlay
  ];

  shell-overlays = [
    self.overlays.all
    rust-overlay
  ];

  ###

  eachCallPackage = x: overlays: let
    call = pkgs: (import x ({inherit pkgs lib;} // inputs));
  in
    self.lib.pkgh.eachSystemPkgs inputs overlays call;

  mkOverlay = {
    add-custom ? false,
    add-system ? false,
  }: _: prev: {
    nixon =
      (lib.optionalAttrs add-custom self.packages.${prev.system})
      // (lib.optionalAttrs add-system {
        systemPackages =
          import ./packagesSystem.nix (prev.extend (lib.composeManyExtensions common-overlays));
      });
  };
in {
  packages = eachCallPackage ./packagesCustom.nix (common-overlays ++ packages-overlays);

  overlays = {
    default = self.overlays.nixon;

    # packages defined by this flake
    nixon = mkOverlay {add-custom = true;};

    # list of packages installed by nixon.packages
    nixonSystemPackages = mkOverlay {add-system = true;};

    # nixon + systemPackages
    all = mkOverlay {
      add-custom = true;
      add-system = true;
    };
  };

  devShells = eachCallPackage ./shell.nix (common-overlays ++ shell-overlays);
}
