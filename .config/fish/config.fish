if status is-interactive
    oh-my-posh init fish --config ~/.config/fish/theme.json | source
    set -g fish_key_bindings fish_vi_key_bindings
    fzf_key_bindings
    bind -M insert -m default jk backward-char force-repaint
    fish_config theme choose tomorrow-night-bright
    set -g fish_greeting
    fish_ssh_agent
end
