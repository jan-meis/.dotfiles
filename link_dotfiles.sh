#!/usr/bin/env bash
readarray -t tracked < $HOME/.dotfiles/tracked

for path in "${tracked[@]}"
do
    mkdir -p "$HOME/$(dirname ${path})"
    ln -s  "$HOME/.dotfiles/${path}" ""$HOME/$(dirname ${path})
done
