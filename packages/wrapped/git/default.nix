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
    basePackage = pkgs.git;
    env.GIT_CONFIG_GLOBAL.value = config-file;
  };
}
