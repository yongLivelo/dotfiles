#!/usr/bin/fish

tmux rename-window console
tmux split-window -h -p 50
tmux new-window -n editor
tmux send-keys 'nvim -c "lua require(\"persistence\").load()"' C-m
tmux select-window -t ":editor"
