{
  pkgs,
  lib,
  theme,
  ...
}: let
  removeHash = lib.flip lib.pipe [
    (lib.splitString "#")
    lib.reverseList
    builtins.head
  ];
  c = lib.mapAttrs (_: removeHash) theme.colors.by-name-flat;
in
  # fish
  ''
    set -l foreground ${c."Bright White"}
    set -l selection ${c."Blue"}
    set -l comment ${c."Bright Black"}
    set -l red ${c."Red"}
    set -l orange ${c."Orange"}
    set -l yellow ${c."Yellow"}
    set -l green ${c."Green"}
    set -l purple ${c."Magenta"}
    set -l cyan ${c."Bright Cyan"}
    set -l pink ${c."Pink"}

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
