{
  lib,
  theme,
  ...
}:
{
  flake.modules.nixos.base =
    {
      config,
      pkgs,
      self',
      ...
    }:
    {
      system.nixos.variantName = "Nixon";

      environment.etc.issue.enable = lib.mkForce false;

      system.activationScripts.update-issue = {
        text = # bash
          ''
            ${self'.packages.garden}/bin/garden info issue \
            --variant-name ${config.system.nixos.variantName} \
            --hostname ${config.networking.hostName} \
            --write
          '';
      };
    };

  flake.modules.nixos.pc =
    { pkgs, ... }:
    {
      boot = {
        loader = {
          systemd-boot = {
            enable = lib.mkDefault true;
            configurationLimit = 10;
            consoleMode = "max";
            # consoleMode = "auto";
          };
        };

        kernelPackages = lib.mkDefault pkgs.linuxPackages_latest;
      };
      # console.colors = let
      #   colors = theme.termcolors.simple.lists;
      # in
      #   (colors.ansi ++ colors.brights)
      #   |> builtins.map (lib.removePrefix "#");
    };
}
