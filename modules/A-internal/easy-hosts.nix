{
  lib,
  config,
  ...
}: let
  mods = modules: {inherit modules;};
in {
  config.easy-hosts = {
    shared.modules = [
      config.hosts.shared
      config.flake.modules.generic.meta
    ];

    perHost = {
      class,
      tags,
      name,
      ...
    } @ host:
      mods [
        # load base of our config
        (config.flake.modules.${class}.base or {})
        # load our host-specific config in form of flake-parts.modules module
        (config.hosts.${class}.${name} or {})
        # Auto-add modules matching host's tags
        {
          imports =
            tags
            |> builtins.map (
              tag: [
                config.flake.modules.${class}.${tag} or []
                config.flake.modules.generic.${tag} or []
              ]
            )
            |> lib.flatten;
        }
        # pass metadata to our configs
        {
          meta._host = host;
        }
      ];
  };
}
