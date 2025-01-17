{
  config,
  lib,
  pkgs,
  options,
  ...
}: let
  inherit (lib) mkOption types;
  cfg = config.user._TEMPLATE;
in {
  options.user._TEMPLATE = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Whether to enable _TEMPLATE system configuration.";
    };
  };
  config =
    lib.mkIf cfg.enable {
    };
}
