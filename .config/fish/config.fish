set -gx EDITOR nvim
fish_add_path -g "$HOME/.local/bin/"

if type -q archlinux-java
    set -l jvm (archlinux-java get 2>/dev/null)
    if test -n "$jvm" -a -d "/usr/lib/jvm/$jvm"
        set -gx JAVA_HOME /usr/lib/jvm/$jvm
        fish_add_path -g $JAVA_HOME/bin
    end
end

if status is-interactive
    set -g fish_greeting
    if type -q oh-my-posh
        oh-my-posh init fish --config ~/.config/fish/theme.json | source
    end

    set -g fish_key_bindings fish_vi_key_bindings
    function fish_user_key_bindings
        fzf_key_bindings
        bind -M insert -m default jk backward-char force-repaint
        for mode in insert default visual
            bind -M $mode \cp up-or-search
            bind -M $mode \cn down-or-search
            bind -M $mode \cf forward-char
            bind -M $mode \ca sesh-term
            bind -M $mode \cy 'y; functions -q omp_repaint_prompt && omp_repaint_prompt; commandline -f force-repaint'
            bind -M $mode \cz 'cdi; functions -q omp_repaint_prompt && omp_repaint_prompt; commandline -f force-repaint'
        end
    end
    fish_config theme choose "Tomorrow Night Bright"

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
end
