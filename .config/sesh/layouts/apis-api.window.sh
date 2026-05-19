window_root "~/Projects/apis-api/"
new_window "editor"
run_cmd "nvim -c 'lua require(\"resession\").load(vim.fn.getcwd(), { dir = \"dirsession\" })'"
new_window "commands"
run_cmd "posting"
split_h 50
run_cmd "./mvnw spring-boot:run"
select_window "editor"
