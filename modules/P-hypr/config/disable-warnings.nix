{
  flake.modules.hypr.disable-warnings.land = {
    debug.suppress_errors = true; # checked in installCheck phase
    misc.disable_watchdog_warning = true; # uwsm is used instead
  };
}
