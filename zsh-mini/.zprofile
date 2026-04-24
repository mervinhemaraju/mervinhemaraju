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

# > Granted.dev
alias assume=". assume"

# > Terminal Aliases
alias terminal-restart='exec zsh -l && assume --unset'

# > Brew Aliases
alias cleanup='brew cleanup'
alias upgrade='brew update && brew upgrade && brew list > $DOTFILES/brew_list.txt'
alias upgrade-all='upgrade && update-install'

# > System Related
alias clip='pbcopy'
alias throw='pbpaste >'
alias update-list='softwareupdate --list'
alias update-install='softwareupdate --install'
alias flushdns='dscacheutil -flushcache; sudo killall -HUP mDNSResponder'
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
alias cpath='copypath'

# > Flutter & Dart aliases
alias fl='flutter'
alias flpg='fl pub get'
alias flr='fl run'
alias fld='fl doctor'
alias fldv='fl doctor -v'
alias drw='dart run build_runner watch'
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
alias kns='kubens'
alias knsf='kns | grep -vE "gke-managed-cim|gke-managed-system|gke-managed-volumepopulator|gmp-public|gmp-system|kube-node-lease|kube-public|kube-system"'
alias kgpar="k get pods --all-namespaces -o custom-columns='NAMESPACE:.metadata.namespace,NAME:.metadata.name,CPU_REQUEST:.spec.containers[*].resources.requests.cpu,MEMORY_REQUEST:.spec.containers[*].resources.requests.memory'"

# > Docker
alias dk="docker"
alias dki="docker images"
alias dkps="docker ps"

# > ArgoCD
alias argo-admin-secret="kgsec -n argocd argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d"
alias argo-pf="k port-forward service/argocd-server -n argocd 8080:443"

# > Pre Commit
alias pca="pre-commit run --all-files"

# > Terraform Docs
alias tfdocs="terraform-docs"
alias tfdocs-gen="terraform-docs markdown table --output-file README.md --output-mode inject ."

# > Other Tools
alias pass="py $DOTFILES/scripts/python/functions/password_generator.py"

# > AWS 
# * scripts
alias aws-logs-finder="python ~/scripts/python/aws-logs-finder/main.py"
alias oci-ssh="~/Dotfiles/scripts/python/oci-ssh-connector/exec.sh"
alias oci-ampere-finder="~/Dotfiles/scripts/python/oci-ampere-finder/exec.sh"

# * configs
alias aws-region-default="export AWS_REGION=eu-west-1"
alias aws-region-switch=fn_aws_switch_region
alias aws-get-account='python $EXECS/aws-account-identifier.py'
alias aws-clear='export AWS_REGION= && export AWS_PROFILE='

# > OCI
alias oci-zeus=oci_zeus
alias oci-poseidon=oci_poseidon
alias oci-gaia=oci_gaia
alias oci-helios=oci_helios

# > GCP
alias gcca="gcloud config configurations activate"
alias gccl="gcloud config configurations list"
alias gccc="gcloud config configurations create"
alias gccd="gcloud config configurations delete"
alias gsp='gcloud config set project'
alias gpl='gcloud projects list --format="table(projectId, name)"'

# > Vercel
alias vrcp="vercel --token=$VERCEL_PLAGUEWORKS_TOKEN"

# > Cloudflare
alias warp="warp-cli"
alias warpc="warp-cli connect"
alias warpdc="warp-cli disconnect"