{
  lib,
  config,
  ...
}:
let
  git-config = {
    user = {
      inherit (config.meta.defaultOwner.git) name email;
    };
    init = {
      defaultBranch = "main";
    };
  };
in
{
  wrapped.git = {
    tags = null;
    module =
      { pkgs, ... }:
      {
        single = {
          package = pkgs.git;
          wrapper = {
            env.GIT_CONFIG_GLOBAL.value = pkgs.writeText "gitconfig" (lib.generators.toGitINI git-config);
          };
        };
      };
  };
}
