eval "$(/opt/homebrew/bin/brew shellenv)"
bindkey -e
[[ -f ~/.zsh_aliases ]] && source ~/.zsh_aliases
# Writable completion cache so gardenctl doesn't try to write into root-owned fpath dirs.
# Must be on fpath BEFORE compinit so cached completions (e.g. _kubectl) get autoloaded.
export ZSH_CACHE_DIR="$HOME/.zsh/cache"
mkdir -p "$ZSH_CACHE_DIR/completions"
fpath=("$ZSH_CACHE_DIR/completions" $fpath)
# Cache kubectl completions — delete ~/.zsh/cache/completions/_kubectl to regenerate
_kubectl_comp="$ZSH_CACHE_DIR/completions/_kubectl"
[[ -f $_kubectl_comp ]] || command kubectl completion zsh >| $_kubectl_comp
autoload -Uz compinit && compinit
# kubectl and k are aliased to `kubecolor`; with completealiases off, zsh completes
# the expanded command, so register kubectl's completion under `kubecolor`.
compdef kubecolor=kubectl
compdef kubectl=kubectl
compdef k=kubectl
source <(fzf --zsh)
source <(stern --completion=zsh)
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
export TMUX_DEFAULT_TERMINAL="tmux-256color"

[[ -f ~/.zsh_private ]] && source ~/.zsh_private

# Machine-local secrets (not in dotfiles/git). Add LITELLM_API_KEY etc. here.
[[ -f ~/.zshenv ]] && source ~/.zshenv
