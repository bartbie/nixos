{
  lib,
  nixonLib,
  config,
  ...
}:
let
  inherit (config) flake;
in
{
  flake.modules.hypr.api-keybinds =
    {
      config,
      hyprLib,
      ...
    }:
    let
      inherit (lib) types;
      inherit (hyprLib) mkSubmodule;

      # Produce a canonical form for a single effective bind. Used for assertions.
      normalizeBind =
        mainMod:
        {
          useMainMod,
          mods,
          keys,
          flags,
          ...
        }:
        let
          # flags "m" and "s" change the bind type — two binds on the same key are
          # not colliding if they have different types (e.g. bind + bindm)
          bindType =
            if builtins.elem "m" flags then
              "bindm"
            else if builtins.elem "s" flags then
              "binds"
            else
              "bind";

          allMods =
            [
              (lib.optional useMainMod mainMod)
              mods
            ]
            |> lib.flatten
            |> lib.unique;
        in
        "${bindType}:${lib.join "+" allMods}:${keys}";
    in
    {
      options.keybinds =
        let
          mkDispatchSubmodule =
            name: conf: rest:
            mkSubmodule conf (
              { config, ... }:
              {
                options = {
                  action = lib.mkOption {
                    type = lib.types.nullOr lib.types.str;
                    default = null;
                  };
                  args = lib.mkOption {
                    type = hyprLib.coercedToList hyprLib.coercedStr;
                    default = [ ];
                  };
                  exec = lib.mkOption {
                    type = types.nullOr (
                      types.coercedTo types.str
                        (cmd: {
                          inherit cmd;
                          wrap = true;
                        })
                        (
                          types.submodule {
                            options = {
                              cmd = lib.mkOption { type = types.str; };
                              wrap = lib.mkOption {
                                type = types.bool;
                                default = true;
                              };
                            };
                          }
                        )
                    );
                    default = null;
                  };
                  normalize = lib.mkOption {
                    type = types.raw;
                    readOnly = true;
                    internal = true;
                  };
                };
                config.normalize =
                  top-level-config:
                  let
                    inherit (config) exec;
                  in
                  if (exec == null) then
                    { inherit (config) action args; }
                  else
                    {
                      action = "exec";
                      args = lib.singleton (if (exec.wrap) then top-level-config.runCmd exec.cmd else exec.cmd);
                    };

                imports = [
                  rest
                  flake.modules.generic.assertions
                ];
                config.assertions = [
                  {
                    assertion = (config.action != null) != (config.exec != null);
                    message = "${name}: exactly one of action or exec must be set";
                  }
                  {
                    assertion = (config.exec != null) -> (config.args == [ ]);
                    message = "${name}: exec doesn't use args";
                  }
                ];
              }
            );
        in
        lib.mkOption {
          type = types.listOf (
            mkDispatchSubmodule "keybind" { } (
              { config, ... }:
              {
                options = {
                  useMainMod = lib.mkOption {
                    type = types.bool;
                    default = true;
                  };
                  flags = lib.mkOption {
                    type = hyprLib.coercedToList (
                      types.enum [
                        "n"
                        "e"
                        "s"
                        "m"
                        "l"
                      ]
                    );
                    apply = x: x |> lib.uniqueStrings |> builtins.sort builtins.lessThan;
                    default = [ ];
                  };
                  mods = lib.mkOption {
                    type = hyprLib.coercedToList (types.str);
                    default = [ ];
                    apply =
                      x:
                      x
                      |> builtins.filter (s: s != "")
                      |> builtins.map lib.toUpper
                      |> lib.uniqueStrings
                      |> builtins.sort builtins.lessThan;
                  };
                  keys = lib.mkOption {
                    type = hyprLib.coercedToList (types.str);
                    apply =
                      x:
                      x
                      |> builtins.filter (s: s != "")
                      |> builtins.map (k: if builtins.stringLength k == 1 then lib.toUpper k else k)
                      |> lib.uniqueStrings
                      |> builtins.sort builtins.lessThan;
                  };

                  altBehavior = lib.mkOption {
                    default = null;
                    type = types.nullOr (mkDispatchSubmodule "altBehavior" { } ({ ... }: { }));
                  };
                };
                imports = [ flake.modules.generic.assertions ];
                config.assertions =
                  nixonLib.assertions.propagateAssertions [
                    (lib.optional (config.altBehavior != null) (config.altBehavior))

                    {
                      assertion = !(builtins.elem "m" config.flags && builtins.elem "s" config.flags);
                      message = "flags 'm' and 's' are mutually exclusive";
                    }
                  ]
                  |> builtins.map (
                    x:
                    x
                    // {
                      message = "keybind [${normalizeBind config}]: ${x.message}";
                    }
                  );
              }
            )
          );
        };

      config.land =
        config.keybinds
        |> builtins.map (
          o:
          let
            dispatchToString =
              extraMods:
              {
                action,
                args,
              }:
              (
                [
                  (
                    [
                      (lib.optional o.useMainMod config.mainMod)
                      extraMods
                      o.mods
                    ]
                    |> lib.flatten
                    |> lib.join " "
                  )
                  o.keys
                  action
                  args
                ]
                |> lib.flatten
                |> lib.join ", "
              );
          in
          {
            "bind${o.flags |> lib.join ""}" = [
              # main
              (dispatchToString [ ] (o.normalize config))
              (lib.optional (o.altBehavior != null) (dispatchToString "ALT" (o.altBehavior.normalize config)))
            ];
          }
        )
        |> lib.zipAttrs
        |> builtins.mapAttrs (_: lib.flatten);

      config.assertions = nixonLib.assertions.propagateAssertions [
        config.keybinds

        (
          let
            duplicatedBinds =
              config.keybinds
              |> builtins.map (bind: [
                (normalizeBind config.mainMod bind)
                (lib.optional (bind.altBehavior != null) (
                  normalizeBind config.mainMod (bind // { mods = bind.mods ++ [ "ALT" ]; })
                ))
              ])
              |> lib.flatten
              |> builtins.groupBy (x: x)
              |> builtins.mapAttrs (_: builtins.length)
              |> lib.filterAttrs (_: count: count > 1);

            conflictCount = duplicatedBinds |> builtins.attrNames |> builtins.length |> builtins.toString;
          in
          {
            assertion = duplicatedBinds == { };
            message = ''
              Colliding keybinds detected (${conflictCount} conflicts):
                ${
                  duplicatedBinds
                  |> lib.mapAttrsToList (bind: count: "${bind}  (${builtins.toString count}x)")
                  |> lib.join "\n  "
                }
              Each entry is  bindtype:MOD+MOD:KEY  — check your `keybinds` option.
            '';
          }
        )
      ];
    };
}
