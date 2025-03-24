{
  pkgs,
  lib,
  wrapperManagerLib,
  ...
} @ inputs: let
  writeVendor = type: x: pkgs.writeTextDir "share/fish/vendor_${type}.d/${x}";
  writeVendorConf = writeVendor "conf";

  plugins = builtins.attrValues {
    inherit
      (pkgs.fishPlugins)
      foreign-env
      fzf-fish
      ;
  };

  mapPlugins = lib.flip lib.pipe [
    (map (elem: "bartbie_load_plugin ${elem}"))
    (lib.concatStringsSep "\n")
  ];

  starship-config = (pkgs.formats.toml {}).generate "starship.toml" (import ./starship.nix inputs);

  direnv-config = pkgs.writeTextDir "direnvrc" ''
    source ${pkgs.nix-direnv}/share/nix-direnv/direnvrc
  '';

  config =
    writeVendorConf "bartbie_config.fish"
    # fish
    ''
      ${mapPlugins plugins}

      fenv source /etc/profile

      if status is-interactive
          ${builtins.readFile ./interactive.fish}

          set -gx STARSHIP_CONFIG ${starship-config}
          ${lib.getExe pkgs.starship} init fish | source

          set -gx DIRENV_LOG_FORMAT "" # disables direnv logging
          set -gx direnv_config_dir ${direnv-config}
          ${lib.getExe pkgs.direnv} hook fish | source
      end
    '';
in {
  wrappers.fish = {
    arg0 = lib.getExe' pkgs.fish "fish";
    xdg.dataDirs = wrapperManagerLib.getXdgDataDirs [
      (writeVendorConf "load_plugin.fish" (builtins.readFile ./load_plugin.fish))
      (writeVendorConf "kanagawa.fish" (builtins.readFile ./kanagawa.fish))
      config
    ];
  };
}
