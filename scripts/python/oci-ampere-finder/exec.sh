#!/bin/zsh

source ~/scripts/python/oci-ampere-finder/.venv/bin/activate

source ~/scripts/python/oci-ampere-finder/secrets.env

python ~/scripts/python/oci-ampere-finder/runner.py

deactivate