{config, ...}: let
  mods = modules: {inherit modules;};
in {
  config.easy-hosts = {
    shared.modules = [
      config.hosts.shared
      config.flake.modules.generic.meta
    ];

    perHost = h:
      mods [
        # load our host-specific config in form of flake-parts.modules module
        (config.hosts.${h.class}.${h.name} or {})
        # pass metadata to our configs
        {
          meta._host = h;
        }
      ];
    perClass = class:
      mods [
        # load base of our config
        (config.flake.modules.${class}.base or {})
      ];
  };
}
