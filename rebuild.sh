set -e

# cd to your config dir
pushd /etc/nixos

# Edit your config
$EDITOR .

# Autoformat your nix files
alejandra . >/dev/null

# Shows your changes
git diff -U0 ./**.nix

echo "NixOS Rebuilding..."

# Rebuild, output simplified errors, log trackebacks
sudo nixos-rebuild switch | tee nixos-switch.log || (rg -N error nixos-switch.log && false)

# Get current generation metadata
current=$(nixos-rebuild list-generations | grep current)

# Commit all changes with the generation metadata
git commit -am "$current"

# Back to where you were
popd

# Notify all OK!
# notify-send -e "NixOS Rebuilt OK!" --icon=software-update-available
echo "NixOS Rebuilt OK!"
