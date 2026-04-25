# json-workstation

Nix flake configuration for all of Jason's devices.

## Pre-requisites

- Install Nix via [Determinate Installer](https://github.com/DeterminateSystems/nix-installer)
- Clone this repo and symlink it: `ln -s /path/to/json-workstation ~/.system`

## Devices

| Host | Config Key | Type |
|---|---|---|
| Work MacBook | `JSON-MACBOOK14` | nix-darwin |
| Personal MacBook | `JSON-MACBOOK16` | nix-darwin |
| Personal Linux (JSON-MINI) | `JSON-MINI` | home-manager |
| WSL (JSON-STATION) | `JSON-STATION` | home-manager |

## Install

Each host has a directory under `hosts/` with a `default.nix` config and (where needed) a `bootstrap.sh` script for system-level setup.

### macOS (Work MacBook / Personal MacBook)

```bash
nix --extra-experimental-features 'nix-command flakes' run nix-darwin -- switch --flake .
```

Then enable the 1Password SSH agent and CLI integration in 1Password developer settings.

### JSON-MINI (Pop!_OS workstation)

```bash
git clone https://github.com/jasonwc/json-workstation.git
cd json-workstation && bash hosts/json-mini/bootstrap.sh
```

Configures SSH server (key-only auth), disables sleep/suspend, installs Nix, and applies home-manager.

### JSON-STATION (WSL)

```bash
git clone https://github.com/jasonwc/json-workstation.git
cd json-workstation && bash hosts/json-station/bootstrap.sh
```

Ensures systemd is enabled in WSL, installs Nix, and applies home-manager.

## Maintenance

Update nix dependencies:

```bash
cd ~/.system && nix flake update
```

Apply configuration changes:

```bash
update
```

## Useful links

- https://mynixos.com/home-manager/options/programs
- https://search.nixos.org/packages
- https://nixos-and-flakes.thiscute.world/nixos-with-flakes/modularize-the-configuration
