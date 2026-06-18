# mux-pick — fuzzy-pick a session/directory (via sesh + fzf) and connect.
#
# Candidates come from `sesh list`: running tmux sessions plus zoxide dirs.
#  - tmux entry  -> attach/switch to that session
#  - zoxide dir  -> `mux <path>` builds/attaches the full work layout
#
# Works both at a plain shell (attaches) and inside tmux or a tmux popup
# (switches the client).

sel="$(
  sesh list -j \
    | jq -r '.[] | [.Src, .Name, .Path] | @tsv' \
    | fzf --delimiter='\t' --with-nth='2,3' --no-sort \
          --prompt='mux> ' --height='60%' --reverse \
          --preview 'ls -p {3} 2>/dev/null | head -50'
)" || exit 0
[ -n "$sel" ] || exit 0

IFS=$'\t' read -r src name path <<<"$sel"

if [ "$src" = tmux ]; then
  if [ -n "${TMUX:-}" ]; then
    exec tmux switch-client -t "=$name"
  else
    exec tmux attach -t "=$name"
  fi
else
  exec mux "$path"
fi
