{
  config,
  lib,
  pkgs,
  options,
  ...
}: let
  inherit (lib) mkEnableOption;
  cfg = config.nixon.programs.git;
in {
  options.nixon.programs.git = {
    enable = mkEnableOption "git";
    jj = {
      enable = mkEnableOption "jj";
    };
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
