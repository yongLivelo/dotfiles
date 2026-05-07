if status is-interactive
    oh-my-posh init fish --config ~/.config/fish/theme.json | source
    set -g fish_key_bindings fish_vi_key_bindings
    bind -M insert \cp up-or-search
    bind -M insert \cn down-or-search
    bind -M insert \cf forward-char
    fzf_key_bindings
    bind -M insert -m default jk backward-char force-repaint
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
    set -Ux FZF_DEFAULT_OPTS "
     --color=fg:#c0caf5,bg:#1a1b26,hl:#bb9af7 \
    --color=fg+:#c0caf5,bg+:#24283b,hl+:#7dcfff \
    --color=info:#7aa2f7,prompt:#7dcfff,pointer:#7dcfff \
    --color=marker:#9ece6a,spinner:#9ece6a,header:#9ece6a
    "
    alias ls eza
end
