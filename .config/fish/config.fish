function fish_user_key_bindings
    for mode in insert default visual
        bind -M $mode \cp up-or-search
        bind -M $mode \cn down-or-search
        bind -M $mode \cf forward-char
        bind -M $mode \cz 'commandline -r "sesh connect (sesh list -c --icons | fzf-tmux -p 80%,70% --no-sort --ansi --border-label \" sesh \" --prompt \"⚡ \" --bind \"tab:down,btab:up\" --preview-window \"right:55%\" --bind \"ctrl-d:execute(tmux kill-session -t {2..})+change-prompt(⚡  )+reload(sesh list -c --icons)\" --preview \"sesh preview {}\")"; commandline -f execute'
    end
end

if status is-interactive
    oh-my-posh init fish --config ~/.config/fish/theme.json | source
    set -g fish_key_bindings fish_vi_key_bindings
    fish_user_key_bindings
    fzf_key_bindings
    bind -M insert -m default jk backward-char force-repaint
    bind -M visual -m default jk backward-char force-repaint

    fish_config theme choose tomorrow-night-bright
    set -g fish_greeting
    if type -q keychain
        SHELL=(which fish) keychain --quiet --eval id_ed25519 | source
    end
    set -gx EDITOR nvim

    function y
        set tmp (mktemp -t "yazi-cwd.XXXXXX")
        command yazi $argv --cwd-file="$tmp"
        if read -z cwd <"$tmp"; and [ "$cwd" != "$PWD" ]; and test -d "$cwd"
            builtin cd -- "$cwd"
        end
        rm -f -- "$tmp"
    end

    alias n='nvim'

    zoxide init --cmd cd fish | source
    alias ls eza
    fish_add_path "$HOME/.tmux/plugins/tmuxifier/bin"
    set -gx TMUXIFIER_LAYOUT_PATH "$HOME/dotfiles/.config/sesh/layouts"
    set -gx FZF_DEFAULT_OPTS "
        --color=fg:#c0caf5,bg:#1a1b26,hl:#bb9af7 
        --color=fg+:#c0caf5,bg+:#2f334d,hl+:#7dcfff 
        --color=info:#7aa2f7,prompt:#7dcfff,pointer:#7dcfff 
        --color=marker:#9ece6a,spinner:#9ece6a,header:#9ece6a
    "
end
