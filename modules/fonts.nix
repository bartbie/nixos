{
  config,
  lib,
  pkgs,
  options,
  ...
}: let
  inherit (lib) mkEnableOption;
  cfg = config.nixon.fonts;
in {
  options.nixon.fonts = {
    enable = mkEnableOption "fonts";
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
