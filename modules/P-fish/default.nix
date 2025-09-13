{
  lib,
  theme,
  ...
}: let
  common = {
    pkgs,
    self',
    ...
  }: let
    package = self'.packages.fish;
  in {
    environment.systemPackages = [
      pkgs.nix-index
    ];
    programs.bash = {
      interactiveShellInit = let
        fish-cmd = lib.getExe' package "fish";
      in ''
        if [[ $(${lib.getExe' pkgs.procps "ps"} --no-header --pid=$PPID --format=comm) != "fish" && -z ''${BASH_EXECUTION_STRING} ]]
        then
          shopt -q login_shell && LOGIN_OPTION='--login' || LOGIN_OPTION=""
          export SHELL=${fish-cmd}
          exec ${fish-cmd} $LOGIN_OPTION
        fi
      '';
    };
  };
in {
  wrapped.fish = {
    tags = null;
    module = {
      pkgs,
      pkgs-unstable,
      wrapperManagerLib,
      nixonArgs,
      self',
      ...
    }: {
      single = {
        package =
          pkgs-unstable.fish
          #               .overrideAttrs (old: {
          #   # TODO: remove after fixed upstream
          #   patches = old.patches ++ [./files/4f46d369c4e9d7ea2f76290c6cb3a0882014eb4a.patch];
          # })
          ;
        wrapper = {
          xdg.dataDirs = wrapperManagerLib.getXdgDataDirs [(pkgs.callPackage ./_writeConfig.nix (nixonArgs // {inherit self';}))];
        };
      };
    };
  };
  flake.modules = {
    nixos.base = common;
    darwin.base = common;
  };
}
