set -e

JJ_ROOT=$(jj root)
BUBBLE_UNDO="$JJ_ROOT/.jj/bubble-undo"

if [ ! -f "$BUBBLE_UNDO" ]; then
  echo "no bubble to undo"
  exit 1
fi

saved_op=$(cat "$BUBBLE_UNDO")
current_minus2=$(jj op log --no-graph -T 'self.id() ++ "\n"' | sed -n '3p')

if [ "$saved_op" != "$current_minus2" ]; then
  echo "bubble was not the last operation, aborting"
  exit 1
fi

jj op restore "$saved_op"
rm "$BUBBLE_UNDO"
