{
  pkgs,
  lib,
  ...
}: let
  config = {
    user = {
      name = "bartbie";
      email = "bartbie37@gmail.com";
    };
    init = {defaultBranch = "main";};
  };
  config-file = pkgs.writeText "gitconfig" (lib.generators.toGitINI config);
in {
  wrappers.git = {
    arg0 = lib.getExe' pkgs.git "git";
    env.GIT_CONFIG_GLOBAL.value = config-file;
  };
}
