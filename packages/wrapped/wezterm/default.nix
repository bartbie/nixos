{pkgs, ...}: {
  wrappers.wezterm = {
    basePackage = pkgs.unstable.wezterm;
    env.WEZTERM_CONFIG_FILE.value = "${./wezterm.lua}";
  };
}
