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
      pager = ":builtin";
    };
    aliases = let
      split = lib.flip lib.pipe [
        (builtins.split " ")
        (builtins.filter (x: x != "" && x != []))
      ];
      mapSplit = lib.attrsets.mapAttrs (_: split);
    in
      mapSplit {
        wip = "commit -m WIP";
        anc = "log -r anc(5)";
        slast = "show -r anc(2)~@";
      };
    revset-aliases = {
      "anc(x)" = "ancestors(@, x)";
    };
  };
in {
  wrappers.jujutsu = {
    executableName = "jj";
    arg0 = lib.getExe' pkgs.jujutsu "jj";
    env.JJ_CONFIG.value = "${generate "jujutsu-config.toml" config}";
  };
}
