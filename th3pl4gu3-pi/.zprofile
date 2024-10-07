#!/bin/zsh

#*#######################*#
#*##### Referencing #####*#
#*#######################*#

# > Retrieve functions
source ~/scripts/bash/functions.sh

# > Retrieve secrets
source ~/.secrets

#*###################*#
#*##### Aliases #####*#
#*###################*#

# > Terminal Aliases
alias terminal-restart='exec zsh -l && assume --unset'

# > System Related
alias clip='xclip'
alias throw='xclip -selection clipboard -o >'
alias update='sudo apt-get update -y && sudo apt-get upgrade -y'
alias update-all='update && sudo apt-get dist-upgrade'
alias flushdns='sudo resolvectl flush-caches'

alias cat='bat -p'
alias la='lsd -al --color=always --group-directories-first'
alias ls='lsd -a --color=always --group-directories-first'
alias ll='lsd -l --color=always'
alias t='htop'
alias df='duf'
alias cd='z'
alias find='fd'
alias dig='doggo'
alias cpp='rsync -ah --progress'
alias rmf='rm -rf'

# > Python Aliases
alias python='python3.11'
alias py='python3.11'
alias pip='pip3.11'
alias python-load-env='python -m venv .venv && source .venv/bin/activate && python -m pip install --upgrade pip && pip install pip-chill'
alias python-pypi-upload='python setup.py sdist && python -m twine upload dist/*'
alias pip-chill='pip-chill --no-chill'
alias pip-ins-req='pip install -r requirements.txt'
alias pip-req='pip-chill > requirements.txt'
alias pip-unset='pip config unset global.index-url'

# > Git Aliases
alias git-load-domain-personal="GITHUB_DOMAIN='github-personal'"
alias git-load-config-personal=fn_git_load_config_personal
alias git-clear-branches="git branch | grep -v 'main\|master' | xargs git branch -D"
alias git-clone=fn_git_clone
alias grms="git checkout master && git-clear-branches && git pull"
alias grm="git checkout main && git-clear-branches && git pull"
alias greset="git reset --soft HEAD~1"

# > Kubernetes
alias k="kubectl"

# > Pre Commit
alias pca="pre-commit run --all-files"

# > Terraform Docs
alias tfdocs="pre-commit run --all-files"

# > AWS 

# * Scripts
alias aws-logs-finder="python ~/scripts/python/aws-logs-finder/main.py"
alias oci-ssh="~/Dotfiles/scripts/python/oci-ssh-connector/exec.sh"
alias oci-ampere-finder="~/Dotfiles/scripts/python/oci-ampere-finder/exec.sh"

# * Aws configs
alias aws-region-default="export AWS_REGION=eu-west-1"
alias aws-region-switch=fn_aws_switch_region
alias aws-get-account='python $EXECS/aws-account-identifier.py'
alias aws-clear='export AWS_REGION= && export AWS_PROFILE='

# * Aws Service Login
alias aws-ca-versions="fn_aws_ca_versions"
alias aws-ca-login="aws codeartifact login --tool pip --repository euw1pypackages --domain cko-it-packages --domain-owner $(fn_aws_current_account) --region $AWS_REGION"
alias aws-ecr-login="aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $(fn_aws_current_account).dkr.ecr.eu-west-1.amazonaws.com"

# * Nektos / Act
alias act-cko-it="act -P $(fn_aws_current_account).dkr.ecr.eu-west-1.amazonaws.com/cko-core-platform/github-action-runner-cko-it:1.7.0 -s GITHUB_TOKEN=$GITHUB_CKO_WORKFLOWS"