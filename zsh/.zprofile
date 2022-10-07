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

# > Brew Aliases
alias cleanup='brew cleanup'
alias upgrade='brew update && brew upgrade && brew list >> $DOTFILES/brew_list.txt'
alias upgrade-all='upgrade && update-install'

alias cat='bat --color=always'
alias cat-simp='bat -p --pager=never'
alias la='exa -al --icons --color=always --group-directories-first'
alias ls='exa -a --icons --color=always --group-directories-first'
alias ll='exa -l --icons --color=always'
alias t='htop'

# > Python Aliases
alias python='python3'
alias pip='pip3'
alias python-load-env='python -m venv .venv && source .venv/bin/activate && python -m pip install --upgrade pip'

# > Git Aliases
alias git-load-domain-cko="GITHUB_DOMAIN='git@github-cko'"
alias git-load-domain-personal="GITHUB_DOMAIN='git@github-personal'"
alias git-load-config-cko=fn_git_load_config_cko
alias git-load-config-personal=fn_git_load_config_personal
alias git-clear-branches="git branch | grep -v 'main' | xargs git branch -D"
alias git-clone=fn_git_clone

# > AWS Aliases
alias aws-auth="gimme-aws-creds <<< '0,2,4,5,6,8,9'"
alias aws-switch-region=fn_aws_switch_region
alias aws-get-account='python ~/Execs/aws-account-identifier.py'

