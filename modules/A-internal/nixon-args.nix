{ lib, ... }:
let
  module =
    { config, ... }:
    {
      options.nixonArgs = lib.mkOption {
        type = lib.types.lazyAttrsOf lib.types.raw;
        description = ''
          Defines nixonArgs added to specialArgs in this environment.
          Flake-parts environment passes its nixonArgs down.
        '';
        default = { };
      };
      config._module.args = config.nixonArgs // {
        inherit (config) nixonArgs;
      };
    };
in
{
  imports = [
    module
    (
      { config, ... }:
      {
        perSystem = { inherit (config) nixonArgs; };
        hosts.shared = { inherit (config) nixonArgs; };
      }
    )
  ];
  perSystem = module;
  hosts.shared = module;
}
