# we need to have a way of marking which wrappers should be added to nixon's overlay and packages
# we will hack this by adding our own option and reading the output config in packagesCustom
{lib, ...}: let
  inherit (lib) types;
in {
  options.nixon = {
    standalonePackages = lib.mkOption {
      type = types.nullOr (types.listOf types.str);
      default = null;
      description = ''
        Mark which wrappers should be added to `nixon.custom` overlay and flake's packages.
        `null` will make make it use folder's name when looking for a wrapper.
      '';
    };
    overrideAttrs = let
      oattrs = types.attrsOf types.anything;
    in
      lib.mkOption {
        type = types.either oattrs (types.functionTo (types.functionTo oattrs));
        default = {};
        description = ''
          Add extra custom overrideAttrs to build pipeline.
        '';
      };
  };
}
