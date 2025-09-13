{
  lib,
  config,
  ...
}: {
  wrapped.waybar = {
    systems = config.meta.systemsNoDarwin;
    module = {pkgs, ...}: {
      single = {
        package = pkgs.waybar;
        wrapper.prependArgs = [];
      };
    };
  };
}
