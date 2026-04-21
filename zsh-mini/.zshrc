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
export DOTFILES="$HOME/Mervin/Dotfiles" # * Path to dotfiles
export EXECS="$HOME/Mervin/Execs" # * Path to executables
export KEYS="$HOME/Mervin/MyKeys" # * Path to SSH Keys
export PROJECTS="$HOME/Mervin/Projects" # * Path to Projects
export KUBECONFIG=~/.kube/configs/oci_prod_zeus:~/.kube/configs/oci_dev_helios:~/.kube/configs/oci_mgmt_poseidon
export JAVA_HOME="/opt/homebrew/opt/openjdk@21"
export CLOUDSDK_PYTHON="/opt/homebrew/bin//python3.11" # Google Cloud python path 
export GOBIN="$(go env GOPATH)/bin" # * Path to go bin
export OBJC_DISABLE_INITIALIZE_FORK_SAFETY=YES
# export GRANTED_ENABLE_AUTO_REASSUME=true # * Auto re assume roles for granted

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="robbyrussell"

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(azure ansible argocd alias-finder aws copypath dotenv docker docker-compose gcloud history git macos python rust terraform golang pip vscode vagrant kubectl helm kubectx)

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

# > Brew installations
source $(brew --prefix zsh-fast-syntax-highlighting)/share/zsh-fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh
source $(brew --prefix zsh-autocomplete)/share/zsh-autocomplete/zsh-autocomplete.plugin.zsh
source $(brew --prefix zsh-autosuggestions)/share/zsh-autosuggestions/zsh-autosuggestions.zsh