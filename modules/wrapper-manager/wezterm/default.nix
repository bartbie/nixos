{
  pkgs,
  lib,
  theme,
  ...
}: let
  c = theme.colors.by-name-flat;

  concatCols = lib.flip lib.pipe [
    (builtins.map lib.strings.escapeNixString)
    (builtins.concatStringsSep ", ")
  ];

  config =
    pkgs.writeText "wezterm.lua"
    #lua
    ''
      local colors = {
         foreground = "${c.foreground}",
         background = "${c.background}",

         cursor_bg = "${c.White}",
         cursor_fg = "${c.White}",
         cursor_border = "${c.White}",

         selection_fg = "${c.White}",
         selection_bg = "${c."selection background"}",

         scrollbar_thumb = "${c.split}",
         split = "${c.split}",

         ansi = { ${concatCols theme.colors.list.ansi} },
         brights = { ${concatCols theme.colors.list.brights} },
         indexed = { [16] = "${c.Orange}", [17] = "${c."Peach Red"}" },
      };

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
  wrappers.wezterm = {
    arg0 = lib.getExe' pkgs.unstable.wezterm "wezterm";
    env.WEZTERM_CONFIG_FILE.value = config;
  };
}
