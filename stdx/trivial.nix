{nixpkgs, ...} @ inputs: let
  inherit (nixpkgs) lib;
in {
  # pipe but reversed order of args
  rpipe = f: x: lib.pipe x f;
}
