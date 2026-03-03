{
  pkgs,
  lib,
  theme,
  ...
}:
let
  inherit (theme.termcolors) simple;
  removeHash = lib.flip lib.pipe [
    (lib.splitString "#")
    lib.reverseList
    builtins.head
  ];

  c = lib.mapAttrsRecursive (_: removeHash) simple;
in
# fish
''
  set -l foreground ${c.area.primary.fg}
  set -l selection ${c.area.selection.bg}
  set -l comment ${c.area.comment}
  set -l red ${c.ansi.red}
  set -l yellow ${c.ansi.yellow}
  set -l green ${c.ansi.green}
  set -l purple ${c.ansi.magenta}
  set -l cyan ${c.brights.cyan}
  set -l pink ${c.rest."Pink"}
  set -l orange ${c.rest."Orange"}

  # Syntax Highlighting Colors
  set -gx fish_color_normal $foreground
  set -gx fish_color_command $cyan
  set -gx fish_color_keyword $pink
  set -gx fish_color_quote $yellow
  set -gx fish_color_redirection $foreground
  set -gx fish_color_end $orange
  set -gx fish_color_error $red
  set -gx fish_color_param $purple
  set -gx fish_color_comment $comment
  set -gx fish_color_selection --background=$selection
  set -gx fish_color_search_match --background=$selection
  set -gx fish_color_operator $green
  set -gx fish_color_escape $pink
  set -gx fish_color_autosuggestion $comment

  # Completion Pager Colors
  set -gx fish_pager_color_progress $comment
  set -gx fish_pager_color_prefix $cyan
  set -gx fish_pager_color_completion $foreground
  set -gx fish_pager_color_description $comment
  set -gx fish_pager_color_selected_background --background=$selection
''
