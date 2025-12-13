{lib, ...}: {
  flake.modules.generic.assertions = {config, ...}: {
    key = "nixon-assertions";
    options = {
      assertions = lib.mkOption {
        type = lib.types.listOf (lib.types.submodule {
          options = {
            assertion = lib.mkOption {
              type = lib.types.bool;
            };
            message = lib.mkOption {
              type = lib.types.str;
            };
          };
        });
        default = [];
        internal = true;
        description = ''
          List of assertions to check after module evaluation.
        '';
      };
    };
  };
}
