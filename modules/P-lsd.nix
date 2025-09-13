{nixonLib, ...}: {
  wrapped.lsd = {
    tags = null;
    module = {pkgs, ...}: {
      basePackages = [pkgs.lsd];
      wrappers = nixonLib.pkgh.mapArg0 pkgs.lsd "lsd" {
        ls.prependArgs = [];
        lsa.prependArgs = ["-a"];
        ll.prependArgs = ["-l"];
        la.prependArgs = ["-la"];
      };
    };
  };
}
