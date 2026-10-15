# gh greptile                  Is each of my open PRs ready to merge?
# gh greptile OWNER/REPO NUM    Greptile summary and unresolved comments for one PR
#
# A PR is ready when it isn't a draft, CI is green (or has no checks),
# Greptile's "Confidence Score" is 5/5, and its review decision is approved
# or no review is required.

pr_fields='
  number title url isDraft reviewDecision repository { nameWithOwner }
  comments(last: 50) { nodes { author { login } body } }
  reviewThreads(first: 100) {
    nodes {
      isResolved path line originalLine
      comments(first: 1) { nodes { author { login } body } }
    }
  }
  commits(last: 1) {
    nodes { commit { statusCheckRollup { state contexts(first: 100) {
      nodes { ... on CheckRun { name status conclusion } }
    } } } }
  }'

# Per-PR jq helpers shared by both modes.
jq_defs='
  def summary: [.comments.nodes[] | select(.author.login == "greptile-apps"
    and (.body | contains("greptile_summary")))] | last | .body // "";
  def score: (summary | capture("Confidence Score: (?<s>[0-9])/5").s // "-") as $s
    | if $s == "-" then "-" else "\($s)/5" end;
  def check: [.commits.nodes[0].commit.statusCheckRollup.contexts.nodes[]?
    | select(.name == "Greptile Review")] | last
    | if . == null then "none"
      elif .status != "COMPLETED" then "running"
      else .conclusion | ascii_downcase end;
  def clean: gsub("<img alt=\"(?<a>[^\"]*)\"[^>]*>"; "[\(.a)]")
    | gsub("<[^>]*>"; "") | gsub("&nbsp;"; "") | gsub(" *▶"; "") | gsub("\\\\(?<c>[.()])"; "\(.c)")
    | gsub("\\[(Retrigger|View in Greptile)\\]"; "") | gsub("\\]\\*\\*(?<n>\\w)"; "] **\(.n)");
  def ci: .commits.nodes[0].commit.statusCheckRollup.state // "NONE"
    | {SUCCESS: "green", FAILURE: "red", ERROR: "red", NONE: "none"}[.]
      // "pending";
  def greptile: if check == "running" then "running" else score end;
  def review: {APPROVED: "approved", REVIEW_REQUIRED: "needed",
    CHANGES_REQUESTED: "changes"}[.reviewDecision // ""] // "not needed";
  def ready: (.isDraft | not) and (ci == "green" or ci == "none")
    and greptile == "5/5" and (review == "approved" or review == "not needed");
  def open_threads: [.reviewThreads.nodes[] | select(.isResolved | not)
    | select(.comments.nodes[0].author.login == "greptile-apps")];
'

if [ $# -eq 0 ]; then
  # Color only for a terminal, and honor NO_COLOR.
  color=false
  [ -t 1 ] && [ -z "${NO_COLOR:-}" ] && color=true

  gh api graphql -f q="is:pr is:open author:@me archived:false" -f query="
    query(\$q: String!) {
      search(query: \$q, type: ISSUE, first: 50) {
        nodes { ... on PullRequest { $pr_fields } }
      }
    }" --jq "$jq_defs def color: $color;"'
    # Cells are [text, ANSI color]. Pad on the plain text, then wrap in
    # color, so escape codes never count toward column widths.
    def paint($c): if color and $c != "" then "\u001b[\($c)m\(.)\u001b[0m" else . end;
    def good: "32"; def bad: "31"; def wait: "33"; def dim: "90";
    def state($is_ok; $is_waiting): if $is_ok then good elif $is_waiting then wait else bad end;
    [["READY", dim], ["CI", dim], ["GREPTILE", dim], ["REVIEW", dim],
     ["PR", dim], ["TITLE", dim]] as $header
    | [.data.search.nodes | sort_by(ready | not)[]
      | [(if ready then ["yes", "1;32"] elif .isDraft then ["draft", dim]
          else ["no", "1;31"] end),
         [ci, if ci == "none" then dim else state(ci == "green"; ci == "pending") end],
         [greptile, if greptile == "-" then dim
           else state(greptile == "5/5"; greptile == "running") end],
         [review, state(review == "approved" or review == "not needed"; review == "needed")],
         ["\(.repository.nameWithOwner)#\(.number)", "36"],
         [.title[:60], ""]]] as $rows
    | ([$header] + $rows) as $all
    | [range($header | length) as $i | [$all[][$i][0] | length] | max] as $w
    | $all[]
    | [to_entries[] | .key as $i | .value as [$t, $c]
       | (if $i < ($w | length) - 1 then $t + (" " * ($w[$i] - ($t | length))) + "  "
          else $t end) as $cell
       | $cell | paint($c)] | join("")'
  exit
fi

if [ $# -ne 2 ]; then
  echo "usage: gh greptile [OWNER/REPO NUMBER]" >&2
  exit 2
fi

owner=${1%%/*}
repo=${1#*/}
width=$(tput cols 2>/dev/null || echo 100)
[ "$width" -gt 120 ] && width=120

# Render as Markdown through glow. Its output goes to less rather than a
# terminal, so the style is set explicitly instead of auto-detected.
gh api graphql -f owner="$owner" -f repo="$repo" -F num="$2" -f query="
  query(\$owner: String!, \$repo: String!, \$num: Int!) {
    repository(owner: \$owner, name: \$repo) {
      pullRequest(number: \$num) { $pr_fields }
    }
  }" --jq "$jq_defs"'
  def icon(ok; wait): if ok then "✅" elif wait then "⏳" else "❌" end;
  .data.repository.pullRequest
  | open_threads as $open
  | "# \(.title)",
    "\(.repository.nameWithOwner)#\(.number) · <\(.url)>",
    "",
    "| Ready | CI | Greptile | Review |",
    "|:-:|:-:|:-:|:-:|",
    "| \(if .isDraft then "📝 draft" else icon(ready; false) end) "
      + "| \(icon(ci == "green" or ci == "none"; ci == "pending")) \(ci) "
      + "| \(icon(greptile == "5/5"; greptile == "running")) \(greptile) "
      + "| \(icon(review == "approved" or review == "not needed"; false)) \(review) |",
    "",
    (summary
      | gsub("(?s)<details><summary><h3>Diagram.*?</details>"; "")
      | gsub("(?s)<h2>.*?</h2>"; "")
      | gsub("<h3>(?<h>[^<]*)</h3>"; "\n## \(.h)\n")
      | clean
      | gsub("(?m)^Reviews \\(.*$"; "")),
    "",
    (if ($open | length) > 0
     then "## Unresolved Greptile comments (\($open | length))",
       ($open[] | "### `\(.path):\(.line // .originalLine)`", "", (.comments.nodes[0].body | clean), "")
     else empty end)' |
  glow -s "${GH_GREPTILE_STYLE:-dark}" -w "$width" - |
  less -R -X
