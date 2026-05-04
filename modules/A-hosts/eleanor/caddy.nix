{ lib, ... }:
let
  domain = "bartbie.gay";
  alias = "bartb.ee";
in
{
  hosts.nixos.eleanor = {
    services.caddy = {
      enable = true;
      virtualHosts.${domain} = {
        serverAliases = [
          "www.${domain}"
          alias
          "www.${alias}"
        ];
        extraConfig = ''
          respond "ok"
        '';
      };
    };
  };
}
