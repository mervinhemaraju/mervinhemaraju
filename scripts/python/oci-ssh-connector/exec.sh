#!/bin/zsh

source ~/scripts/python/oci-ssh-connector/.venv/bin/activate

source ~/scripts/python/oci-ssh-connector/secrets.env

python ~/scripts/python/oci-ssh-connector/runner.py

deactivate