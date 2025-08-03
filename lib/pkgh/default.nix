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

  forSystems = systems: self: fn: let
    each-sys = lib.genAttrs systems (system: let
      preselect = v:
        {
          packages = v.packages.${system} or {};
          devShells = v.devShells.${system} or {};
        }
        // v;
      self' = preselect self;
      inputs' = builtins.attrValues (_: preselect) self.inputs;
    in
      fn {inherit system self' inputs';});
  in
    lib.pipe each-sys [
      # {
      #     linux = {pkgs = X;};
      #     darwin = {pkgs = Y;};
      # }
      (builtins.mapAttrs (sys: builtins.mapAttrs (_: v: {${sys} = v;})))
      # {
      #     linux = {pkgs = {linux = X;};};
      #     darwin = {pkgs = {darwin = Y;};};
      # }
      builtins.attrValues
      # [
      #     {pkgs = {linux = X;};}
      #     {pkgs = {darwin = Y;};}
      # ]
      (builtins.foldl' lib.recursiveUpdate {})
      # {
      #     pkgs = {linux = X; darwin = Y;};
      # }
    ];

  eachSystemPkgs = systems: nixpkgs: overlays: f: let
    eachSystem = lib.genAttrs systems;
    mkPkgs = system: (import nixpkgs {inherit system overlays;});
  in
    eachSystem (system: f (mkPkgs system));
}
