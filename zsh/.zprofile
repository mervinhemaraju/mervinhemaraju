#!/bin/zsh

#*#######################*#
#*##### Referencing #####*#
#*#######################*#

# > Retrieve functions
source ~/bash-scripts/functions.sh

# > Retrieve secrets
source ~/.secrets

#*###################*#
#*##### Aliases #####*#
#*###################*#

# > Terminal Aliases
alias terminal-restart='exec zsh -l'

# > System Related
alias clip='pbcopy'
alias update-list='softwareupdate --list'
alias update-install='softwareupdate --install'
alias flushdns='dscacheutil -flushcache; sudo killall -HUP mDNSResponder'

# > Brew Aliases
alias cleanup='brew cleanup'
alias upgrade='brew update && brew upgrade && brew list > $DOTFILES/brew_list.txt'
alias upgrade-all='upgrade && update-install'

alias cat='bat -p --color=always --pager=never'
alias la='exa -al --icons --color=always --group-directories-first'
alias ls='exa -a --icons --color=always --group-directories-first'
alias ll='exa -l --icons --color=always'
alias t='htop'
alias df='duf'
alias cd='z'
alias find='fd'
alias dig='dog'

# > Python Aliases
alias python='python3'
alias pip='pip3'
alias python-load-env='python -m venv .venv && source .venv/bin/activate && python -m pip install --upgrade pip && pip install pip-chill'
alias python-pypi-upload='python setup.py sdist && python -m twine upload dist/*'
alias pip-chill='pip-chill --no-chill'
alias pyreq='pip-chill > requirements.txt'

# > Git Aliases
alias git-load-domain-cko="GITHUB_DOMAIN='github-cko'"
alias git-load-domain-personal="GITHUB_DOMAIN='github-personal'"
alias git-load-config-cko=fn_git_load_config_cko
alias git-load-config-personal=fn_git_load_config_personal
alias git-clear-branches="git branch | grep -v 'main\|master' | xargs git branch -D"
alias git-clone=fn_git_clone
alias git-r-master="git checkout master && git-clear-branches && git pull"
alias git-r-main="git checkout main && git-clear-branches && git pull"

# > AWS Aliases
# alias aws-auth="gimme-aws-creds <<< '0,2,4,5,6,8,9'"
alias aws-auth='okta-aws-cli -b -z --session-duration 43200'
alias aws-switch-region=fn_aws_switch_region
alias aws-get-account='python $EXECS/aws-account-identifier.py'
alias aws-prod-legacy="aws-auth --aws-iam-idp $AWS_IDP_PL --aws-iam-role 'arn:aws:iam::${AWS_PROD_LEGACY}:role/$AWS_ROLE_IT_PLATFORM_INFRA' --profile cko-prod-legacy-it-platform"
alias aws-dev="aws-auth --aws-iam-idp $AWS_IDP_DEV --aws-iam-role 'arn:aws:iam::${AWS_DEV}:role/$AWS_ROLE_IT_PLATFORM_INFRA' --profile cko-dev-it-platform"
alias aws-mgmt="aws-auth --aws-iam-idp $AWS_IDP_MGMT --aws-iam-role 'arn:aws:iam::${AWS_MGMT}:role/$AWS_ROLE_IT_PLATFORM_INFRA' --profile cko-mgmt-it-platform"
alias aws-playground="aws-auth --aws-iam-idp $AWS_IDP_PLAYGROUND --aws-iam-role 'arn:aws:iam::${AWS_PLAYGROUND}:role/$AWS_ROLE_IT_PLATFORM_INFRA' --profile cko-playground-it-platform"
alias aws-sbox="aws-auth --aws-iam-idp $AWS_IDP_SBOX --aws-iam-role 'arn:aws:iam::${AWS_SBOX}:role/$AWS_ROLE_IT_PLATFORM_INFRA' --profile cko-sbox-it-platform"
alias aws-qa="aws-auth --aws-iam-idp $AWS_IDP_QA --aws-iam-role 'arn:aws:iam::${AWS_QA}:role/$AWS_ROLE_IT_PLATFORM_INFRA' --profile cko-qa-it-platform"
alias aws-prod="aws-auth --aws-iam-idp $AWS_IDP_PROD --aws-iam-role 'arn:aws:iam::${AWS_PROD}:role/$AWS_ROLE_IT_PLATFORM_VO' --profile cko-prod-it-platform"
alias aws-login-basics="aws-prod-legacy & aws-dev & aws-mgmt &"
alias aws-login-all="aws-prod-legacy & aws-dev & aws-mgmt & aws-sbox & aws-qa & aws-prod"
