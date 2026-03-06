let
  pc =
    { pkgs, ... }:
    {
      fonts = {
        packages = builtins.attrValues {
          inherit (pkgs)
            noto-fonts
            noto-fonts-cjk-sans
            noto-fonts-color-emoji
            atkinson-hyperlegible-next
            twemoji-color-font
            charis-sil
            dejavu_fonts
            ;
          inherit (pkgs.nerd-fonts)
            jetbrains-mono
            terminess-ttf
            ;
        };
        enableDefaultPackages = false;
        fontconfig = {
          defaultFonts =
            let
              emoji = [
                "twemoji-color-font"
                "Noto Color Emoji"
              ];
            in
            {
              inherit emoji;
              monospace = [
                "JetBrainsMono Nerd Font"
                "JetBrainsMono"
                "Noto Sans Symbols 2" # braille etc. fallback
              ]
              ++ emoji;
              sansSerif = [
                "Atkinson Hyperlegible Next"
                "Atkinson Hyperlegible"
                "Noto Sans"
              ];
              serif = [
                "Charis Sil"
                "Noto Serif"
              ];
            };
        };
      };
    };
in
{
  flake.modules.nixos.pc = pc;
  flake.modules.darwin.base = pc;
}
