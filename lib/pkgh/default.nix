{
  lib,
  final,
  self,
  ...
}:
{
  getExeAttrs =
    pkgs: at:
    let
      getPkg = p: lib.getAttrFromPath p pkgs;
      getExe = p: v: lib.getExe' (getPkg p) v;
      mapNode =
        p: v:
        if builtins.isList v then
          lib.genAttrs v (getExe p)
        else if builtins.isString v then
          getExe p v
        else
          throw "Argument must be string or list!";
    in
    # TODO: remove nesting when passing lists
    # low priority as i mostly use Flat
    lib.mapAttrsRecursive mapNode at;

  getExeAttrsFlat =
    pkgs: at:
    lib.pipe at [
      (self.getExeAttrs pkgs)
      final.flattenAttrs
    ];

  mkUnstableOverlay =
    inputs:
    (final: _: {
      unstable = import inputs.nixpkgs-unstable {
        inherit (final) system config;
      };
    });

  forSystems =
    systems: self: fn:
    let
      wrapper =
        system:
        let
          preselect =
            v:
            {
              packages = v.packages.${system} or { };
              devShells = v.devShells.${system} or { };
            }
            // v;
          self' = preselect self;
          inputs' = builtins.attrValues (_: preselect) self.inputs;
        in
        fn { inherit system self' inputs'; };

      addSystem = sys: (builtins.mapAttrs (_: outp: { ${sys} = outp; }));
    in
    lib.pipe systems [
      (builtins.map (sys: addSystem sys (wrapper sys)))
      (builtins.foldl' lib.recursiveUpdate { })
    ];

  eachSystemPkgs =
    systems: nixpkgs: overlays: f:
    let
      eachSystem = lib.genAttrs systems;
      mkPkgs = system: (import nixpkgs { inherit system overlays; });
    in
    eachSystem (system: f (mkPkgs system));

  mapArg0 =
    pkg: exe: attrs:
    attrs |> builtins.mapAttrs (_: opts: { arg0 = lib.getExe' pkg exe; } // opts);
}
