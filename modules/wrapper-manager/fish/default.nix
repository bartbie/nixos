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

  kanagawa = pkgs.writeText "kanagawa.fish" (import ./kanagawa.nix inputs);

  config =
    writeVendorConf "bartbie_config.fish"
    # fish
    ''
      source ${./load_plugin.fish}
      ${mapPlugins plugins}

      fenv source /etc/profile

      if status is-interactive
          source ${./pushd_mod.fish}

          ${builtins.readFile ./interactive.fish}

          source ${kanagawa}

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
    xdg.dataDirs = wrapperManagerLib.getXdgDataDirs [config];
  };
}
