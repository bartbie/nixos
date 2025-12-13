set -euo pipefail
WALLPAPER_DIR="$HOME/Eternal/Pictures/wallpapers/random/"

# find them all
WALLPAPERS=$(fd . "$WALLPAPER_DIR" --type symlink --type file)
case "$(echo $WALLPAPERS | wc -l)" in
  0)
      # noop
      ;;
  1)
      swww img $WALLPAPERS "$@"
      ;;
  *)
      CURRENT_WALL=$(swww query | sed "s/.*image: //")
      # Get a random wallpaper that is not the current one
      WALLPAPER=$(fd . "$WALLPAPER_DIR" --type symlink --type file --exclude "$(basename "$CURRENT_WALL")" | shuf -n 1)

      # Apply the selected wallpaper
      swww img $WALLPAPER "$@"
      ;;
esac
