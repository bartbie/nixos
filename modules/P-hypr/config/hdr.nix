{
  flake.modules.hypr.hdr = {
    config,
    lib,
    hyprLib,
    ...
  }: let
    inherit (hyprLib) typed namedEnumList;
  in {
    options.hdr.enable = lib.mkEnableOption "hdr";

    options.land = {
      render = {
        cm_fs_passthrough = typed (namedEnumList ["off" "always" "hdr-only"]) // {default = "hdr-only";};
        # Auto-switch to HDR in fullscreen when needed.
        cm_auto_hdr = typed (namedEnumList ["off" "hdr" "hdredid"]) // {default = "hdr";};
      };
      quirks.prefer_hdr = typed (namedEnumList ["off" "always" "gamescope-only"]) // {default = "off";};
    };

    config.land = lib.mkIf config.hdr.enable {
      quirks.prefer_hdr = "always";
    };
  };
}
