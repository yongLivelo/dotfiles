window_root "~/Projects/apis-cmssi/"
new_window "editor"
run_cmd "nvim -c 'lua require(\"resession\").load(vim.fn.getcwd(), { dir = \"dirsession\" })'"
split_h 40
run_cmd "opencode"
new_window "commands"
run_cmd "npm run dev"
split_h 50
select_window "editor"
