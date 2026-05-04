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
end
