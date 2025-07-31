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

    # mod -> wrapper
    buildBaseWrapper = mod:
      lib.makeOverridable (
        overrideArgs: let
          mods = [
            mod
            modules.options
          ];
          specialArgs = {
            inherit flake;
            inherit (flake.lib) theme;
            overrideArgs = builtins.removeAttrs overrideArgs ["wrapperArgs"];
            wrapperArgs = overrideArgs.wrapperArgs or {};
          };
          cfg-nixon =
            (lib.evalModules {
              specialArgs =
                specialArgs
                // {
                  inherit pkgs;
                };
              modules = mods ++ [{_module.check = false;}];
            }).config.nixon;
          cfg =
            (wrapper-manager.lib.eval {
              inherit specialArgs pkgs;
              modules = mods;
            }).config;
        in
          if !cfg-nixon.enable
          then {passthru.nixon.enable = cfg-nixon.enable;}
          else
            (cfg.build.toplevel.overrideAttrs cfg.nixon.overrideAttrs).overrideAttrs (prev: {
              passthru =
                prev.passthru
                // {
                  nixon = {
                    inherit (cfg) wrappers;
                    inherit (cfg.nixon) enable;
                    extraWrappersNames = cfg.nixon.standalonePackages;
                  };
                };
            })
      ) {};

    # picks subwrapper by its pname and sets correct metadata, including meta.mainProgram
    # {wrapper, subwrapper} -> drv
    pickSubwrapper = {
      base,
      subwrapper,
    }:
      base.overrideAttrs (
        final: prev:
          {
            pname = subwrapper.pname;
            executableName = subwrapper.executableName;
          }
          // (flake.lib.optionalAttr "version" subwrapper)
          // {
            name =
              if final ? version
              then "${final.pname}-${final.version}"
              else final.pname;
            passthru = lib.recursiveUpdate (prev.passthru or {}) {nixon.baseWrapper = base;};
            meta = lib.recursiveUpdate (prev.meta or {}) {
              name = final.pname;
              mainProgram = final.executableName;
            };
          }
      );

    # given name, evals wm module to a list of wrappers
    # name -> mod -> [drv] | []
    buildWrappers = name: mod: let
      assertNameInWrappers = name: wrappers:
        lib.assertMsg (builtins.elem name (builtins.attrNames wrappers)) "name is not in wrappers!\nname:${name}\nwrappers:${builtins.toString (builtins.attrNames wrappers)}";

      base-wrapper = buildBaseWrapper mod;
      inherit (base-wrapper.passthru.nixon) enable wrappers extraWrappersNames;

      # if it's null (default), use filename, otherwise use list
      names = flake.lib.nullOr extraWrappersNames [name];
    in
      lib.optionals enable (
        lib.forEach names (
          name:
            assert assertNameInWrappers name wrappers;
              pickSubwrapper {
                base = base-wrapper;
                subwrapper =
                  wrappers.${name}
                  // {
                    pname = name;
                  };
              }
        )
      );

    # evals attrsOf wm modules
    # {modname -> modules} -> {pname -> drv}
    evalWrapperImports = attr:
      lib.pipe attr [
        (lib.mapAttrsToList buildWrappers)
        lib.flatten
        (builtins.map (x: lib.nameValuePair x.pname x))
        builtins.listToAttrs
      ];
  in
    evalWrapperImports modules.list-flat;

  scripts = {};
in
  wrapped // scripts
