{
  config,
  lib,
  pkgs,
  options,
  ...
}: let
  inherit (lib) mkEnableOption;
  cfg = config.nixon.programs;
in {
  options.nixon.programs.zoxide.enable = mkEnableOption "zoxide";
  options.nixon.programs.lsd.enable = mkEnableOption "lsd";
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
