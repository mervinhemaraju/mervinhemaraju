
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
export PATH="/opt/homebrew/opt/ruby/bin:$PATH"
export PATH="/opt/homebrew/lib/ruby/gems/3.4.0/bin:$PATH"
export PATH="$(brew --prefix helm@3)/bin:$PATH"
export DOTFILES="$HOME/Dotfiles" # * Path to dotfiles
export EXECS="$HOME/Execs" # * Path to executables
export KEYS="$HOME/MyKeys" # * Path to SSH Keys
export PROJECTS="$HOME/Projects" # * Path to Projects
export ANSIBLE_CONFIG="$HOME/.ansible.cfg" # * Path to ansible config file
export OBJC_DISABLE_INITIALIZE_FORK_SAFETY=YES
export KUBECONFIG=~/.kube/configs/gke_cockpit_prod:~/.kube/configs/oci_poseidon:~/.kube/configs/aws_dke_dev:~/.kube/configs/minikube
export JAVA_HOME="/opt/homebrew/opt/openjdk@21"
export CLOUDSDK_PYTHON="/opt/homebrew/bin//python3.11" # Google Cloud python path 
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
plugins=(azure gcloud aws history git dotenv macos python terraform ansible docker docker-compose golang pip vscode vagrant kubectl minikube helm kubectx argocd zsh-autosuggestions zsh-docker-aliases zsh-syntax-highlighting)

# > Sourcing
source $ZSH/oh-my-zsh.sh # * ZSH
source ~/.zprofile # * Load zprofile

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"

# > Commands

# * For AWS CLI completer
# complete -C '/usr/local/bin/aws_completer' aws
complete -C '/opt/homebrew/bin/aws_completer' aws

# > Autoloads
autoload bashcompinit && bashcompinit
autoload -Uz compinit && compinit

# > MOTD
figlet -cf slant "TH3PL4GU3" | lolcat

# > Evals
eval "$(starship init zsh)" # * Starship init
eval "$(zoxide init zsh)" # * Zoxide init

# > Others
[[ -s "$HOME/.profile" ]] && source "$HOME/.profile" # Load the default .profile

[[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm" # Load RVM into a shell session *as a function*

[[ -e "/Users/mervinhemaraju/lib/oci_autocomplete.sh" ]] && source "/Users/mervinhemaraju/lib/oci_autocomplete.sh"# The following lines have been added by Docker Desktop to enable Docker CLI completions.
fpath=(/Users/mervinhemaraju/.docker/completions $fpath)
autoload -Uz compinit
compinit
# End of Docker CLI completions

# Added by Antigravity
export PATH="/Users/mervinhemaraju/.antigravity/antigravity/bin:$PATH"

# Added by Antigravity
export PATH="/Users/mervinhemaraju/.antigravity/antigravity/bin:$PATH"
