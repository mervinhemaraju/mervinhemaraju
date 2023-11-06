
# Environment Variables
export JAVA_HOME=$(/usr/libexec/java_home)

# Fpaths
fpath=(/Users/mervin.hemaraju/.granted/zsh_autocomplete/assume/ $fpath)

fpath=(/Users/mervin.hemaraju/.granted/zsh_autocomplete/granted/ $fpath)


alias assume="source assume --duration 10h"
. "$HOME/.cargo/env"
