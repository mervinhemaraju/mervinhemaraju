#!/bin/zsh

source ~/DotFiles/scripts/python/oci-ssh-connector/.venv/bin/activate

source ~/DotFiles/scripts/python/oci-ssh-connector/secrets.env

python ~/DotFiles/scripts/python/oci-ssh-connector/main.py

deactivate