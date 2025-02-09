{
  config,
  lib,
  pkgs,
  options,
  ...
}: let
  inherit (lib) mkEnableOption;
  cfg = config.nixon;
in {
  options.nixon.zoxide.enable = mkEnableOption "zoxide";
  options.nixon.lsd.enable = mkEnableOption "lsd";
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
