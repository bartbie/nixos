{
  lib,
  final,
  ...
}: {
  getExeAttrs = pkgs: at: let
    getPkg = p: lib.getAttrFromPath p pkgs;
  in
    lib.mapAttrsRecursive (p: v: lib.getExe' (getPkg p) v) at;

  getExeAttrsFlat = pkgs: at:
    lib.pipe at [
      (final.getExeAttrs pkgs)
      final.flattenAttrs
    ];

  mkUnstableOverlay = inputs: (final: _: {
    unstable = import inputs.nixpkgs-unstable {
      inherit (final) system config;
    };
  });

  eachSystemPkgs = inputs: overlays: f: let
    eachSystem = lib.genAttrs (import inputs.systems);
    mkPkgs = system: (import inputs.nixpkgs {inherit system overlays;});
  in
    eachSystem (system: f (mkPkgs system));
}
