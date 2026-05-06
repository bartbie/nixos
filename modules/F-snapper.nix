{
  flake.modules.nixos.snapper-persist =
    { config, ... }:
    {
      services.snapper = {
        configs.persist = {
          SUBVOLUME = "/persist";
          ALLOW_GROUPS = [ "wheel" ];
          TIMELINE_CREATE = true;
          TIMELINE_CLEANUP = true;
          TIMELINE_LIMIT_HOURLY = 24;
          TIMELINE_LIMIT_DAILY = 7;
          TIMELINE_LIMIT_WEEKLY = 4;
          TIMELINE_LIMIT_MONTHLY = 6;
          TIMELINE_LIMIT_YEARLY = 0;
        };
      };
    };
}
