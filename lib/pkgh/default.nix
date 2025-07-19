{
  lib,
  final,
  self,
  ...
}: {
  getExeAttrs = pkgs: at: let
    getPkg = p: lib.getAttrFromPath p pkgs;
    getExe = p: v: lib.getExe' (getPkg p) v;
    mapNode = p: v:
      if builtins.isList v
      then lib.genAttrs v (getExe p)
      else if builtins.isString v
      then getExe p v
      else throw "Argument must be string or list!";
  in
    # TODO: remove nesting when passing lists
    # low priority as i mostly use Flat
    lib.mapAttrsRecursive mapNode at;

  getExeAttrsFlat = pkgs: at:
    lib.pipe at [
      (self.getExeAttrs pkgs)
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
