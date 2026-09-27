#!/usr/bin/fish

tmux new-window -n editor
tmux send-keys 'rm -rf /tmp/godot.nvim && godotdev.sh' C-m
tmux select-window -t ":editor"
