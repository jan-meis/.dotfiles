bindkey -e
[[ -f ~/.zsh_aliases ]] && source ~/.zsh_aliases
autoload -Uz compinit && compinit
source <(fzf --zsh)
source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
# Cache gardenctl rc output — regenerate with: gardenctl rc zsh > ~/.gardenctl_rc.zsh
_gardenctl_rc=~/.gardenctl_rc.zsh
if [[ ! -f $_gardenctl_rc ]]; then gardenctl rc zsh >| $_gardenctl_rc; fi
source $_gardenctl_rc

PS1='%F{yellow}%~ %(?.%F{green}.%F{red})%#%f '
HISTFILE=~/.zsh_history
HISTSIZE=999999999
SAVEHIST=$HISTSIZE
setopt inc_append_history
setopt share_history
export GPG_TTY=$(tty)

export PATH="$HOME/.local/bin:$PATH"
_brew=/opt/homebrew
export PATH=$_brew/opt/coreutils/libexec/gnubin:$PATH
export PATH=$_brew/opt/gnu-sed/libexec/gnubin:$PATH
export PATH=$_brew/opt/gnu-tar/libexec/gnubin:$PATH
export PATH=$_brew/opt/grep/libexec/gnubin:$PATH
export PATH=$_brew/opt/gzip/bin:$PATH
unset _brew _gardenctl_rc

bindkey '^P' up-history
bindkey '^N' down-history
bindkey '^U' kill-buffer
bindkey '^[e' _expand_alias

export GOPATH="$HOME/go"
export PATH="$GOPATH/bin:$PATH"

export BUILDMACHINE="NONE"
export EDITOR="nvim"
