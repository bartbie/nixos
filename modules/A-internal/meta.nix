{
  lib,
  options,
  ...
}@args:
let
  global = args.config;
  t = lib.types;

  mkMarker =
    type:
    lib.mkOption {
      inherit type;
      readOnly = true;
    };

  mkSetter =
    type:
    lib.mkOption {
      inherit type;
      internal = true;
    };

  mkGlobal =
    type: default:
    lib.mkOption {
      inherit type default;
      readOnly = true;
    };

  mapGlobal =
    opt: rest:
    lib.mkOption (
      {
        inherit (opt) type;
        default = opt.value;
      }
      // rest
    );

  mapGlobals =
    opts: rest: opts |> lib.mapAttrsRecursiveCond (x: !(lib.isOption x)) (_: opts: mapGlobal opts rest);
in
{
  options.meta = {
    # Filter out darwin from flake-parts' config.systems
    systemsNoDarwin = mkGlobal (t.listOf t.str) (
      global.systems |> builtins.filter (s: (builtins.match "darwin" s) == null)
    );
  };
  config = {
    flake.modules.generic.meta = {
      imports = [
        # Add globals from flake scope to inner scopes
        { options.meta = mapGlobals options.meta { readOnly = true; }; }
        # Add overridable owner
        { options.meta.owner = mapGlobals options.meta.defaultOwner { }; }
        # Add overridable flakePath
        { options.meta.flakePath = mapGlobal options.meta.defaultFlakePath { }; }
      ];
    };
    hosts.shared =
      # Set host metadata
      { config, ... }:
      {
        options.meta = {
          _host = mkSetter (t.attrsOf t.anything);
          tags = mkMarker (t.listOf t.str);
          class = mkMarker (t: t.str);
        };
        config.meta = {
          inherit (config.meta._host) tags class;
        };
      };
  };
}
