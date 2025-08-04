{
  lib,
  config,
  options,
  ...
}: let
in {
  # override easy-hosts.hosts to attach hosts.<name>.add ootion
  options.easy-hosts.hosts = let
    mods = config.flake.modules;
    old = options.easy-hosts.hosts;
    patch = {config, ...}: {
      options.add = lib.mkOption {
        type = lib.types.functionTo (lib.types.listOf lib.types.deferredModule);
        default = _: [];
      };
      config.modules = config.add (mods.${config.class} or {});
    };
    opt = lib.mkOption (
      old // {type = lib.types.attrsOf (lib.types.submodule (old.type.getSubModules ++ [patch]));}
    );
  in
    lib.mkForce opt;

  flake.modules = {
    nixos.pc = {};
    darwin.base = {};
  };
}
