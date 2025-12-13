{
  flake.modules.hypr.touchpad.land = {
    input.touchpad = {
      # macbook-like
      natural_scroll = true;
      clickfinger_behavior = true;
    };
    gestures = [
      "3, horizontal, workspace"
    ];
  };
}
