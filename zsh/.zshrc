
# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

# > Variable exports
export ZSH="$HOME/.oh-my-zsh" # * Path to your oh-my-zsh installation.
export PATH="$PATH:/opt/homebrew/bin/" # * Path to homebrew installations
export PATH="$HOME/.cargo/bin:$PATH"
export PATH="$HOME/flutter/bin:$PATH"
export PATH="$PATH":"$HOME/.pub-cache/bin"
export PATH="$PATH:$HOME/.rvm/bin"
export PATH="/opt/homebrew/opt/postgresql@17/bin:$PATH" # * Path to postgresql installations
export PATH="/opt/homebrew/opt/node@22/bin:$PATH" # * Path to node installations
export PATH="/opt/homebrew/opt/openjdk@21/bin:$PATH" # * Path to jdk installation
export PATH="/opt/homebrew/opt/ruby/bin:$PATH" # * Ruby
export PATH="/opt/homebrew/lib/ruby/gems/3.4.0/bin:$PATH" # * Ruby Gems
export PATH="$(brew --prefix helm@3)/bin:$PATH" # * Helm3
export PATH="$HOME/.antigravity/antigravity/bin:$PATH" # * Antigravity

# External SSD app binaries
export PATH="/Volumes/mervin-ext-ssd/Applications/Docker.app/Contents/Resources/bin:$PATH"

export DOTFILES="$HOME/Dotfiles" # * Path to dotfiles
export EXECS="$HOME/Execs" # * Path to executables
export KEYS="$HOME/MyKeys" # * Path to SSH Keys
export PROJECTS="$HOME/Projects" # * Path to Projects
export PROJECTSEXT="/Volumes/mervin-ext-ssd/Projects" # * Path to Projects
export ANSIBLE_CONFIG="$HOME/.ansible.cfg" # * Path to ansible config file
export OBJC_DISABLE_INITIALIZE_FORK_SAFETY=YES
export KUBECONFIG=~/.kube/configs/gke_cockpit_prod:~/.kube/configs/aws_dke_dev:~/.kube/configs/minikube:~/.kube/configs/oci_prod_zeus:~/.kube/configs/oci_dev_helios:~/.kube/configs/oci_mgmt_poseidon:~/.kube/configs/vw-i-eur-pop-ireland
export JAVA_HOME="/opt/homebrew/opt/openjdk@21"
export CLOUDSDK_PYTHON="/opt/homebrew/bin//python3.11" # Google Cloud python path 
export GOBIN="$(go env GOPATH)/bin" # * Path to go bin
# export GRANTED_ENABLE_AUTO_REASSUME=true # * Auto re assume roles for granted

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="robbyrussell"

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment one of the following lines to change the auto-update behavior
# zstyle ':omz:update' mode disabled  # disable automatic updates
# zstyle ':omz:update' mode auto      # update automatically without asking
# zstyle ':omz:update' mode reminder  # just remind me to update when it's time

# Uncomment the following line to change how often to auto-update (in days).
# zstyle ':omz:update' frequency 13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# You can also set it to another string to have that shown instead of the default red dots.
# e.g. COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
# Caution: this setting can cause issues with multiline prompts in zsh < 5.7.1 (see #5765)
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(azure ansible argocd alias-finder aws copypath dotenv docker docker-compose gcloud history git macos python rust terraform golang pip vscode vagrant kubectl minikube helm kubectx)

# > Sourcing
source $ZSH/oh-my-zsh.sh # * ZSH
source ~/.zprofile # * Load zprofile

# > Autocompletes for external tools
complete -C '/opt/homebrew/bin/aws_completer' aws # * AWS CLI
[[ -e "/Users/mervinhemaraju/lib/oci_autocomplete.sh" ]] && source "/Users/mervinhemaraju/lib/oci_autocomplete.sh" # * OCI CLI

# > Autoloads
autoload -U +X bashcompinit && bashcompinit
autoload -U +X compinit && compinit

# > MOTD
figlet -cf slant "TH3PL4GU3" | lolcat

# > Evals
eval "$(starship init zsh)" # * Starship init
eval "$(zoxide init zsh)" # * Zoxide init

# > Others
[[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm" # Load RVM into a shell session *as a function*

# Brew installations
source $(brew --prefix zsh-fast-syntax-highlighting)/share/zsh-fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh
source $(brew --prefix zsh-autocomplete)/share/zsh-autocomplete/zsh-autocomplete.plugin.zsh
source $(brew --prefix zsh-autosuggestions)/share/zsh-autosuggestions/zsh-autosuggestions.zsh