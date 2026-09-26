# json-workstation

Nix flake configuration for all of Jason's devices: nix-darwin + home-manager on
the Macs, home-manager only on Linux.

## Pre-requisites

- Install Nix via [Determinate Installer](https://github.com/DeterminateSystems/nix-installer) (the Mac bootstrap scripts do this for you)
- Clone this repo and symlink it: `ln -s /path/to/json-workstation ~/.system`

## Devices

| Host | Config Key | Type |
|---|---|---|
| Personal MacBook (also dev SSH server) | `JSON-MACBOOK16` | nix-darwin |
| Work MacBook (Papercompute) | `JSON-PAPERBOOK` | nix-darwin |
| Personal Linux (json-mini, Pop!_OS) | `JSON-Mini` | home-manager |
| WSL (json-station) | `JSON-STATION` | home-manager |

## Layout

```
flake.nix          # all outputs (flake-parts)
hosts/<host>/      # default.nix composes modules per device; bootstrap.sh for first setup
modules/home/      # shared home-manager modules (zsh, git, editor, tmux, coding agents, ...)
modules/darwin/    # macOS system config: apps, Colima, SSH/dev server
docs/              # setup notes (coding agents, remote viewing, ...)
windows/           # native Windows services on json-station that Nix can't manage
```

## Install

Each host has a directory under `hosts/` with a `default.nix` config and a
`bootstrap.sh` script for system-level setup. Clone the repo, then run the
host's script from inside it:

```bash
git clone https://github.com/jasonwc/json-workstation.git
cd json-workstation && bash hosts/<host>/bootstrap.sh
```

- **Macs** (`personal-macbook`, `paperbook`; needs Xcode Command Line Tools):
  pulls SSH keys from GitHub, installs Determinate Nix with the FlakeHub cache
  and Homebrew, symlinks `~/.system` and applies nix-darwin. Then enable the 1Password SSH agent and CLI integration in
  1Password developer settings.
- **json-mini** (`json-mini`): configures the SSH server (key-only auth),
  disables sleep/suspend, enables lingering so user services start at boot,
  installs Nix and applies home-manager.
- **json-station** (`json-station`): ensures systemd is enabled in WSL,
  installs Nix and applies home-manager.

## Maintenance

Update nix dependencies:

```bash
cd ~/.system && nix flake update
```

Apply configuration changes (`darwin-rebuild switch` on macOS,
`home-manager switch` on Linux):

```bash
update
```

Validate with `nix flake check`; format with `nixfmt` (in the devShell).

## Coding agents

`modules/home/coding-agents.nix` installs Claude Code and Codex (pinned native
builds), opencode, pi, goose, `agy` and, on Linux, aider on every host. DeepSeek's
`dsh` is a pinned `npx` wrapper (`modules/home/deepseek-harness.nix`) with its
telemetry and session-log upload turned off.

opencode, pi and `dsh` also get the DGX Sparks as an extra provider, `json-lab`,
at `http://inference.json.lab/v1` (`modules/home/json-lab-inference.nix`). The
model list is `modules/home/json-lab-models.nix` and follows json-inference's
definitions; only one model is served at a time, and the hosted providers
remain available alongside it. See `docs/coding-agents-setup.md` for subscriptions and per-device setup.

## json-mini monitoring

`hosts/json-mini/monitoring.nix` runs the endpoints json-lab reads as
home-manager systemd user services:

| Service | Port | Used by |
|---|---|---|
| node-exporter | 9100 | Prometheus job `json-mini` |
| `amdgpu_exporter.py` (Radeon 890M) | 9101 | Prometheus job `json-mini-gpu` |
| Glances REST API | 61208 | Homepage widgets |

## Shell helpers

- `update`: apply this repo's config (above)
- `fwd <host> <port> [port...]`: SSH-forward localhost-only ports from another
  machine, e.g. `fwd json-mini 3080`, then open `http://localhost:3080`.
  Ctrl-C closes the tunnel.

## Related repos

- **json-lab**: the k3s homelab and the DGX Sparks' OS. It scrapes json-mini's
  exporters and serves `inference.json.lab`.
- **json-inference**: what the Sparks serve (model definitions, benchmarks).

## Useful links

- https://mynixos.com/home-manager/options/programs
- https://search.nixos.org/packages
- https://nixos-and-flakes.thiscute.world/nixos-with-flakes/modularize-the-configuration
