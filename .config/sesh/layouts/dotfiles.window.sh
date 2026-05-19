window_root "~/dotfiles/"
new_window "editor"
run_cmd "nvim -c 'lua require(\"resession\").load(vim.fn.getcwd(), { dir = \"dirsession\" })'"
