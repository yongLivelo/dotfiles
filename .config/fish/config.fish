if status is-interactive
    if type -q archlinux-java
        set -gx JAVA_HOME /usr/lib/jvm/(archlinux-java get)
        fish_add_path $JAVA_HOME/bin
    end
    set -gx EDITOR nvim

    set -g fish_greeting
    oh-my-posh init fish --config ~/.config/fish/theme.json | source

    set -g fish_key_bindings fish_vi_key_bindings
    fzf_key_bindings
    bind -M insert -m default jk backward-char force-repaint
    function fish_user_key_bindings
        for mode in insert default visual
            bind -M $mode \cp up-or-search
            bind -M $mode \cn down-or-search
            bind -M $mode \cf forward-char
            bind -M $mode \ca sesh-term
        end
    end
    fish_config theme choose "Tomorrow Night Bright"
    if test -d ~/.config/fish/secrets
        for secret_file in ~/.config/fish/secrets/*.fish
            source $secret_file
        end
    end
    fish_user_key_bindings

    alias n nvim
    alias ls eza
    alias imv imv-dir

    if type -q keychain
        env SHELL=(command -s fish) keychain --quiet --eval id_ed25519 | source
    end
    zoxide init --cmd cd fish | source
    function y
        set tmp (mktemp -t "yazi-cwd.XXXXXX")
        command yazi $argv --cwd-file="$tmp"
        if read -l cwd <"$tmp"; and [ "$cwd" != "$PWD" ]; and test -d "$cwd"
            builtin cd -- "$cwd"
        end
        rm -f -- "$tmp"
    end

    fish_add_path "$HOME/.local/bin/"
end
