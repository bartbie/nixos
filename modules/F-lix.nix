{ lib, ... }:
let
  lix-version = "lix_2_95";
  downstreamers = [
    # FIXME: this infrecs for whatever reason
    # "nixpkgs-review"
    "nix-eval-jobs"
    "nix-fast-build"
    "colmena"
  ];
  getSet = x: x.lixPackageSets.${lix-version};
  disable =
    p:
    lib.recursiveUpdate p {
      meta = {
        available = false;
        broken = true;
      };
    };
in
{
  # Overlay the downstreamers in unstable and disable in stable
  overlays = {
    stable = [
      # (_: prev: {lix = disable prev.lix;})
      (_: prev: lib.genAttrs downstreamers (n: disable prev.${n}))
      (_: prev: { nixpkgs-review = disable prev.nixpkgs-review; })
    ];
    unstable = [
      (_: prev: { lix = (getSet prev).lix; })
      (_: prev: lib.genAttrs downstreamers (n: (getSet prev).${n}))
      # (_: prev: {nixpkgs-review = (getSet prev).nixpkgs-review;})
    ];
  };
  hosts.shared =
    { pkgs-unstable, ... }:
    {
      nix.package = lib.mkForce pkgs-unstable.lix;
    };

  perSystem =
    {
      pkgs,
      pkgs-unstable,
      system,
      self',
      ...
    }:
    {
      packages.lix = pkgs-unstable.lix;
      devShells.devWithLix = pkgs.mkShell {
        name = "nixon-shell-lix";
        packages = [
          pkgs-unstable.lix
          pkgs.nh
          pkgs.nixos-rebuild
        ];
        inputsFrom = [ self'.devShells.devBase ];
      };
    };
}
