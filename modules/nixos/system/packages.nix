{
  config,
  lib,
  pkgs,
  options,
  flake,
  ...
}: let
  inherit (lib) mkEnableOption;
  cfg = config.nixon.packages;
in {
  options.nixon.packages = {
    enable = mkEnableOption "packages";
    system.enable = (mkEnableOption "system") // {default = true;};
    wrapped.enable = (mkEnableOption "wrapped") // {default = true;};
  };
  config = (lib.mkIf cfg.enable) {
    warnings = lib.optionals (!cfg.system.enable && !cfg.wrapped.enable) [
      ''
        You have disabled both nixon.packages.system and nixon.packages.wrappedA.
        This means no actual packages will be added to your systemPackages.
      ''
    ];
    environment.systemPackages = lib.optionals (cfg.system.enable) (builtins.attrValues pkgs.nixon.systemPackages);
    wrapper-manager = {
      packages = flake.wrapperManagerModules.list-flat;
      sharedModules = [flake.wrapperManagerModules.options];
      extraSpecialArgs = {
        inherit flake;
        inherit (flake.lib) theme;
      };
      enableInstall = cfg.wrapped.enable;
    };
  };
}
