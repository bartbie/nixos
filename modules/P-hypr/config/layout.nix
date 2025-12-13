{
  flake.modules.hypr.layout = {
    layout = "dwindle";
    land = {
      general = {
        no_focus_fallback = true;
      };
      dwindle = {
        pseudotile = true;
        preserve_split = true;
      };
      input.follow_mouse = 1;
      binds = {
        allow_workspace_cycles = true;
      };
    };
  };
}
