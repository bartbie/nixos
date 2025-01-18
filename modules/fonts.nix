{
  config,
  lib,
  pkgs,
  options,
  ...
}: let
  inherit (lib) mkOption types;
  cfg = config.user.fonts;
in {
  options.user.fonts = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Whether to enable fonts system configuration.";
    };
  };
  config = lib.mkIf cfg.enable {
    fonts = {
      packages =
        lib.attrValues {
          inherit
            (pkgs)
            noto-fonts
            noto-fonts-cjk-sans
            noto-fonts-emoji
            ;
        }
        ++ [
          (pkgs.nerdfonts.override {fonts = ["JetBrainsMono" "Terminus"];})
        ];
      fontconfig = {
        defaultFonts = {
          monospace = [
            "JetBrainsMono"
            "JetBrainsMono Nerd Font"
            "Noto Color Emoji"
          ];
          emoji = ["Noto Color Emoji"];
        };
      };
    };
  };
}
