# If not running interactively, don't do anything
[[ $- != *i* ]] && return

export EDITOR=nvim
export PATH=$PATH:~/.cargo/bin/
export PATH=$PATH:~/.local/bin/
