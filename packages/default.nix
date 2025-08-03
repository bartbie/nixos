{
  self,
  nixpkgs,
  ...
} @ inputs': let
  inputs = inputs' // {flake = self;};
  inherit (nixpkgs) lib;

  ###

  dependencies = let
    unstable = self.lib.pkgh.mkUnstableOverlay inputs;
    rust = self.inputs.rust-overlay.overlays.default;

    common = [
      unstable
      self.inputs.bartbie-nvim.overlays.default
    ];

    this = {
      nixon =
        common
        ++ [
          # this way wrappers can use each other
          self.overlays.nixon
        ];

      nixonSystemPackages = common;

      forDevShells =
        this.nixon
        ++ [
          rust
        ];

      all = this.nixon;
    };
  in
    this;

  # our overlays
  overlays = {
    # packages defined by this flake
    nixon = let
      mkPackages = pkgs: import ./packagesCustom.nix ({inherit pkgs;} // inputs);
    in
      _: prev: mkPackages prev;

    # list of packages installed by nixon.packages
    nixonSystemPackages = _: prev: {
      nixon = lib.recursiveUpdate prev.nixon {
        systemPackages =
          import ./packagesSystem.nix prev;
      };
    };

    # nixon + systemPackages
    all = lib.composeManyExtensions [self.overlays.nixon self.overlays.nixonSystemPackages];
  };
in {
  overlays = let
    # same but with overlay dependencies composed in
    with-deps = lib.mapAttrs' (n: v: lib.nameValuePair "${n}" (lib.composeManyExtensions [v dependencies.${n}])) overlays;

    # overlays but renamed
    raw = lib.mapAttrs' (n: v: lib.nameValuePair "${n}Raw") overlays;
  in
    raw
    // with-deps
    // {
      default = self.overlays.nixon;
      inherit (dependencies) forDevShells;
    };
}
