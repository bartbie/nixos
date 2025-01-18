{
  config,
  lib,
  pkgs,
  options,
  ...
}: let
  inherit (lib) mkOption types;
  cfg = config.user;
  mkEnable = name:
    mkOption {
      type = types.bool;
      default = false;
      description = "Whether to enable ${name} system configuration.";
    };
in {
  options.user.zoxide.enable = mkEnable "zoxide";
  options.user.lsd.enable = mkEnable "lsd";
  config =
    lib.mkIf cfg.zoxide.enable
    (let
      package = pkgs.zoxide;
    in {
      environment.systemPackages = [package];
      programs.fish.interactiveShellInit = lib.mkAfter ''
        ${package}/bin/zoxide init fish | source
      '';
    })
    // lib.mkIf cfg.lsd.enable {
      environment.systemPackages = [pkgs.lsd];
    };
}
