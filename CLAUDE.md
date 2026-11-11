# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

json-workstation — Nix flake managing system and home environment configuration across macOS and Linux devices.

## Architecture

- **macOS hosts** use **nix-darwin** (system-level) + **home-manager** (user-level)
- **Linux hosts** use **home-manager** only (no system management)
- **flake.nix** is the central entry point declaring all outputs via flake-parts
- **hosts/<host>/default.nix** composes modules for each device; host-only services live beside it (json-mini: `monitoring.nix`, `renovate.nix`, `repo-docs.nix`, `inference-ui.nix`, `rex.nix`; personal-macbook: `monitoring.nix`, `rex.nix`)
- **modules/home/** contains shared home-manager modules (shell, git, editor, tmux, etc.)
- **modules/darwin/** contains macOS-specific system and app configuration (apps, Colima, SSH/dev server, `rex-tunnels.nix`)

## Hosts

| Host | Config Key | Directory | Platform | Config System |
|------|-----------|-----------|----------|---------------|
| Personal MacBook (also dev SSH server) | `JSON-MACBOOK16` | `hosts/personal-macbook` | aarch64-darwin | nix-darwin |
| Work MacBook (Papercompute) | `JSON-PAPERBOOK` | `hosts/paperbook` | aarch64-darwin | nix-darwin |
| Personal Linux (Pop!_OS) | `JSON-Mini` | `hosts/json-mini` | x86_64-linux | home-manager |
| WSL | `JSON-STATION` | `hosts/json-station` | x86_64-linux | home-manager |

## Key Commands

- `update` — shell alias that applies config (`darwin-rebuild switch` on macOS, `home-manager switch` on Linux)
- `nix flake check` — validate the flake
- `nix flake update` — update all flake inputs
- `bash hosts/<host>/bootstrap.sh` — initial setup for a new machine

## Conventions

- Repo is symlinked to `~/.system` on all machines
- Formatter is `nixfmt` (available in devShell)
- Uses nixpkgs-unstable channel
- `allowUnfree = true` across all hosts
- Flatpak apps managed via nix-flatpak on JSON-Mini only
- Coding agents come from `modules/home/coding-agents.nix` on every host. Claude Code, Codex, opencode and pi are pinned upstream binaries; `scripts/bump-agents.sh` bumps them, `dsh` and herdr-core (`modules/home/herdr/herdr-core-native.nix`) to latest. opencode, pi and DeepSeek's `dsh` also get the DGX Sparks (`inference.json.lab`) as an extra provider, from the list in `modules/home/json-lab-models.nix`. `dsh` is a pinned `npx` wrapper with its telemetry and session-log upload off.
- Renovate runs from JSON-Mini, not the GitHub app: `hosts/json-mini/renovate.nix` is a weekly home-manager user timer (Sun 03:30 PT) covering json-lab, json-agents, json-inference and json-workstation. The token comes from `gh auth token` at run time (gh login in the desktop keyring, so json-mini needs a login after a reboot); nothing automerges. Run now: `systemctl --user start renovate`; logs: `journalctl --user -u renovate`
- Multiplexers: tmux + `mux` (smug layouts) and herdr on every host, plus herdr-core (`hc`) for the Herdr mobile apps (its own server; TUI terminals don't show in the apps; never `hc update`, it bypasses Nix); Rex servers on JSON-Mini (`rex.nix`, systemd user `rex`) and JSON-MACBOOK16 (`rex.nix`, launchd `com.user.rex-server`), reached from the Macs by SSH socket forwards in `modules/darwin/rex-tunnels.nix` (`rexTunnels.hosts`; local sockets `~/.ssh/rex-<host>.sock`). `rex skill setup` is run by hand per host, never from `update`. Proposed Rex work is tracked in json-lab `docs/features.md`
- JSON-PAPERBOOK only: `modules/home/gh-dash.nix` (gh-dash + `gh greptile`) and peon-ping (Claude Code sound cues)
- JSON-MACBOOK16 runs monitoring exporters as launchd daemons (`hosts/personal-macbook/monitoring.nix`: node-exporter :9100, macmon :9101, Glances :61208), like json-mini's `monitoring.nix` user services
- Git is configured to rebase on pull (no merge commits)
- `PROJECT_BASE_DIR` and `PROJECT_FOLDER` both point to `~/workspace`
- On Linux, `home.sessionPath` adds `~/.nix-profile/bin` (`modules/home/zsh.nix`) so non-interactive `ssh host cmd` sees Nix tools; without it the Herdr apps can't find `hc`
