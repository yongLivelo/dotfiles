#!/usr/bin/fish

tmux rename-window console
tmux split-window -h -p 50
tmux new-window -n editor
tmux split-window -h -p 40
tmux select-pane -t 1
tmux send-keys 'nvim -c "lua require(\"persistence\").load()"' C-m
tmux select-pane -t 2
tmux send-keys opencode C-m
tmux select-window -t ":editor"
