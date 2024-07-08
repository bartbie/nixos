{home-manager, ...} @ inputs: {
  allowUnfree = {nixpkgs.config.allowUnfree = true;};
  hypr-cachix = {
    nix.settings = {
      substituters = ["https://hyprland.cachix.org"];
      trusted-public-keys = ["hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="];
    };
  };
}
