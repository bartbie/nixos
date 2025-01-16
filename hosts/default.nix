{self, ...}: let
    mkHostArgs =  hostname: system: modules:
        { 
        inherit system;
        modules = [
            {networking.hostName = hostname;}
            {nixpkgs.overlays = import ./common/overlays.nix inputs;};
            ./hosts/${hostname}
        ] ++ modules;
        specialArgs = {
            inherit inputs;
            flake = self;
        };
    };
in
{
    lyndon = lib.nixosSystem (mkHostArgs "lyndon", "x86_64-linux" [
        self.system
    ]);
}
