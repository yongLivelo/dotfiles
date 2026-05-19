window_root "~/dotfiles/"
new_window "editor"
run_cmd "nvim -c 'lua require(\"resession\").load(vim.fn.getcwd(), { dir = \"dirsession\" })'"
split_h 40
run_cmd "opencode"
select_window "editor"
