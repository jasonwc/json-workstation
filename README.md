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
| Coder Workspace | `coder` | home-manager |
| Personal Linux (JSON-MINI) | `JSON-MINI` | home-manager |
| WSL (JSON-STATION) | `JSON-STATION` | home-manager |

## Install

### macOS (nix-darwin)

```bash
nix --extra-experimental-features 'nix-command flakes' run nix-darwin -- switch --flake .
```

Then enable the 1Password SSH agent and CLI integration in 1Password developer settings.

### Linux / WSL / Coder (home-manager)

```bash
nix run home-manager -- switch -b backup --flake .
```

For Coder, run `install.sh` or `coder-vm.sh` if removing existing direnv/cachix from profile.

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
