{
  self,
  nixpkgs,
  ...
} @ inputs': let
  inputs =
    inputs'
    // {
      flake = self;
    };
  inherit (nixpkgs) lib;

  composeOls = l: lib.composeManyExtensions (lib.flatten l);

  ###

  dependencies-for = let
    unstable = self.lib.pkgh.mkUnstableOverlay inputs;
    rust = self.inputs.rust-overlay.overlays.default;

    common = [
      unstable
      (
        # HACK: wrap the nvim overlay with one passing it unstable packages
        # this way i don't need to do inputs.bartbie-nvim.packages...
        # and still have it use nixpkgs-unstable
        final: prev: let
          ol = self.inputs.bartbie-nvim.overlays.default;
        in
          ol final prev.unstable
      )
    ];

    deps-for = {
      nixon = common;

      nixonSystemPackages = common;

      all = deps-for.nixon;

      forOutputs =
        deps-for.nixon
        ++ [
          rust
          self.overlays.nixon
        ];
    };
  in
    deps-for;

  # our overlays
  overlays = {
    # packages defined by this flake
    nixon = let
      mkPackages = pkgs: import ./packagesCustom.nix ({inherit pkgs lib;} // inputs);
    in
      _: prev:
        lib.fix (self: {
          # we don't want to use final in case downstream overlays overwrite it by mistake
          nixon = mkPackages (prev // self);
        });

    # list of packages installed by nixon.packages
    nixonSystemPackages = _: prev: {
      nixon = lib.recursiveUpdate prev.nixon {
        systemPackages = import ./packagesSystem.nix prev;
      };
    };

    # nixon + systemPackages
    all = composeOls [
      self.overlays.nixon
      self.overlays.nixonSystemPackages
    ];
  };
  # same but with overlay dependencies composed in
  with-deps =
    lib.mapAttrs' (
      n: v:
        lib.nameValuePair "${n}" (composeOls [
          dependencies-for.${n}
          v
        ])
    )
    overlays;

  # overlays but renamed
  raw = lib.mapAttrs' (n: v: lib.nameValuePair "${n}Raw" v) overlays;
in
  raw
  // with-deps
  // {
    default = self.overlays.nixon;
    forOutputs = composeOls dependencies-for.forOutputs;
  }
