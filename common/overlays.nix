{
  bartbie-nvim,
  nixpkgs-unstable,
  home-manager,
  ...
} @ inputs: {
  unstable-pkgs = allowUnfree: final: _prev: {
    unstable = import nixpkgs-unstable {
      system = final.system;
      config = {inherit allowUnfree;};
    };
  };

  # packages available under nixpkgs.mine
  mine-pkgs = final: prev: let
    # flakes need to be handled
    unpack = flake: flake.packages."${final.system}";
  in {
    mine = {
      inherit (unpack bartbie-nvim) bartbie-nvim;
      rebuild = final.writeShellApplication {
        name = "rebuild";
        text = builtins.readFile ../scripts/rebuild.sh;
        runtimeInputs = with final; [
          git
          alejandra
          ripgrep
        ];
      };
      home-export = final.writeShellApplication {
        name = "home-export";
        text = builtins.readFile ../scripts/home-export.sh;
        runtimeInputs = [
          (unpack home-manager).default
        ];
      };
    };
  };
}
