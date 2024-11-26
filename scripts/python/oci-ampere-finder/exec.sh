#!/bin/zsh

source ~/DotFiles/scripts/python/oci-ampere-finder/.venv/bin/activate

source ~/DotFiles/scripts/python/oci-ampere-finder/secrets.env

python ~/DotFiles/scripts/python/oci-ampere-finder/runner.py

deactivate