{
  lib,
  nixonLib,
  ...
}: {
  flake.modules.hypr.api-windowrules = {
    config,
    hyprLib,
    ...
  }: let
    inherit (lib) types;
    inherit (hyprLib) mkSubmodule;
  in {
    options.windowRules = lib.mkOption {
      type = types.listOf (mkSubmodule {
          config = true;
        }
        {
          options = {
            name = lib.mkOption {
              type = types.str;
            };
            match = lib.mkOption {
              default = {};
              type = let
                inherit (hyprLib) typedOpt;
                str = typedOpt types.str;
                bool = typedOpt types.bool;
              in
                # fill this in whenever new match rule gets used
                types.submodule {
                  options = {
                    class = str;
                    title = str;
                    xwayland = bool;
                    float = bool;
                    floating = bool;
                    fullscreen = bool;
                    pin = bool;
                    workspace = str;
                    tag = str;
                    content = typedOpt (hyprLib.namedEnumList ["none" "photo" "video" "game"]);
                  };
                };
            };
          };
        });
    };
    config.land.windowrule = let
      mapRule = rule: let
        mapMatches = matches:
          matches
          |> lib.filterAttrs (_: v: v != null)
          |> lib.mapAttrs' (n: v: lib.nameValuePair "match:${n}" (nixonLib.dag.entryAfter ["name"] v));

        effects =
          rule
          |> (x: builtins.removeAttrs x ["name" "match" "assertions"])
          |> builtins.mapAttrs (_: nixonLib.dag.entryAfter ["name" "match"]);
      in
        lib.mergeAttrsList [
          {name = nixonLib.dag.entryAnywhere rule.name;}
          (rule.match |> mapMatches)
          effects
        ];
    in
      config.windowRules
      |> builtins.map (
        rule:
          rule
          |> mapRule
          |> nixonLib.dag.mkDag
      );

    config.assertions = nixonLib.assertions.propagateAssertions [
      config.windowRules
    ];
  };
}
