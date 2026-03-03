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
  flake.modules.hypr.api-workspacerules =
    {
      config,
      hyprLib,
      ...
    }:
    let
      inherit (lib) types;
      inherit (hyprLib) mkSubmodule;
    in
    {
      options.workspaceRules =
        let
          inherit (hyprLib) typed typedOpt coercedToList;

          str = typedOpt types.str;
          bool = typedOpt types.bool;
          int = typedOpt types.int;
          uint = typedOpt types.ints.unsigned;

          nonZeroInt = types.addCheck types.int (n: n != 0);

          relAbsType = types.submodule {
            options = {
              rel = typed types.int;
              abs = typed types.ints.unsigned;
            };
          };

          windowCountFlagsType = lib.mkOption {
            type = coercedToList (
              types.enum [
                "t"
                "f"
                "g"
                "v"
                "p"
              ]
            );
            apply = x: x |> lib.uniqueStrings |> builtins.sort builtins.lessThan;
            default = [ ];
          };

          workspaceIdentifierType = types.submodule (
            { config, ... }:
            {
              imports = [ flake.modules.generic.assertions ];

              options = {
                id = uint;
                relId = typedOpt nonZeroInt;
                name = str;
                m = typedOpt relAbsType;
                r = typedOpt relAbsType;
                e = typedOpt relAbsType;
                previous = typedOpt (
                  hyprLib.enumAliased {
                    "previous" = [ "global" ];
                    "previous_per_monitor" = [ "per_monitor" ];
                  }
                );
                empty = typedOpt (
                  types.submodule {
                    options = {
                      m = typed types.bool;
                      n = typed types.bool;
                    };
                  }
                );
                special = typedOpt (types.either types.bool types.str);
              };

              config =
                let
                  setFields =
                    config
                    |> (
                      x:
                      builtins.removeAttrs x [
                        "_module"
                        "assertions"
                      ]
                    )
                    |> (lib.filterAttrs (_: v: v != null))
                    |> builtins.attrNames;
                in
                {
                  assertions = [
                    {
                      assertion = builtins.length setFields == 1;
                      message = "workspaceIdentifier: exactly one field must be set, got: ${
                        if setFields == [ ] then "none" else lib.join ", " setFields
                      }";
                    }
                  ];
                };
            }
          );

          selectorType = types.submodule {
            imports = [
              (lib.mkAliasOptionModule [ "range" ] [ "r" ])
              (lib.mkAliasOptionModule [ "special" ] [ "s" ])
              (lib.mkAliasOptionModule [ "name" ] [ "n" ])
              (lib.mkAliasOptionModule [ "monitor" ] [ "m" ])
              (lib.mkAliasOptionModule [ "windowCount" ] [ "w" ])
              (lib.mkAliasOptionModule [ "fullscreen" ] [ "f" ])
            ];

            options = {
              r = typedOpt (
                types.submodule {
                  options = {
                    from = typed types.ints.unsigned;
                    to = typed types.ints.unsigned;
                  };
                }
              );
              s = bool;
              n = typedOpt (
                types.oneOf [
                  types.bool
                  (types.submodule { options.starts = typed types.str; })
                  (types.submodule { options.ends = typed types.str; })
                ]
              );
              m = str // {
                apply = s: if s == "" then null else s;
              };
              w = typedOpt (
                types.submodule (
                  { config, ... }:
                  {
                    options = {
                      flags = windowCountFlagsType;
                      exact = int;
                      from = int;
                      to = int;
                    };
                    imports = [ flake.modules.generic.assertions ];
                    config.assertions = [
                      {
                        assertion = config.exact != null -> (config.from == null && config.to == null);
                        message = "windowCount: exact and from/to are mutually exclusive";
                      }
                      {
                        assertion = (config.from != null) == (config.to != null);
                        message = "windowCount: from/to require each other";
                      }
                    ];
                  }
                )
              );
              f = typedOpt (
                types.enum [
                  (-1)
                  0
                  1
                  2
                ]
              );
            };
          };
        in
        lib.mkOption {
          default = [ ];
          type = types.listOf (
            mkSubmodule { } {
              options = {
                match = lib.mkOption {
                  type = types.attrTag {
                    goto = typed workspaceIdentifierType;
                    filter = typed selectorType;
                  };
                };
                monitor = str;
                default = bool;
                persistent = bool;
                defaultName = str;
                gapsin = int;
                gapsout = int;
                bordersize = int;
                rounding = bool;
                decorate = bool;
                shadow = bool;
                layout = str;
                on-created-empty = str;
              };
            }
          );
        };

      config.land.workspace =
        let
          inherit (hyprLib) toString;
          kvToString = x: y: "${x}:${y}";

          getGoto =
            id:
            let
              relToString = rel: (lib.optionalString (rel > 0) "+") + (toString rel);

              relAbsToString =
                prefix: ra:
                if ra.rel != null then "${prefix}${relToString ra.rel}" else "${prefix}~${toString ra.abs}";

              field =
                id
                |> (x: builtins.removeAttrs x [ "assertions" ])
                |> lib.filterAttrs (_: v: v != null)
                |> builtins.attrNames
                |> builtins.head;
            in
            {
              relId = relToString id.relId;
              name = kvToString "name" id.name;
              m = relAbsToString "m" id.m;
              r = relAbsToString "r" id.r;
              e = relAbsToString "e" id.e;
              empty = "empty${lib.optionalString id.empty.n "n"}${lib.optionalString id.empty.m "m"}";
              special = if builtins.isBool id.special then "special" else kvToString "special" id.special;
            }
            .${field} or (id.${field} |> toString);

          getFilters =
            let
              nameToString =
                n:
                if builtins.isBool n then
                  hyprLib.toString n
                else if n.starts != null then
                  kvToString "s" n.starts
                else
                  kvToString "e" n.ends;

              wcToString =
                w:
                let
                  flagStr = lib.join "" w.flags;
                  countStr = if w.exact != null then toString w.exact else "${toString w.from}-${toString w.to}";
                in
                "w[${lib.optionalString (flagStr != "") "(${flagStr})"}${countStr}]";

              mapSelector =
                at: c: fn:
                lib.optional (at.${c} != null) "${c}[${fn at.${c}}]";
            in
            f: [
              (mapSelector f "r" (
                {
                  from,
                  to,
                }:
                "${toString from}-${toString to}"
              ))
              (mapSelector f "n" nameToString)
              (mapSelector f "w" wcToString)
              (
                builtins.removeAttrs f [
                  "r"
                  "n"
                  "w"
                  "assertions"
                ]
                |> builtins.attrNames
                |> builtins.map (n: mapSelector f n toString)
              )
            ];
        in
        config.workspaceRules
        |> builtins.map (
          wr:
          [
            (
              (
                {
                  goto = getGoto wr.match.goto;
                  filter = getFilters wr.match.filter;
                }
                .${wr.match |> builtins.attrNames |> builtins.head}
              )
              |> lib.flatten
              |> lib.join " "
            )
            (
              wr
              |> (
                x:
                builtins.removeAttrs x [
                  "match"
                  "assertions"
                ]
              )
              |> lib.filterAttrs (n: v: v != null)
              |> builtins.mapAttrs (n: v: kvToString n (toString v))
              |> builtins.attrValues
            )
          ]
          |> lib.flatten
          |> lib.join ", "
        );

      config.assertions = nixonLib.assertions.propagateAssertions [
        config.workspaceRules
        (
          let
            violations =
              config.workspaceRules
              |> lib.filter (r: r.monitor or null != null)
              |> builtins.groupBy (x: x.monitor)
              |> lib.filterAttrs (_: entries: (builtins.length entries) > 1)
              |> lib.mapAttrsToList (
                monitor: entries:
                "monitor ${monitor}: ${
                  entries |> builtins.map (r: r.defaultName or (toString r.match.goto.id or "?")) |> lib.join ", "
                }"
              );
          in
          {
            assertion = violations == [ ];
            message = "workspaceRules: max 1 default per monitor\n  ${lib.join "\n  " violations}";
          }
        )
      ];
    };
}
