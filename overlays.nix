{
  bartbie-nvim,
  nixpkgs-unstable,
  ...
} @ inputs: {
  unstable-pkgs = allowUnfree: final: _prev: {
    unstable = import nixpkgs-unstable {
      system = final.system;
      config = {inherit allowUnfree;};
    };
  };

  # packages available under nixpkgs.mine
  mine-pkgs = final: prev: {
    mine = {
      inherit bartbie-nvim;
      rebuild = final.writeShellApplication {
        name = "rebuild";
        text = builtins.readFile ./rebuild;
        runtimeInputs = with final; [
          git
          alejandra
        ];
      };
    };
  };
}
