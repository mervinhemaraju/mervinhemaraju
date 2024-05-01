#!/bin/zsh

source ~/Dotfiles/scripts/python/oci-ssh-connector/.venv/bin/activate

source ~/Dotfiles/scripts/python/oci-ssh-connector/secrets.env

python ~/Dotfiles/scripts/python/oci-ssh-connector/main.py

deactivate