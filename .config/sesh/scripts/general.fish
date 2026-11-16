#!/usr/bin/fish

tmux rename-window console
tmux split-window -h -p 50
tmux new-window -n editor
tmux split-window -h -p 40
tmux select-pane -t 1
if test -f project.godot
    tmux send-keys 'nvim -c "lua require[[persistence]].load()" -c GodotPin' C-m
else
    tmux send-keys 'nvim -c "lua require[[persistence]].load()"' C-m
end
tmux select-pane -t 2
tmux send-keys opencode C-m
tmux select-window -t ":editor"
