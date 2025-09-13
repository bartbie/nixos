{
  wrapped.zellij = {
    tags = null;
    module = {pkgs-unstable, ...}: {
      single = {
        package = pkgs-unstable.zellij;
        wrapper = {
          env.ZELLIJ_CONFIG_FILE.value = ./config.kdl;
        };
      };
    };
  };
}
