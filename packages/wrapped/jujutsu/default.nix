{
  pkgs,
  lib,
  ...
}: let
  inherit (pkgs.formats.toml {}) generate;
  config = {
    user = {
      name = "bartbie";
      email = "bartbie37@gmail.com";
    };
    ui = {
      default-command = "status";
      editor = "nvim";
    };
    aliases = let
      split = lib.flip lib.pipe [
        (builtins.split " ")
        (builtins.filter (x: x != "" && x != []))
      ];
    in {
      wip = split "commit -m WIP";
      anc = split "log -r anc(5)";
    };
    revset-aliases = {
      "anc(x)" = "ancestors(@, x)";
    };
  };
in {
  wrappers.jujutsu = {
    basePackage = pkgs.unstable.jujutsu;
    env.JJ_CONFIG.value = "${generate "jujutsu-config.toml" config}";
  };
}
