# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

json-workstation — Nix flake managing system and home environment configuration across macOS and Linux devices.

## Architecture

- **macOS hosts** use **nix-darwin** (system-level) + **home-manager** (user-level)
- **Linux hosts** use **home-manager** only (no system management)
- **flake.nix** is the central entry point declaring all outputs via flake-parts
- **hosts/<host>/default.nix** composes modules for each device
- **modules/home/** contains shared home-manager modules (shell, git, editor, tmux, etc.)
- **modules/darwin/** contains macOS-specific system and app configuration

## Hosts

| Host | Config Key | Platform | Config System |
|------|-----------|----------|---------------|
| Personal MacBook | `JSON-MACBOOK16` | aarch64-darwin | nix-darwin |
| Personal Linux (Pop!_OS) | `JSON-MINI` | x86_64-linux | home-manager |
| WSL | `JSON-STATION` | x86_64-linux | home-manager |

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
- Flatpak apps managed via nix-flatpak on JSON-MINI only
- Git is configured to rebase on pull (no merge commits)
- `PROJECT_BASE_DIR` and `PROJECT_FOLDER` both point to `~/workspace`
