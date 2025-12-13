{
  flake.modules.hypr.fullscreen = {...}: {
    land.misc.on_focus_under_fullscreen = 2;
    windowRules = [
      {
        # Ignore maximize requests from apps.
        name = "ignore-maximize";
        match = {
          class = ".*";
        };
        suppress_event = "maximize";
      }
    ];
  };
}
