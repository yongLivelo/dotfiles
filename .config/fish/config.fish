if status is-interactive
    set -gx JAVA_HOME /usr/lib/jvm/java-17-openjdk
    fish_add_path $JAVA_HOME/bin
    set -Ux nvm_default_version latest
    set -gx ANDROID_HOME $HOME/Android/Sdk
    set -gx EDITOR nvim
    set -gx TMUXIFIER_LAYOUT_PATH "$HOME/.config/sesh/layouts"

    set -g fish_greeting
    set -gx FZF_DEFAULT_OPTS " \
        --color=bg:#1a1b26,bg+:#292e42,fg:#c0caf5,fg+:#c0caf5 \
        --color=hl:#2ac3de,hl+:#2ac3de,info:#545c7e,marker:#bb9af7 \
        --color=prompt:#7aa2f7,spinner:#2ac3de,pointer:#bb9af7 \
        --color=border:#3b4261,header:#9ece6a,gutter:#1a1b26 \
        --color=query:#c0caf5,scrollbar:#3b4261"
    oh-my-posh init fish --config ~/.config/fish/theme.json | source
    fish_config theme choose tomorrow-night-bright

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
    fish_user_key_bindings

    alias n nvim
    alias ls eza

    if type -q keychain
        if not ssh-add -l >/dev/null 2>&1
            keychain --stop all 2>/dev/null
        end
        SHELL=(which fish) keychain --quiet --eval id_ed25519 | source
    end
    zoxide init --cmd cd fish | source
    function y
        set tmp (mktemp -t "yazi-cwd.XXXXXX")
        command yazi $argv --cwd-file="$tmp"
        if read -z cwd <"$tmp"; and [ "$cwd" != "$PWD" ]; and test -d "$cwd"
            builtin cd -- "$cwd"
        end
        rm -f -- "$tmp"
    end

    fish_add_path "$HOME/.cargo/env.fish"
    fish_add_path "$HOME/.local/bin/"
    fish_add_path "$HOME/.tmux/plugins/tmuxifier/bin"
    fish_add_path $ANDROID_HOME/emulator $ANDROID_HOME/platform-tools
end
