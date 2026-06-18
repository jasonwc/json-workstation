# mux-iterm [parent] — open one iTerm tab per immediate subfolder of a
# parent directory, each running `mux <subfolder>` so the tab attaches to
# (or creates) that folder's work session.
#
# Parent resolution: argument, else $MUX_ROOT, else ~/workspace.

parent="${1:-${MUX_ROOT:-$HOME/workspace}}"
if [ ! -d "$parent" ]; then
  echo "mux-iterm: not a directory: $parent" >&2
  exit 1
fi
parent="$(cd -- "$parent" && pwd -P)"

dirs=()
while IFS= read -r d; do
  dirs+=("$d")
done < <(find "$parent" -mindepth 1 -maxdepth 1 -type d | sort)

if [ "${#dirs[@]}" -eq 0 ]; then
  echo "mux-iterm: no subdirectories in $parent" >&2
  exit 1
fi

# Single-quote for the shell, then escape \ and " for the AppleScript string.
sq() { printf "'%s'" "${1//\'/\'\\\'\'}"; }
as_escape() {
  local s=${1//\\/\\\\}
  printf '%s' "${s//\"/\\\"}"
}

emit() { # $1 = first|tab, $2 = dir
  local cmd esc
  cmd="mux $(sq "$2")"
  esc="$(as_escape "$cmd")"
  if [ "$1" = first ]; then
    printf '  tell current session of w to write text "%s"\n' "$esc"
  else
    printf '  tell w\n'
    printf '    set t to (create tab with default profile)\n'
    printf '    tell current session of t to write text "%s"\n' "$esc"
    printf '  end tell\n'
  fi
}

{
  printf 'tell application "iTerm2"\n'
  printf '  activate\n'
  printf '  set w to (create window with default profile)\n'
  first=first
  for d in "${dirs[@]}"; do
    emit "$first" "$d"
    first=tab
  done
  printf 'end tell\n'
} | /usr/bin/osascript -
