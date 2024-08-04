#!/usr/bin/env bash
readarray -t tracked < $HOME/.dotfiles/tracked

for path in "${tracked[@]}"
do
    mkdir -p "$HOME/.dotfiles/$(dirname ${path})"
    cp -r "$HOME/${path}" "$HOME/.dotfiles/$(dirname ${path})"
done
