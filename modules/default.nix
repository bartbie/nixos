{
  config,
  lib,
  pkgs,
  options,
  ...
}: let
  inherit (lib) mkEnableOption;
  cfg = config.nixon.core;
  findImports = ignore: let
    fs = lib.fileset;
    filterNonNix = f: (f.hasExt "nix") && !(lib.hasPrefix "_" f.name);
    ignore' =
      if lib.isList ignore
      then ignore
      else [ignore];
  in
    fs.toList (fs.difference (fs.fileFilter filterNonNix ./.) (fs.unions ([./default.nix] ++ ignore')));
in {
  imports = findImports [];
  options.nixon.core.enable = mkEnableOption "core";
  config.nixon = let
    tru = lib.mkDefault true;
    fal = lib.mkDefault false;
  in
    lib.mkIf cfg.enable
    {
      base.enable = tru;
      net.enable = tru;
      nix.enable = tru;
      audio.enable = tru;
      audio.bluetooth.enable = tru;
      fonts.enable = tru;
      packages.enable = tru;

      git.enable = tru;
      fish.enable = tru;
      direnv.enable = tru;
      zoxide.enable = tru;
      lsd.enable = tru;
      tmux.enable = tru;
      starship.enable = tru;
      firefox.enable = tru;

      plasma5.enable = tru;

      hypr.enable = fal;
    };
}
