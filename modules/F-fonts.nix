let
  pc = {pkgs, ...}: {
    fonts = {
      packages = builtins.attrValues {
        inherit
          (pkgs)
          noto-fonts
          noto-fonts-cjk-sans
          noto-fonts-color-emoji
          ;
        inherit
          (pkgs.nerd-fonts)
          jetbrains-mono
          terminess-ttf
          ;
      };
      # ++ [
      #   (.override {fonts = ["JetBrainsMono" "Terminus"];})
      # ];
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
in {
  flake.modules.nixos.pc = pc;
  flake.modules.darwin.base = pc;
}
