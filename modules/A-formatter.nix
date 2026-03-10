{
  wrapped.fmt = {
    module =
      {
        pkgs,
        wrapperManagerLib,
        ...
      }:
      {
        single = {
          package = pkgs.treefmt;
          wrapper.pathAdd =
            [
              pkgs.nixfmt
              pkgs.prettier
              pkgs.qt6.qtdeclarative
            ]
            |> builtins.map (x: "${x}/bin");
        };
      };
  };
  perSystem =
    { config, ... }:
    {
      formatter = config.packages.fmt;
    };
}
