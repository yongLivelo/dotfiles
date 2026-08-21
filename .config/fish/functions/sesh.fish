function sesh
    if count $argv > 0
        command sesh $argv
        return
    end

    set -l header '  ^a all ^t tmux ^g configs ^x zoxide ^d tmux kill ^f find'
    set -l bindings \
        --bind 'tab:down,btab:up' \
        --bind 'ctrl-a:change-prompt(⚡  )+reload(sesh list --icons)' \
        --bind 'ctrl-t:change-prompt(🪟  )+reload(sesh list -t --icons)' \
        --bind 'ctrl-g:change-prompt(⚙️  )+reload(sesh list -c --icons)' \
        --bind 'ctrl-x:change-prompt(📁  )+reload(sesh list -z --icons)' \
        --bind 'ctrl-f:change-prompt(🔎  )+reload(fd -H -d 2 -t d -E .Trash . ~)' \
        --bind 'ctrl-d:execute(tmux kill-session -t {2..})+change-prompt(⚡  )+reload(sesh list --icons)'

    set -l selection (command sesh list --icons | fzf \
        --no-sort --ansi --border-label ' sesh ' --prompt '⚡  ' \
        --header $header \
        $bindings \
        --preview-window 'right:55%' \
        --preview 'command sesh preview {}'
    )

    if test -n "$selection"
        command sesh connect "$selection"
    end
end
