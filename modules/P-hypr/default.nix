{
  lib,
  config,
  ...
}: {
  flake.modules.nixos.hypr = {
    pkgs,
    self',
    ...
  }: let
    package = self'.packages.hypr;
  in {
    programs.hyprland = {
      inherit package;
      enable = true;
      withUWSM = true;
    };
    xdg.portal.config.hyprland = {
      default = ["hyprland" "gtk"];
    };
    environment.systemPackages = package.passthru.runtimeInputs;
  };
  wrapped.hypr = {
    systems = config.meta.systemsNoDarwin;
    module = {
      pkgs,
      pkgs-unstable,
      nixonLib,
      theme,
      overrideArgs,
      self',
      wrapperManagerLib,
      ...
    }: let
      config = pkgs.callPackage ./_hyprland-config.nix {
        inherit nixonLib theme;
        inherit
          (self'.packages)
          alacritty
          waybar
          # TODO:
          rand-wp
          ;
      };
    in {
      single = {
        package =
          {wrapRuntimeDeps = false;}
          |> pkgs-unstable.hyprland.override
          |> (x: x.override overrideArgs);
        wrapper = {
          prependArgs = ["--config" config];
          pathAdd = wrapperManagerLib.getBin [
            pkgs.binutils
            pkgs-unstable.hyprland-qtutils
            pkgs.pciutils
            pkgs.pkgconf
          ];
        };
      };
      build.extraPassthru = {
        inherit (config.passthru) runtimeInputs;
        configDrv = config;
      };
    };
  };
}
