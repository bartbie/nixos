{
  config,
  lib,
  pkgs,
  options,
  ...
}: let
  inherit (lib) mkEnableOption;
  cfg = config.nixon.ssh;
in {
  options.nixon.ssh = {
    enable = mkEnableOption "ssh";
  };
  config = lib.mkIf cfg.enable {
    services.openssh.enable = true;
  };
}
