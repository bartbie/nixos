{
  self,
  nixpkgs,
  ...
} @ inputs: let
  inherit (nixpkgs) lib;

  _dependencies = lib.composeManyExtensions [
    self.overlays.nixon
    (self.lib.mkUnstableOverlay inputs)
    self.inputs.bartbie-nvim.overlays.default
  ];

  eachCallPackage = x: overlays: let
    call = pkgs: (import x ({inherit pkgs lib;} // inputs));
  in
    self.lib.eachSystemPkgs inputs overlays call;
in {
  packages = eachCallPackage ./mkPkgs.nix [_dependencies];

  devShells = eachCallPackage ./shell.nix [_dependencies self.overlays.systemPackages];

  overlays = {
    default = self.overlays.nixon;

    # packages defined by this flake
    nixon = _: prev: {nixon = self.packages.${prev.system};};

    ### overlays used by this flake

    # list of packages installed by nixon.packages
    systemPackages = _: prev: {
      systemPackages = import ./systemPackages.nix (prev.extend _dependencies);
    };

    # nixon + systemPackages
    all = lib.composeManyExtensions (builtins.attrValues {
      inherit
        (self.overlays)
        nixon
        systemPackages
        ;
    });

    # dependencies overlay used by this flake
    # will probably interfere with your other overlays
    inherit _dependencies;
  };
}
