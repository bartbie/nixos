{ lib, ... }:
{
  flake.modules.nixos.cuda = {
    nix.settings = {
      substituters = [
        "https://cache.nixos-cuda.org"
        "https://cache.flox.dev"
      ];
      trusted-public-keys = [
        "cache.nixos-cuda.org:74DUi4Ye579gUqzH4ziL9IyiJBlDpMRn9MBN8oNan9M="
        "flox-cache-public-1:7F4OyH7ZCnFhcze3fJdfyXYLQw/aV7GEed86nQ7IsOs= "
      ];
    };
    nixpkgs.config = {
      cudaSupport = true;
      allowUnfreePredicate =
        p:
        p.meta.license
        |> lib.flatten
        |> builtins.all (
          { free, shortName, ... }:
          free
          || builtins.elem shortName [
            "CUDA EULA"
            "cuDNN EULA"
            "cuTENSOR EULA"
            "NVidia OptiX EULA"
          ]
        );
    };
  };
}
