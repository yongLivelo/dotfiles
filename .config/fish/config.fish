if status is-interactive
    set -l omp_config "$HOME/.config/fish/tokyonight.json"


    if command -v oh-my-posh >/dev/null

        if test -f "$omp_config"

            oh-my-posh init fish --config "$omp_config" | source

        else

            # Fallback to default if your custom json is missing

            oh-my-posh init fish | source

            echo "⚠️  Note: $omp_config not found, using default theme."

        end

    end


    set -g fish_color_command bb9af7

    set -g fish_color_param 7aa2f7

    set -g fish_color_quote e0af68

    set -g fish_color_error f7768e

    set -g fish_color_end ff9e64

    set -g fish_color_comment 565f89

    set -g fish_color_autosuggestion 565f89

    set -g fish_color_selection --background=283457

    set -g fish_color_search_match --background=283457

    # Make ls beautiful with icons and git status

    alias  ls='eza --icons --git --group-directories-first'


    # Use 'll' for a detailed list view (perfect for Java/React projects)

    alias  ll='eza --icons --git -lh --group-directories-first'


    # Make 'cat' use syntax highlighting

    alias  cat='bat --paging=never'

    # 3. SET GREETING

    set -g fish_greeting 

    set -g fish_key_bindings fish_vi_key_bindings

    function fish_user_key_bindings

        # Execute fzf bindings if available

        if command -v fzf >/dev/null

            fzf_key_bindings

        end

    bind \cR fzf_history_search

# Maps 'jk' to escape

    bind \cR fzf_history_search

    bind -M insert -m default jk backward-char force-repaint


    # Backspace in Normal Mode (using single quotes to wrap the command)

    bind -M default \x7f delete-char

    bind -M visual \x7f kill-selection

    # Accept autosuggestion with Ctrl+F in both modes

    bind -M insert \cf accept-autosuggestion

    bind -M default \cf accept-autosuggestion


    # Accept only the next word (like 'w' in Vim)

    bind -M insert \ce forward-word

    bind -M default \ce forward-word

    end

end 
