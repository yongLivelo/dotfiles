window_root "~/Projects/apis-cmssi/"
new_window "editor"
run_cmd "nvim -c 'lua require(\"resession\").load(vim.fn.getcwd(), { dir = \"dirsession\" })'"
new_window "commands"
run_cmd "npm run dev"
split_h 50
