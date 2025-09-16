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
# alias ssh-keys-load-prod='ssh-add -D && ssh-add /Users/mervin.hemaraju/MyKeys/itops_aws.pem && ssh-add /Users/mervin.hemaraju/MyKeys/prod.pem && ssh-add /Users/mervin.hemaraju/MyKeys/hsm-tooling-mgmt.pem && ssh-add -l'
# alias ssh-keys-load-dev='ssh-add -D && ssh-add /Users/mervin.hemaraju/MyKeys/itops_lon.pem && ssh-add /Users/mervin.hemaraju/MyKeys/mgmt-test.pem && ssh-add -l'
# alias ssh-keys-clear='ssh-add -D'

# > Terminal Aliases
alias terminal-restart='exec zsh -l && assume --unset'

# > System Related
alias clip='pbcopy'
alias throw='pbpaste >'
alias update-list='softwareupdate --list'
alias update-install='softwareupdate --install'
alias flushdns='dscacheutil -flushcache; sudo killall -HUP mDNSResponder'

# > Brew Aliases
alias cleanup='brew cleanup'
alias upgrade='brew update && brew upgrade && brew list > $DOTFILES/brew_list.txt'
alias upgrade-all='upgrade && update-install'

alias cat='bat -p'
alias la='lsd -al --color=always --group-directories-first'
alias ls='lsd -a --color=always --group-directories-first'
alias ll='lsd -l --color=always'
alias t='htop'
alias df='duf'
alias cd='z'
alias find='fd'
alias dig='doggo'
alias rmf='rm -rf'

# > Flutter & Dart aliases
alias f='flutter'
alias fpg='f pub get'
alias fr='f run'
alias fd='f doctor'
alias fdv='f doctor -v'
alias drb='dart run build_runner build'

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
alias git-load-domain-work="export GITHUB_DOMAIN='github-dke'"
alias git-load-domain-personal="export GITHUB_DOMAIN='github-personal'"
alias git-load-config-work=fn_git_load_config_work
alias git-load-config-personal=fn_git_load_config_personal
alias git-clear-branches="git branch | grep -v '\bmain\b\|\bmaster\b\|\bdev\b\|\bstg\b\|\bstaging\b\|\bqa\b' | xargs git branch -D"
alias gcl="py $DOTFILES/scripts/python/functions/git_clone.py"
alias gca='f(){ git checkout ${1:-main} && git-clear-branches && git pull origin ${1:-main}; }; f'
alias greset="git reset --soft HEAD~1"

# > Kubernetes
alias kust="k kustomize"
alias mk="minikube"
alias kctx="kubectx"
alias kns="kubens"

# > ArgoCD
alias argo-admin-secret="kgsec -n argocd argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d"
alias argo-pf="k port-forward service/argocd-server -n argocd 8080:443"

# > Pre Commit
alias pca="pre-commit run --all-files"

# > Terraform Docs
# alias tfdocs="pre-commit run --all-files"

# > Other Tools
alias pass="py $DOTFILES/scripts/python/functions/password_generator.py"

# > AWS 
# * Scripts
alias aws-logs-finder="python ~/scripts/python/aws-logs-finder/main.py"
alias oci-ssh="~/Dotfiles/scripts/python/oci-ssh-connector/exec.sh"
alias oci-ampere-finder="~/Dotfiles/scripts/python/oci-ampere-finder/exec.sh"

# > OCI
alias oci-zeus=oci_zeus
alias oci-poseidon=oci_poseidon
alias oci-gaia=oci_gaia
alias oci-helios=oci_helios

# * Aws configs
alias aws-region-default="export AWS_REGION=eu-west-1"
alias aws-region-switch=fn_aws_switch_region
alias aws-get-account='python $EXECS/aws-account-identifier.py'
alias aws-clear='export AWS_REGION= && export AWS_PROFILE='

# * Vercel
alias vrcp="vercel --token=$VERCEL_PLAGUEWORKS_TOKEN"

# * Aws authenticate
# alias aws-login="aws-login-na && aws-login-legacy"
# alias aws-login-na="export AWS_REGION=eu-west-1 && okta-aws-cli --aws-acct-fed-app-id $OKTA_AWS_ACCOUNT_FEDERATION_APP_ID_NA --aws-session-duration 43200 -bz --all-profiles"
# alias aws-login-legacy="export AWS_REGION=eu-west-1 && okta-aws-cli --aws-acct-fed-app-id $OKTA_AWS_ACCOUNT_FEDERATION_APP_ID_LEGACY --aws-session-duration 43200 -bz --all-profiles"
# alias aws-login-playground="okta-aws-cli --aws-acct-fed-app-id $OKTA_AWS_ACCOUNT_FEDERATION_APP_ID_NA --aws-iam-idp $AWS_IDP_NA_PG -bz --profile cko-na-playground"
# alias aws-login-aft="okta-aws-cli --aws-acct-fed-app-id $OKTA_AWS_ACCOUNT_FEDERATION_APP_ID_NA --aws-iam-idp $AWS_IDP_NA_AFT -bz --profile cko-na-aft"
# alias aws-login-root="okta-aws-cli --aws-acct-fed-app-id $OKTA_AWS_ACCOUNT_FEDERATION_APP_ID_NA --aws-iam-idp $AWS_IDP_NA_ROOT -bz --profile cko-na-root"
# alias aws-login-ccp="okta-aws-cli --aws-acct-fed-app-id $OKTA_AWS_ACCOUNT_FEDERATION_APP_ID_NA --aws-iam-idp $AWS_IDP_NA_CCP -bz --profile cko-na-ccp"
# alias aws-login-ccp-dev="okta-aws-cli --aws-acct-fed-app-id $OKTA_AWS_ACCOUNT_FEDERATION_APP_ID_NA --aws-iam-idp $AWS_IDP_NA_CCP_DEV -bz --profile cko-na-ccp-dev"
# alias aws-login-na="export AWS_REGION=eu-west-1 && okta-aws-cli --aws-acct-fed-app-id $OKTA_AWS_ACCOUNT_FEDERATION_APP_ID_NA -bz --all-profiles"

# * Mass login
# alias aws-login-basics="aws-prod-legacy & aws-dev & aws-mgmt &"
# alias aws-login="aws-auth-legacy --all-profiles"
# alias aws-login-all="aws-prod-legacy & aws-dev & aws-mgmt & aws-sbox & aws-qa & aws-prod & aws-na-playground &"

# * Aws Service Login
# alias aws-ca-versions="fn_aws_ca_versions"
# alias aws-ca-login="aws codeartifact login --tool pip --repository euw1pypackages --domain cko-it-packages --domain-owner $(fn_aws_current_account) --region $AWS_REGION"
# alias aws-ecr-login="aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $(fn_aws_current_account).dkr.ecr.eu-west-1.amazonaws.com"

# * Nektos / Act
# alias act-cko-it="act -P $(fn_aws_current_account).dkr.ecr.eu-west-1.amazonaws.com/cko-core-platform/github-action-runner-cko-it:1.7.0 -s GITHUB_TOKEN=$GITHUB_CKO_WORKFLOWS"