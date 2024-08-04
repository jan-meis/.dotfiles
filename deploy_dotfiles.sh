#!/usr/bin/env bash
readarray -t tracked < $HOME/.dotfiles/tracked

for path in "${tracked[@]}"
do
    mkdir -p "$HOME/$(dirname ${path})"
    cp -r "$HOME/.dotfiles/${path}" "$HOME/$(dirname ${path})"
done
