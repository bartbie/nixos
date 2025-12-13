set -euo pipefail

desktop_id=$(xdg-settings get default-web-browser)

find_desktop() {
    local id="$1" d IFS=':'
    local dirs=("${XDG_DATA_HOME:-$HOME/.local/share}" ${XDG_DATA_DIRS:-/usr/local/share:/usr/share})
    for d in "${dirs[@]}"; do
        [[ -f "$d/applications/$id" ]] && { echo "$d/applications/$id"; return; }
    done
    return 1
}

desktop_file=$(find_desktop "$desktop_id")
exec_line=$(rg -m1 '^Exec=' "$desktop_file" | sed 's/^Exec=//; s/ %[a-zA-Z]//g')
read -ra exec_args <<< "$exec_line"
while [[ "${exec_args[0]:-}" == *=* ]]; do exec_args=("${exec_args[@]:1}"); done

exec "${exec_args[0]}" "${exec_args[@]:1}"
