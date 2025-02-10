{
  config,
  lib,
  pkgs,
  options,
  ...
}: let
  inherit (lib) mkEnableOption;
  cfg = config.nixon.git;
in {
  options.nixon.git = {
    enable = mkEnableOption "git";
  };
  config = lib.mkIf cfg.enable {
    programs.git = {
      enable = true;
      config = {
        user = {
          name = "bartbie";
          email = "bartbie37@gmail.com";
        };
        init = {defaultBranch = "main";};
      };
    };
  };
}
