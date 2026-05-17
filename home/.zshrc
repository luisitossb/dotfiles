# Exports
export EDITOR=nvim
export ZSH="$HOME/.oh-my-zsh"
export PATH=$PATH:~/.cargo/bin/
export PATH=$PATH:~/.local/bin/

# oh-my-zsh plugins
plugins=(
    git
    sudo
    web-search
    archlinux
    zsh-autosuggestions
    zsh-syntax-highlighting
    fast-syntax-highlighting
    copyfile
    copybuffer
    dirhistory
)
source $ZSH/oh-my-zsh.sh

# FZF key bindings (CTRL+R for fuzzy history)
source <(fzf --zsh)

# History
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt appendhistory

# Prompt
eval "$(oh-my-posh init zsh --config $HOME/.config/ohmyposh/luisito.toml)"

# General
alias ..='cd ..'
alias c='clear'
alias nf='fastfetch'
alias pf='fastfetch'
alias ff='fastfetch'
alias ls='eza -a --icons=always'
alias ll='eza -al --icons=always'
alias lt='eza -a --tree --level=1 --icons=always'
alias shutdown='systemctl poweroff'
alias v='$EDITOR'
alias vim='$EDITOR'
alias wifi='nmtui'
alias lock='hyprlock'
alias clock='tty-clock'
alias update-grub='sudo grub-mkconfig -o /boot/grub/grub.cfg'

# Git
alias gs="git status"
alias ga="git add"
alias gc="git commit -m"
alias gp="git push"
alias gpl="git pull"
alias gst="git stash"
alias gsp="git stash; git pull"
alias gfo="git fetch origin"
alias gcheck="git checkout"
alias gcredential="git config credential.helper store"

# Fastfetch on new terminal
if [[ $(tty) == *"pts"* ]] && [[ ! -f ~/.config/quickshell/state/hide-fastfetch ]]; then
    fastfetch
fi

# Personal config
[[ -f ~/.zshrc_custom ]] && source ~/.zshrc_custom
