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

# > SSH Key sessions
alias ssh-keys-load-prod='ssh-add -D && ssh-add /Users/mervin.hemaraju/MyKeys/itops_aws.pem && ssh-add /Users/mervin.hemaraju/MyKeys/prod.pem && ssh-add /Users/mervin.hemaraju/MyKeys/mgmt.pem && ssh-add -l'
alias ssh-keys-load-dev='ssh-add -D && ssh-add /Users/mervin.hemaraju/MyKeys/itops_lon.pem && ssh-add /Users/mervin.hemaraju/MyKeys/mgmt-test.pem && ssh-add -l'
alias ssh-keys-clear='ssh-add -D'

# > Terminal Aliases
alias terminal-restart='exec zsh -l && assume --unset'

# > System Related
alias clip='pbcopy'
alias update-list='softwareupdate --list'
alias update-install='softwareupdate --install'
alias flushdns='dscacheutil -flushcache; sudo killall -HUP mDNSResponder'

# > Brew Aliases
alias cleanup='brew cleanup'
alias upgrade='brew update && brew upgrade && brew list > $DOTFILES/brew_list.txt'
alias upgrade-all='upgrade && update-install'

alias cat='bat -p'
alias la='exa -al --icons --color=always --group-directories-first'
alias ls='exa -a --icons --color=always --group-directories-first'
alias ll='exa -l --icons --color=always'
alias t='htop'
alias df='duf'
alias cd='z'
alias find='fd'
alias dig='dog'

# > Python Aliases
alias python='python3.11'
alias py='python3.11'
alias pip='pip3.11'
alias python-load-env='python -m venv .venv && source .venv/bin/activate && python -m pip install --upgrade pip && pip install pip-chill'
alias python-pypi-upload='python setup.py sdist && python -m twine upload dist/*'
alias pip-chill='pip-chill --no-chill'
alias pyreq='pip-chill > requirements.txt'
alias pip-unset='pip config unset global.index-url'

# > Git Aliases
alias git-load-domain-cko="GITHUB_DOMAIN='github-cko'"
alias git-load-domain-personal="GITHUB_DOMAIN='github-personal'"
alias git-load-config-cko=fn_git_load_config_cko
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

# * Aws authenticate
alias aws-login="export AWS_REGION=eu-west-1 && okta-aws-cli -b -z --session-duration 43200 --all-profiles"
# alias aws-auth-na="export AWS_REGION=eu-west-1 && okta-aws-cli --aws-acct-fed-app-id $OKTA_AWS_ACCOUNT_FEDERATION_APP_ID_NA -b -z"

# * New Accounts
# alias aws-na-playground="aws-auth-na --profile cko-playground-na"

# * Legacy Accounts
# alias aws-prod-legacy="aws-auth-legacy --aws-iam-idp $AWS_IDP_PL --aws-iam-role 'arn:aws:iam::${AWS_PROD_LEGACY}:role/$AWS_ROLE_IT_PLATFORM_INFRA' --profile cko-prod-legacy"
# alias aws-dev="aws-auth-legacy --aws-iam-idp $AWS_IDP_DEV --aws-iam-role 'arn:aws:iam::${AWS_DEV}:role/$AWS_ROLE_IT_PLATFORM_INFRA' --profile cko-dev"
# alias aws-mgmt="aws-auth-legacy --aws-iam-idp $AWS_IDP_MGMT --aws-iam-role 'arn:aws:iam::${AWS_MGMT}:role/$AWS_ROLE_IT_PLATFORM_INFRA' --profile cko-mgmt"
# alias aws-sbox="aws-auth-legacy --aws-iam-idp $AWS_IDP_SBOX --aws-iam-role 'arn:aws:iam::${AWS_SBOX}:role/$AWS_ROLE_IT_PLATFORM_INFRA' --profile cko-sbox"
# alias aws-qa="aws-auth-legacy --aws-iam-idp $AWS_IDP_QA --aws-iam-role 'arn:aws:iam::${AWS_QA}:role/$AWS_ROLE_IT_PLATFORM_INFRA' --profile cko-qa"
# alias aws-prod="aws-auth-legacy --aws-iam-idp $AWS_IDP_PROD --aws-iam-role 'arn:aws:iam::${AWS_PROD}:role/$AWS_ROLE_IT_PLATFORM_INFRA' --profile cko-prod"

# * Mass login
# alias aws-login-basics="aws-prod-legacy & aws-dev & aws-mgmt &"
# alias aws-login="aws-auth-legacy --all-profiles"
# alias aws-login-all="aws-prod-legacy & aws-dev & aws-mgmt & aws-sbox & aws-qa & aws-prod & aws-na-playground &"

# * Aws Service Login
alias aws-codeartifact-login-ckoit="aws codeartifact login --tool pip --repository euw1pypackages --domain cko-it-packages --domain-owner $(fn_aws_current_account) --region $AWS_REGION"
alias aws-ecr-login="aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $(fn_aws_current_account).dkr.ecr.eu-west-1.amazonaws.com"

# * Nektos / Act
alias act-cko-it="act -P $(fn_aws_current_account).dkr.ecr.eu-west-1.amazonaws.com/cko-core-platform/github-action-runner-cko-it:1.7.0 -s GITHUB_TOKEN=$GITHUB_CKO_WORKFLOWS"