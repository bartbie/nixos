{pkgs, ...}: let
  inherit (pkgs.formats.toml {}) generate;
  config = {
    user = {
      name = "bartbie";
      email = "bartbie37@gmail.com";
    };
    ui = {
      default-command = "status";
      editor = "nvim";
    };
  };
in {
  wrappers.jujutsu = {
    basePackage = pkgs.unstable.jujutsu;
    env.JJ_CONFIG.value = "${generate "jujutsu-config.toml" config}";
  };
}
