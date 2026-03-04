set -e

JJ_ROOT=$(jj root)
BUBBLE_UNDO="$JJ_ROOT/.jj/bubble-undo"

op_before=$(jj op log --no-graph -T 'self.id() ++ "\n"' | head -1)

mapfile -t ids < <(jj log -r 'local() & ::@' -T 'change_id ++ "\n"' --no-graph)

jj rebase -s "after_local()" -A "before_local()"

args=()
for id in "${ids[@]}"; do
  args+=(-r "$id")
done

jj new "${args[@]}"

echo "$op_before" > "$BUBBLE_UNDO"
