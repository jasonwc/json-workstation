# jasonwc
## Pre-requisites
- Install Nix via Kandji or determinate installer
- Install Cachix via mo cli
- Install home-manager

# Darwin install

Apply the system configuration with [nix-darwin](https://github.com/LnL7/nix-darwin):

```bash
nix --extra-experimental-features 'nix-command flakes' run nix-darwin -- switch --flake ~/workspace/workstations/home/jasonwc
```

Finally, enable the 1password ssh agent and cli integration in the 1password developer settings.

# Coder install

Run `install.sh`

## Maintenance

To update nix dependencies:

```
cd ~/.system && nix flake update
```

To apply changes to the configuration:

```
update
```

## Questions
- VSCode plugin from Adam
- 1Password plugin from Luke
- Why nix.enable false when determinate? Luke doesn't seem to need to do that

## Useful things
https://mynixos.com/home-manager/options/programs
https://search.nixos.org/packages
https://nixos-and-flakes.thiscute.world/nixos-with-flakes/modularize-the-configuration
