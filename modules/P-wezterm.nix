{lib, ...}: {
  wrapped.wezterm.module = {
    pkgs,
    pkgs-unstable,
    theme,
    ...
  }: let
    colors = let
      inherit (theme.termcolors.simple) area lists indexed;
      concat-indexed = lib.pipe indexed [
        (builtins.mapAttrs (_: lib.strings.escapeNixString))
        (pkgs-unstable.lib.concatMapAttrsStringSep ", " (n: v: "[${n}] = ${v}"))
      ];
    in
      lib.generators.toLua {} {
        foreground = area.primary.fg;
        background = area.primary.bg;

        cursor_bg = area.cursor.bg;
        cursor_fg = area.cursor.fg;
        cursor_border = area.cursor.border;

        selection_bg = area.selection.bg;

        split = area.split;
        scrollbar_thumb = area.scrollbar.thumb;

        ansi = lists.ansi;
        brights = lists.brights;
        indexed = lib.generators.mkLuaInline "{${concat-indexed}}";
      };

    config =
      pkgs.writeText "wezterm.lua"
      #lua
      ''
        local colors = ${colors}

        local wezterm = require("wezterm");
        return {
            hide_tab_bar_if_only_one_tab = true, -- i never use tabs but it may happen accidentally
            -- enable_tab_bar = false,
            window_background_opacity = 0.96,
            -- color_scheme = "kanagawabones",
            -- color_scheme = "Kanagawa (Gogh)",
            font = wezterm.font("JetBrains Mono Nerd Font"),
            colors = colors,
        };
      '';
  in {
    single = {
      package = pkgs-unstable.wezterm;
      wrapper = {
        env.WEZTERM_CONFIG_FILE.value = config;
      };
    };
  };
}
