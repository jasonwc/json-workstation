# mux [dir] — open or attach the standard work session for a directory.
#
# Session name is the directory's basename (with . and : sanitised, since
# tmux forbids them). If the session already exists it is reused as-is;
# otherwise smug builds it from ~/.config/smug/mux.yml, detached, and we
# focus the `main` window before attaching/switching.

dir="${1:-$PWD}"
if [ ! -d "$dir" ]; then
  echo "mux: not a directory: $dir" >&2
  exit 1
fi
dir="$(cd -- "$dir" && pwd -P)"

name="${dir##*/}"
name="${name//[.:]/_}"

if ! tmux has-session -t "=$name" 2>/dev/null; then
  smug start mux --detach "session=$name" "dir=$dir"
  tmux select-window -t "=$name:main" 2>/dev/null || true
fi

if [ -n "${TMUX:-}" ]; then
  exec tmux switch-client -t "=$name"
else
  exec tmux attach -t "=$name"
fi
