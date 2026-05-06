{
  lib,
  config,
  nixonLib,
  ...
}:
{
  wrapped.jujutsu = {
    tags = null;
    module =
      {
        pkgs,
        pkgs-unstable,
        ...
      }:
      let
        split =
          x:
          if builtins.isList x then
            x
          else
            assert builtins.isString x;
            x |> (builtins.split " ") |> (builtins.filter (x: x != "" && x != [ ]));

        mapSplit =
          x:
          let
            aliases = x |> lib.flatten |> lib.mergeAttrsList |> lib.attrsets.mapAttrs (_: split);
            aliasNames =
              aliases
              |> builtins.attrNames
              |> (x: x ++ [ "help-custom" ])
              |> lib.lists.naturalSort
              |> lib.join "\n";
          in
          aliases
          // {
            help-custom = (exec "echo '${aliasNames}'");
          };

        exec = s: [
          "util"
          "exec"
          "--"
          "bash"
          "-c"
          s
          "--"
        ];

        tagAliasFor = tag: {
          "${tag}()" = ''description(regex:'\[${tag}\]:?.*') | bookmarks(regex:'^${tag}/.*')'';
        };

        mkExec =
          name:
          (nixonLib.scriptsPath + /${name}.sh)
          |> builtins.readFile
          |> pkgs.writers.writeBashBin name
          |> lib.getExe
          |> exec;

        jj-config = {
          user = {
            inherit (config.meta.defaultOwner.git) name email;
          };
          ui = {
            default-command = "status";
            editor = "nvim";
            pager = ":builtin";
          };
          git.private-commits = "blocked()";
          revsets.log = "present(@) | ancestors(immutable_heads().., 2) | trunk() | base()";
          aliases = mapSplit [
            {
              wip = "commit -m [wip]";
              anc = "log -r anc(5)";
              slast = "show -r anc(2)~@";

              rdown = "rebase -r @ --before anc(2)~@";
              rup = "rebase -r @ --after desc(2)~@";

              logb = "log -r base()::";

              tug = [
                "bookmark"
                "move"
                "--from"
                "heads(::@- & movable_bookmarks()) ~ anchors()"
                "--to"
                # (heads(movable_bookmarks() & ::@-)..@-) = commits of (top bookmark)::@-
                # parent of (roots of blocking and those commits) or parents of @
                "coalesce(roots(blocking() & (heads(movable_bookmarks() & ::@-)..@-))-, heads(::@-))"
              ];

              rebase-all = [
                "rebase"
                "-s"
                "roots(trunk()..mutable())"
                "-d"
                "trunk()"
              ];

              rebase-wip = [
                "rebase"
                "-s"
                "roots(wip() & mutable())"
                "-d"
                "trunk()"
              ];

              rebase-stack = [
                "rebase"
                "-s"
                "roots(stack() & mutable())"
                "-d"
                "trunk()"
              ];

              strip = [
                "abandon"
                "-r"
                "mutable() & stack() & empty() & description(exact:\"\")"
              ];

              strip-base = [
                "abandon"
                "-r"
                ''(mutable() & base():: & mine() & empty() & description(exact:""))~(base():: & ~mine())::''
              ];

              strip-all = [
                "abandon"
                "-r"
                ''(mutable() & mine() & empty() & description(exact:""))~(~mine())::''
              ];

              op-restore = exec "jj op restore $(jj op log --no-graph -T 'self.id() ++ \"\\n\"' | sed -n \"$(($1 + 1))p\")";

              anchor = exec "jj bookmark create \"anchor/$1\" -r \"\${2:-@}\"";
              anchors = "log -r anchors() -T anchor_line(self)";
              newa = exec ''jj new "anchor/$1"'';
              newb = [
                "new"
                "-r"
                "base()"
              ];

              log-empty = [
                "log"
                "-r"
                "mutable() & mine() & description(exact:\"\") ~ empty()"
                "--summary"
              ];

              stack = [
                "rebase"
                "--after"
                "trunk()"
                "--before"
                "closest_merge(@)"
                "--revision"
              ];

              stage = [
                "stack"
                "closest_merge(@)+:: ~ empty()"
              ];

              restack = [
                "rebase"
                "--onto"
                "trunk()"
                "--source"
                "roots(trunk()..) & mutable()"
                "--simplify-parents"
              ];

            }
            (
              let
                tags = [
                  "local"
                  "wip"
                  "private"
                ];
                inner-log = ''jj log -r "''${1:-@}" -T 'description' --no-graph'';
              in
              [
                (
                  tags
                  |> builtins.map (tag: {
                    "tag-${tag}" = exec ''jj describe -r "''${1:-@}" -m "[${tag}] $(${inner-log})"'';
                    "untag-${tag}" =
                      exec ''jj describe -r "''${1:-@}" -m "$(${inner-log} | sed 's/^\[${tag}\][[:space:]]*//')"'';
                  })
                )
                ({
                  untag = exec ''jj describe -r "''${1:-@}" -m "$(${inner-log} | sed 's/^\[(${tags |> lib.join "|"})\][[:space:]]*//')"'';
                })
              ]
            )
            ({

              bubble = mkExec "bubble";
              unbubble = mkExec "unbubble";

              bst = exec "jj bubble && jj strip && jj tug";

              newl = [
                "new"
                "-r"
                "local_base_tip()"
              ];

              plant = [
                "rebase"
                "-s"
                "@"
                "-d"
                "local_base_tip()"
              ];
            })
          ];
          revset-aliases = lib.mergeAttrsList [
            {
              "anc(x)" = "ancestors(@, x)";
              "desc(x)" = "descendants(@, x)";
            }
            (tagAliasFor "wip")
            (tagAliasFor "private")
            (tagAliasFor "local")
            {
              "T" = "trunk()";
              "TL" = "trunk()::";
              "anchors()" = "bookmarks(regex:'^anchor/.*')";
              "blocked()" = "local() | wip() | private() | anchors()";
              "blocking()" =
                "mutable() & (description(exact:'') | empty() | blocked() | conflicts() | divergent() | hidden())";
              "unpushable()" = "mutable() & blocking()::";
              "pushable()" = "mutable() ~ unpushable()";
              "movable_bookmarks()" = "bookmarks() ~ anchors()";
            }
            {
              "mainline()" = "::trunk()";

              "root_bases()" = "bookmarks() | immutable() | mainline()";
              "base(x)" = "coalesce(heads(::x & root_bases()), x)";
              "base()" = "base(@)";
              "mutbase(x)" = "mutable() & base(x)::";
              "mutbase()" = "mutbase(@)";

              "stack(x, y)" = "base(x)::y";
              "stack(x)" = "stack(x, x)";
              "stack()" = "stack(@)";

              "mutstack(x, y)" = "mutable() & stack(x, y)";
              "mutstack(x)" = "mutstack(x, x)";
              "mutstack()" = "mutstack(@)";

              "before_local(x)" = "coalesce(heads(mutbase(x)::local()-), base(x))";
              "after_local(x)" = "coalesce(roots(mutbase(x):: & local()+::x), x-)";
              "before_local()" = "before_local(@)";
              "after_local()" = "after_local(@)";

              # direct children of base that are continous chains of local()
              "local_base_tip(x)" = "heads(mutbase(x):: & local() ~ (mutbase(x)+:: ~ local())::)";
              "local_base_tip()" = "local_base_tip(@)";

              "closest_merge(to)" = "heads(::to & merges())";
              "closest_merge()" = "closest_merge(@)";
            }
          ];
          template-aliases = {
            "in_branch(commit)" = ''commit.contained_in("immutable_heads()..bookmarks()")'';
            "is_anchor(commit)" = ''commit.contained_in("anchors()")'';
            "is_blocking(commit)" = ''commit.contained_in("blocking()")'';
            "is_unpushable(commit)" = ''commit.contained_in("unpushable()")'';
            "is_bookmark(commit)" = ''commit.contained_in("bookmarks()")'';
            "is_base(c)" = ''c.contained_in("base()")'';
            "base(c)" = ''if(is_base(c), label("base", "base() "), "")'';
            "anchor_line(c)" =
              "c.change_id().short() ++ \" \" ++ c.bookmarks() ++ \" \" ++ c.description().first_line() ++ \"\\n\"";
          };
          templates = {
            redacted = "builtin_log_redacted";
            detailed = "builtin_log_detailed";
            log = "base(self) ++ builtin_log_compact";
            # ◇ in_branch  ❖ bookmark  ⊙ base  ◈ base+bookmark  (conflict/wc → builtin)
            #  ∅ blocking ⊘ blocked (unpushable)
            # TODO: add divergent in if
            log_node = ''
              coalesce(
                if(!self, builtin_log_node),
                if(current_working_copy || immutable || conflict, builtin_log_node),
                if(is_blocking(self), "∅"),
                if(is_unpushable(self), "⊘"),
                if(is_bookmark(self),
                    if(is_base(self), "◈", "❖")),
                if(is_base(self), "⊙"),
                if(in_branch(self), "◇"),
                builtin_log_node
              )
            '';

          };
          colors.base = "cyan";
        };
      in
      {
        single = {
          package = pkgs-unstable.jujutsu;
          wrapper = {
            env.JJ_CONFIG.value = (pkgs.formats.toml { }).generate "jujutsu-config.toml" (jj-config);
          };
        };
      };
  };
}
