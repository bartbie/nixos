{
  flake.modules.hypr.touchpad.land = {
    input.touchpad = {
      # macbook-like
      natural_scroll = true;
      clickfinger_behavior = true;
    };
    gesture = [
      "3, horizontal, workspace"
    ];
  };
}
