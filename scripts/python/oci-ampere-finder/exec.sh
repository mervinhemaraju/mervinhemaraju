#!/bin/zsh

source ~/Dotfiles/scripts/python/oci-ampere-finder/.venv/bin/activate

source ~/Dotfiles/scripts/python/oci-ampere-finder/secrets.env

python ~/Dotfiles/scripts/python/oci-ampere-finder/runner.py

deactivate