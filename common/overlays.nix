{
  bartbie-nvim,
  nixpkgs-unstable,
  home-manager,
  ...
} @ inputs: let
  mkOverlay = fn: final: prev: let
    # flakes need to be handled
    unpack = flake: flake.packages."${final.system}";
  in {
    mine = fn {inherit final prev unpack;};
  };
in {
  unstable-pkgs = allowUnfree: final: _prev: {
    unstable = import nixpkgs-unstable {
      system = final.system;
      config = {inherit allowUnfree;};
    };
  };

  ## packages available under nixpkgs.mine

  bartbie-nvim = mkOverlay ({
    final,
    prev,
    unpack,
    ...
  }: {
    inherit (unpack bartbie-nvim) bartbie-nvim;
  });

  scripts = mkOverlay ({
    final,
    prev,
    unpack,
    ...
  }: {
    scripts = {
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
  });


  hypr = mkOverlay ({
    final,
    prev,
    ...
  }: {
    hypr = {
    };
  });
}
