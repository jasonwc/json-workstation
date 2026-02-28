#!/usr/bin/env bash
nix profile remove direnv
nix profile remove cachix

nix run home-manager -- switch -b backup --flake .

sudo chsh -s /home/coder/.nix-profile/bin/zsh coder
