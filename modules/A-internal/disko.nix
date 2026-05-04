{ lib, config, ... }:
{
  # HACK:
  # disko option expects entire thing to be unique
  # ie every disko config defined in one module
  # we dont want that
  options = {
    diskoCfgs = lib.mkOption {
      type = lib.types.lazyAttrsOf lib.types.raw;
    };
  };
  config.flake.diskoConfigurations = config.diskoCfgs;

}
