{
  lib,
  config,
  ...
}:
let
  jj-config = {
    user = {
      inherit (config.meta.defaultOwner.git) name email;
    };
    ui = {
      default-command = "status";
      editor = "nvim";
      pager = ":builtin";
    };
    aliases =
      let
        split =
          x:
          if builtins.isList x then
            x
          else
            assert builtins.isString x;
            x |> (builtins.split " ") |> (builtins.filter (x: x != "" && x != [ ]));

        mapSplit = lib.attrsets.mapAttrs (_: split);
      in
      mapSplit {
        wip = "commit -m WIP";
        anc = "log -r anc(5)";
        slast = "show -r anc(2)~@";
        rdown = "rebase -r @ --before anc(2)~@";
        rup = "rebase -r @ --after desc(2)~@";
        tug = [
          "bookmark"
          "move"
          "--from"
          "heads(::@- & bookmarks())"
          "--to"
          "@-"
        ];
        rebase-all = [
          "rebase"
          "-s"
          "all:roots(trunk()..mutable())"
          "-d"
          "trunk()"
        ];
      };
    revset-aliases = {
      "anc(x)" = "ancestors(@, x)";
      "desc(x)" = "descendants(@, x)";
      "wip()" = ''description(regex:"wip|WIP:?.*")'';
      "muttrunk()" = ''mutable() & trunk()::'';
    };
    template-aliases = {
      "in_branch(commit)" = ''commit.contained_in("immutable_heads()..bookmarks()")'';
    };
    templates = {
      log_node = ''
        if(self && !current_working_copy && !immutable && !conflict && in_branch(self),
          "◇",
          builtin_log_node
        )
      '';
    };
  };
in
{
  wrapped.jujutsu = {
    tags = null;
    module =
      {
        pkgs,
        pkgs-unstable,
        ...
      }:
      {
        single = {
          package = pkgs-unstable.jujutsu;
          wrapper = {
            env.JJ_CONFIG.value = (pkgs.formats.toml { }).generate "jujutsu-config.toml" jj-config;
          };
        };
      };
  };
}
