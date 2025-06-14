{
  self,
  nixpkgs,
  ...
} @ inputs': let
  inputs = inputs' // {flake = self;};
  inherit (nixpkgs) lib;

  eachCallPackage = x: overlays: let
    call = pkgs: (import x ({inherit pkgs lib;} // inputs));
  in
    self.lib.pkgh.eachSystemPkgs inputs overlays call;

  unstable-overlay = self.lib.pkgh.mkUnstableOverlay inputs;

  common-deps = [
    unstable-overlay
    self.inputs.bartbie-nvim.overlays.default
  ];

  mkOverlay = {
    add-custom ? false,
    add-system ? false,
  }: _: prev: {
    nixon =
      (lib.optionalAttrs add-custom self.packages.${prev.system})
      // (lib.optionalAttrs add-system {
        systemPackages =
          import ./packagesSystem.nix (prev.extend (lib.composeManyExtensions common-deps));
      });
  };
in {
  packages = eachCallPackage ./packagesCustom.nix (common-deps
    ++ [
      # this way wrappers can use each other
      self.overlays.nixon
    ]);

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

  devShells = eachCallPackage ./shell.nix (common-deps ++ [self.overlays.all]);
}
