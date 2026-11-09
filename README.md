# json-workstation

Nix flake configuration for all of Jason's devices: nix-darwin + home-manager on
the Macs, home-manager only on Linux.

## Pre-requisites

- Install Nix via [Determinate Installer](https://github.com/DeterminateSystems/nix-installer) (each host's `bootstrap.sh` does this for you)
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
hosts/<host>/      # default.nix composes modules per device, plus host-only services; bootstrap.sh for first setup
modules/home/      # shared home-manager modules (zsh, git, editor, tmux, coding agents, ...)
modules/darwin/    # macOS system config: apps, Colima, SSH/dev server, Rex tunnels
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
- **json-mini** (`json-mini`): configures the SSH server (key-only auth,
  authorized_keys seeded from github.com/jasonwc.keys), disables
  sleep/suspend, enables lingering so user services start at boot, installs
  Flatpak + Flathub and Nix, applies home-manager, makes zsh the default shell
  and sets up COSMIC Terminal. It also installs the VS Code CLI with a
  `code-tunnel` user service (outside Nix; needs a one-time `code tunnel`
  sign-in).
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

`modules/home/coding-agents.nix` installs Claude Code, Codex, opencode and pi
(upstream prebuilt binaries, pinned in `modules/home/*-native.nix`), `agy`,
Cursor's `cursor-agent`, GitHub's `copilot` and, on Linux, aider on every host.
DeepSeek's `dsh` is a pinned `npx` wrapper (`modules/home/deepseek-harness.nix`)
with its telemetry and session-log upload turned off.

`scripts/bump-agents.sh` moves the pinned agents (claude, codex, opencode, pi,
dsh) to their latest releases, versions and hashes both; pass names to bump
only some. The rest follow nixpkgs via `nix flake update`.

opencode, pi and `dsh` also get the DGX Sparks as an extra provider, `json-lab`,
at `http://inference.json.lab/v1` (`modules/home/json-lab-inference.nix` for
opencode and pi, `deepseek-harness.nix` for `dsh`). The
model list is `modules/home/json-lab-models.nix` and follows json-inference's
definitions; only one model is served at a time, and the hosted providers
remain available alongside it. See `docs/coding-agents-setup.md` for subscriptions and per-device setup.

## Other modules

- `modules/home/tmux.nix` + `modules/home/mux`: tmux with a fixed per-directory
  layout (smug) and a sesh picker (`mux`, `mux-iterm`, `mux-pick`); every host
- `modules/home/herdr`: herdr, the agent multiplexer, piloted alongside `mux`;
  every host
- `modules/home/gh-dash.nix`: gh-dash for open PRs plus `gh greptile` (merge
  readiness); JSON-PAPERBOOK only
- peon-ping (flake input): sound cues on Claude Code events; JSON-PAPERBOOK only

## Host services

**json-mini** (home-manager systemd user services, kept running by lingering):

| Service | File | What |
|---|---|---|
| node-exporter :9100, `amdgpu_exporter.py` :9101, Glances :61208 | `monitoring.nix` | Prometheus jobs `json-mini` / `json-mini-gpu`; Glances for Homepage |
| `renovate` (timer, Sun 03:30 PT) | `renovate.nix` | Dependency PRs for json-lab, json-agents, json-inference, json-workstation; writes a node-exporter heartbeat |
| `repo-docs` (timer, nightly 04:17) | `repo-docs.nix` | Refreshes Byrdpip's read-only `/docs` on spireos (script in json-agents) |
| `inference-ui` :8091 | `inference-ui.nix` | json-inference's model-swap page, published by json-lab as models.json.lab |
| `rex` | `rex.nix` | Personal Rex server (see below) |
| `code-tunnel` | written by `bootstrap.sh` | VS Code remote tunnel (not Nix-managed) |

**JSON-MACBOOK16** (launchd):

| Service | File | What |
|---|---|---|
| node-exporter :9100, macmon :9101, Glances :61208 (daemons) | `hosts/personal-macbook/monitoring.nix` | Prometheus jobs `json-macbook16` / `json-macbook16-gpu`; Glances for Homepage |
| `com.user.rex-server` (agent) | `hosts/personal-macbook/rex.nix` | Personal Rex server (see below) |
| `com.user.colima` (agent) | `modules/darwin/colima.nix` | Docker engine (also on JSON-PAPERBOOK) |

## Rex

[Rex](https://www.superlogical.com/rex/docs) (Superlogical's multiplexer, private
beta) comes from the `rex` flake input (preview channel). Personal servers run on
json-mini (`hosts/json-mini/rex.nix`, systemd user service `rex`) and
JSON-MACBOOK16 (`hosts/personal-macbook/rex.nix`, launchd `com.user.rex-server`),
listening only on their Unix sockets. Rex for Mac reaches them through SSH socket
forwards from `modules/darwin/rex-tunnels.nix`: each Mac lists its targets in
`rexTunnels.hosts` and gets a launchd agent per target, with the local end at
`~/.ssh/rex-<host>.sock` (add that path in Rex for Mac). JSON-PAPERBOOK targets
both servers; JSON-MACBOOK16 targets json-mini.

The agent skill is installed by hand, once per host that runs agents:
`rex skill setup`. Proposed and ruled-out Rex work is tracked in json-lab's
`docs/features.md`.

## Shell helpers

- `update`: apply this repo's config (above)
- `fwd <host> <port> [port...]`: SSH-forward localhost-only ports from another
  machine, e.g. `fwd json-mini 3080`, then open `http://localhost:3080`.
  Ctrl-C closes the tunnel.

## Related repos

- **json-lab**: the k3s homelab and the DGX Sparks' OS. It scrapes the json-mini
  and JSON-MACBOOK16 exporters and serves `inference.json.lab` and models.json.lab.
- **json-inference**: what the Sparks serve (model definitions, benchmarks) and
  the model-swap page json-mini runs.
- **json-agents**: the personal agents on spireos; json-mini runs its
  `bin/repo-docs` nightly, and Renovate covers it.

## Useful links

- https://mynixos.com/home-manager/options/programs
- https://search.nixos.org/packages
- https://nixos-and-flakes.thiscute.world/nixos-with-flakes/modularize-the-configuration
