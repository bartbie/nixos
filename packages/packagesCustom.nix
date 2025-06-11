{
  lib,
  pkgs,
  wrapper-manager,
  self,
  ...
} @ inputs: let
  flake = self;
  wrapped = let
    modules = flake.wrapperManagerModules;
    # stage 1 - we eval modules and add filenames

    # wrapper around eval that extracts needed data
    eval = mod: let
      cfg =
        (wrapper-manager.lib.eval {
          inherit pkgs;
          modules = lib.flatten [mod modules.options];
          specialArgs = {
            inherit flake;
            inherit (flake.lib) theme;
          };
        })
        .config;
    in {
      inherit (cfg) wrappers;
      inherit (cfg.build) toplevel;
      extraWrappersNames = cfg.nixon.standalonePackages;
    };

    evalAttrsToList = lib.flip lib.pipe [
      (builtins.mapAttrs (filename: mod: {inherit filename;} // (eval mod)))
      builtins.attrValues
    ];

    # stage 2 - we add extra wrappers by converting a wrapper to a list with extras

    assertName = name: wrappers: lib.assertMsg (builtins.elem name (builtins.attrNames wrappers)) "name is not in wrappers!";

    # sets correct meta.mainProgram and names
    overrideName = name: {
      wrappers,
      toplevel,
      ...
    }:
      assert assertName name wrappers;
        toplevel
        .overrideAttrs (final: prev: {
          pname = name;
          meta =
            lib.recursiveUpdate (prev.meta or {})
            {
              name = final.pname;
              mainProgram = wrappers.${name}.executableName;
            };
        });

    convertWrapperToList = {
      filename,
      extraWrappersNames,
      ...
    } @ args: let
      # if it's null (default), use filename, otherwise use list
      names = flake.lib.nullOr extraWrappersNames [filename];
    in
      builtins.map (name: {
        inherit name;
        value = overrideName name args;
      })
      names;

    # stage 3 - flatten and convert everything to a attrs for consumption

    flattenToAttrs = list: builtins.listToAttrs (lib.flatten list);
  in
    lib.pipe modules.list-flat [
      evalAttrsToList
      (builtins.map convertWrapperToList)
      flattenToAttrs
    ];

  scripts = {};
in
  wrapped // scripts
