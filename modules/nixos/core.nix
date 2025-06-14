{
  flake,
  config,
  lib,
  pkgs,
  options,
  ...
}: let
  inherit (lib) mkEnableOption;
  cfg = config.nixon.core;

  tru = lib.mkDefault true;
  fal = lib.mkDefault false;

  mk = b: {
    disableDarwin ? false,
    force ? false,
  } @ args: let
    state = args // {inherit (pkgs.stdenv) isDarwin;};
    mkFlag =
      if force
      then lib.mkForce
      else lib.mkDefault;
  in
    flake.lib.match state [
      [
        {
          disableDarwin = true;
          isDarwin = true;
        }
        false
      ]
      [{} (mkFlag b)]
      [{} (mkFlag b)]
    ];
in {
  imports = flake.lib.findImports {
    from = ./default.nix;
    ignored = [./core.nix];
    depth = 1;
    defaultOnly = false;
  };
  options.nixon.core.enable = mkEnableOption "core";
  config = {
    assertions = [
      {
        assertion = !(pkgs.stdenv.isDarwin && config.nixon.impernamence.enable);
        message = "Darwin doesn't support impernamence!";
      }
      {
        assertion = !(pkgs.stdenv.isDarwin && config.nixon.disko.enable);
        message = "Darwin doesn't support disko!";
      }
    ];

    nixon = lib.mkIf cfg.enable {
      base.enable = tru;
      audio = {
        enable = tru;
        bluetooth.enable = tru;
      };
      boot.enable = tru;
      fonts.enable = tru;
      net.enable = tru;
      nix.enable = tru;
      ssh.enable = tru;
      users.enable = tru;
      wayland.enable = mk true {disableDarwin = true;};

      packages.enable = tru;

      programs = {
        fish.enable = mk true {};
        firefox.enable = mk true {};
        hypr.enable = mk true {disableDarwin = true;};
        plasma5.enable = mk false {disableDarwin = true;};
      };
    };
  };
}
