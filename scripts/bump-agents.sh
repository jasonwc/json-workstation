#!/usr/bin/env bash
# Move the pinned coding agents to their latest upstream releases: rewrites
# `version` and every platform's sha256 in modules/home/*-native.nix (and
# herdr-core's in modules/home/herdr/herdr-core-native.nix), and the dsh
# version in modules/home/deepseek-harness.nix. Review the diff, then
# `update` to apply.
#
#   scripts/bump-agents.sh                 # all of them
#   scripts/bump-agents.sh opencode pi     # just these
#
# Needs curl, jq, gh (authenticated, for release lookups) and npm.
set -euo pipefail

cd "$(dirname "$0")/../modules/home"

# set_version <file> <version>
set_version() {
  # First match only: deepseek-harness.nix has a second `version` (its Node pin).
  perl -0pi -e 's/^(\s*version = ")[^"]+(";)/${1}'"$2"'${2}/m' "$1"
}

# set_hash <file> <platform selector value> <sha256>
# Replaces the sha256 on the line after `<field> = "<selector>";`.
set_hash() {
  [[ $3 =~ ^[0-9a-f]{64}$ ]] || {
    echo "bad sha256 for $2: '$3'" >&2
    exit 1
  }
  SEL="$2" SHA="$3" perl -0pi -e 's/(= "\Q$ENV{SEL}\E";\n\s*sha256 = ")[0-9a-f]+/${1}$ENV{SHA}/' "$1"
}

current() { sed -nE 's/^ *version = "([^"]+)";/\1/p' "$1" | head -1; }

report() { [[ $2 == "$3" ]] && echo "$1: $2 (already latest)" || echo "$1: $2 -> $3"; }

bump_claude() {
  local f=claude-code-native.nix v m
  v=$(curl -fsS https://downloads.claude.ai/claude-code-releases/latest)
  report claude "$(current $f)" "$v"
  m=$(curl -fsS "https://downloads.claude.ai/claude-code-releases/$v/manifest.json")
  set_version $f "$v"
  for k in darwin-arm64 darwin-x64 linux-arm64 linux-x64; do
    set_hash $f "$k" "$(jq -r --arg k "$k" '.platforms[$k].checksum' <<<"$m")"
  done
}

bump_codex() {
  local f=codex-native.nix tag v sums
  tag=$(gh release view -R openai/codex --json tagName -q .tagName)
  v=${tag#rust-v}
  report codex "$(current $f)" "$v"
  sums=$(curl -fsSL "https://github.com/openai/codex/releases/download/$tag/codex-package_SHA256SUMS")
  set_version $f "$v"
  for t in aarch64-apple-darwin x86_64-apple-darwin aarch64-unknown-linux-musl x86_64-unknown-linux-musl; do
    set_hash $f "$t" "$(awk -v n="codex-package-$t.tar.gz" '$2 == n { print $1 }' <<<"$sums")"
  done
}

bump_opencode() {
  local f=opencode-native.nix rel v
  rel=$(gh release view -R sst/opencode --json tagName,assets)
  v=$(jq -r '.tagName | ltrimstr("v")' <<<"$rel")
  report opencode "$(current $f)" "$v"
  set_version $f "$v"
  for a in opencode-darwin-arm64.zip opencode-darwin-x64.zip opencode-linux-arm64.tar.gz opencode-linux-x64.tar.gz; do
    set_hash $f "$a" "$(jq -r --arg a "$a" '.assets[] | select(.name == $a) | .digest | ltrimstr("sha256:")' <<<"$rel")"
  done
}

bump_pi() {
  local f=pi-native.nix tag v sums
  tag=$(gh release view -R earendil-works/pi --json tagName -q .tagName)
  v=${tag#v}
  report pi "$(current $f)" "$v"
  sums=$(curl -fsSL "https://github.com/earendil-works/pi/releases/download/$tag/SHA256SUMS")
  set_version $f "$v"
  for k in darwin-arm64 darwin-x64 linux-arm64 linux-x64; do
    set_hash $f "$k" "$(awk -v n="pi-$k.tar.gz" '{ sub(/^\*/, "", $2) } $2 == n { print $1 }' <<<"$sums")"
  done
}

bump_herdr-core() {
  local f=herdr/herdr-core-native.nix m v
  m=$(curl -fsSL https://releases.herdr.dev/core/latest.json)
  v=$(jq -r .version <<<"$m")
  report herdr-core "$(current $f)" "$v"
  set_version $f "$v"
  for t in macos-aarch64 macos-x86_64 linux-aarch64 linux-x86_64; do
    set_hash $f "$t" "$(jq -r --arg t "$t" '.targets[$t].sha256' <<<"$m")"
  done
}

bump_dsh() {
  local f=deepseek-harness.nix v
  v=$(npm view @deepseek-ai/dsh dist-tags.latest)
  report dsh "$(current $f)" "$v"
  set_version $f "$v"
}

agents=("$@")
[[ ${#agents[@]} -gt 0 ]] || agents=(claude codex opencode pi dsh herdr-core)
for a in "${agents[@]}"; do
  case $a in
  claude | codex | opencode | pi | dsh | herdr-core) "bump_$a" ;;
  *)
    echo "unknown agent: $a (claude, codex, opencode, pi, dsh, herdr-core)" >&2
    exit 1
    ;;
  esac
done
