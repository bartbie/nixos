{
  flake.modules.hypr.xwayland = {
    land.xwayland = {
      force_zero_scaling = true;
    };
    windowRules = [
      {
        # Fix some dragging issues with XWayland
        name = "fix-drag-xwayland";
        match = {
          class = "^$";
          title = "^$";
          xwayland = true;
          float = true;
          fullscreen = false;
          pin = false;
        };
        no_focus = true;
      }
    ];
  };
}
