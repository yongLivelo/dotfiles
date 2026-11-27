# Development & Dotfiles TODO List

## 1. Yazi File Operations & Image Clipboard Plugin

> **Goal:** Create a unified file operation history plugin with global undo/redo support and external image paste functionality for Yazi file manager.

- [ ] **Unified Action Stack (Undo/Redo)**
  - [ ] Implement event history tracking for file creation, deletion, renaming, and pasting.
  - [ ] Add working `undo` and `redo` actions linked to Yazi keybindings.
  - [ ] Ensure state persistence across file operations within the session.

- [ ] **External Clipboard Image Support**
  - [ ] Detect image data from system clipboard (`wl-clipboard` on Wayland/Niri, `xclip` fallback).
  - [ ] Automatically generate default filename / prompt for target file name upon paste.
  - [ ] Save image directly to the active Yazi directory.

## 2. Pure-Neovim AI Harness & Markdown-as-Prompt Workflow

> **Goal:** Run the entire AI workflow inside Neovim without Tmux pane glue by combining (1) a shared `ai-harness/` Stow package for skills, commands, `ask_user` MCP, and OpenCode-style keybinds across `opencode`, `claude`, and `agy`, (2) a floating `snacks.win` prompt popup (`<leader>ap`) that saves directly to your `.md` prompt log on `<C-s>`, (3) Markdown-as-Prompt async execution (`obsidian.nvim` / scratch notes) with interactive `snacks.picker` clarification popups and a live Vim-navigable activity log, and (4) a single-window on-demand `snacks.terminal` TUI using disk-persisted sessions (`-c` / `--continue`).

- [ ] **Unified Harness Stow Package (`ai-harness/`)**
  - [ ] Create a single canonical directory in `~/dotfiles/ai-harness/` for shared **skills** (`ponytail`, `superpowers`, ADAPT review templates) and **slash commands**, symlinked via GNU Stow to `~/.config/opencode/`, `~/.claude/`, and `~/.config/agy/`.
  - [ ] Standardize input keybindings across `opencode`, `claude`, and `agy` (`Ctrl+e` to open prompt in `nvim`, `Ctrl+p` / `Ctrl+n` history and menu navigation, and Vi editing mode).

- [ ] **Interactive `ask_user` MCP & `snacks.picker` Question Popup**
  - [ ] Build a lightweight local MCP server (`~/dotfiles/ai-harness/mcp/ask_user_mcp.py`) exposing an `ask_user(question, options)` tool and register it across `opencode`, `claude`, and `agy` using `$HOME`-relative paths.
  - [ ] Bridge MCP calls back to the originating Neovim instance using `$NVIM` RPC (`nvim --server "$NVIM" --remote-expr`) so headless runs pause cleanly while waiting for user input.
  - [ ] Render incoming questions in a `snacks.picker` popup with selectable options, a `"Custom reply..."` fallback via `snacks.input`, and `<C-s>` confirmation (avoiding accidental `<CR>` submits).
  - [ ] Implement `:AIQuestion` (`<leader>aq`) to reopen/answer a pending question popup if dismissed while working in another buffer.

- [ ] **Floating Prompt Popup (`:AIPrompt` / `<leader>ap`)**
  - [ ] Open a floating `snacks.win` Markdown scratch buffer directly over active code with full Neovim bindings (`jk` escape, Vi motions, snippets), pre-filled with a `##` heading template and `@relative/path#Lstart-Lend` when invoked from a visual selection.
  - [ ] Map `<C-s>` (Normal and Insert modes) to atomically format the prompt as a `##` section, append it to the target `.md` prompt store (`obsidian.nvim` daily note or per-project `ai-prompts.md`), close the popup, and dispatch the async runner immediately.
  - [ ] Map `q` in Normal mode to cancel and close the popup in one keypress without saving.

- [ ] **Markdown-as-Prompt Async Runner & Live Activity Log Buffer**
  - [ ] Use the target `.md` prompt file (`obsidian.nvim` daily note / per-project `ai-prompts.md`) where each `## Heading` acts as a persistent prompt thread with full Vi editing and searchable history.
  - [ ] Implement `:AISend` (`<leader>as`): parse the current `##` heading section, attach optional visual selection (`@relative/path#Lstart-Lend`), dispatch asynchronously via `vim.system()` (`opencode run --format json -c`, `claude -p --output-format stream-json --verbose -c`, or `agy` headless CLI) with `NVIM` socket env, and append the final output cleanly under `### Response`.
  - [ ] Stream live tool calls, step counts, and task status (`working` / `done`) in real time into a dedicated Markdown scratch buffer toggled in a right-hand split via `:AILog` (`<leader>al`), so all agent logs stay directly navigable with standard Vim bindings (`j`/`k`, `/`, `gg`/`G`, `v`/`y`) without terminal-mode switching.
  - [ ] Implement `:AISendRef` (`<leader>av`) in Normal/Visual mode to append `@filepath#Lstart-Lend` directly into the active Markdown prompt section.

- [ ] **Single-Window On-Demand TUI (`snacks.terminal` — No Tmux Pane)**
  - [ ] Implement `:AIToggle` (`<leader>at`) to toggle a single floating `snacks.terminal` launched with `<active_harness> -c` in the current repo root for interactive multi-file refactors, `ponytail` / `superpowers` runs, or live tool-permission prompts.
  - [ ] Map `<C-q>` in terminal mode directly to hide the `snacks.terminal` window in one keypress—eliminating nested Tmux/Neovim focus traps and double-`q` exits.

- [ ] **Picker, Statusline & Which-Key Integrations**
  - [ ] **Harness Switcher (`:AISwitch` / `<leader>ah`):** Use `snacks.picker` to switch the active harness (`opencode`, `claude`, `agy`) on the fly and persist the choice for headless runs, `<leader>ap`, and `<leader>at`.
  - [ ] **Statusline Integration (Lualine):** Display active AI harness name, background job state (`idle` / `running`), and a pending-question badge when `ask_user` is waiting.
  - [ ] **Which-Key Mappings (`<leader>a`):** Group all AI commands under `<leader>a` (`<leader>ap` floating prompt popup, `<leader>as` send section, `<leader>av` send file/line ref, `<leader>al` toggle live log panel, `<leader>at` toggle terminal TUI, `<leader>aq` answer pending question, `<leader>ah` switch harness).

## 3. Comprehensive Ponytail Audit

> ⚠️ **Prerequisite:** Defer execution until access to a high-capacity frontier model (e.g., Claude Opus / Hydrogen) is available.

- [ ] Obtain required frontier model API access.
- [ ] Configure local audit scripts to feed codebase context to the model.
- [ ] Execute comprehensive `ponytail` audit and record findings/remediations.

## 4. Dotfiles Polish & Zero-Error Verification

> **Goal:** Audit, standardize, and test the entire dotfiles repository across Niri, KDE Plasma, Neovim, Tmux, Fish, and terminal utilities so every symlink, keybind, theme, and script works cleanly and portably with zero errors.

- [ ] **Symlink, Additional Configs, Packages & Documentation Hygiene**
  - [ ] Verify all GNU Stow packages deploy cleanly with zero conflicts or broken symlinks.
  - [ ] Validate additional configs (such as `peaclock` and `satty`) and additional downloads tracked in `README.md`.
  - [ ] Export declarative native (`pacman -Qqe`) and AUR (`pacman -Qqm`) package lists into `~/dotfiles/packages/` and pair them with an idempotent `bootstrap.sh` install/restow script.
  - [ ] Ensure `AGENTS.md` and `README.md` accurately reflect current directory structure, prefixes, and package dependencies.

- [ ] **Username & Path Portability**
  - [ ] Audit the entire repository (`grep -rn "/home/julio"`) and replace any hardcoded home paths in configs, `.desktop` files, MCP registrations, `obsidian.nvim` settings, and scripts with `$HOME`, `~`, or XDG variables (`$XDG_CONFIG_HOME`, `$XDG_DATA_HOME`) so everything works under any username.

- [ ] **Shell, Multiplexer & Editor Health**
  - [ ] Run `:checkhealth` in Neovim (LazyVim) and resolve all warnings, missing providers, or broken lazy plugin specs.
  - [ ] Verify Fish shell startup time, `keychain` SSH/GPG agent loading, `sesh` + `fzf` session switching (`C-a C-a`), and Vi keybindings.
  - [ ] Confirm consistent Tokyo Night theming and Nerd Font rendering across Kitty, Noctalia, Tmux, LazyVim, Yazi, Zathura, `imv`, `mpv`, `peaclock`, `satty`, Oh My Posh, and Vimium C.

- [ ] **Keybind Conflict, Git Hook & Script Validation (`dotfiles/.local/bin/*`)**
  - [ ] Audit global and app-level keybindings (Niri, Tmux `C-a`, Neovim, Fish, Yazi) for collisions or dead mappings.
  - [ ] Add a `.git/hooks/pre-commit` check (and setup helper) that runs `shellcheck` on `.local/bin/*`, validates Lua formatting (`stylua --check`), and blocks accidental commits of local tokens or machine-specific state files.
  - [ ] Audit all AI-written scripts in `dotfiles/.local/bin/*`: remove redundant or unused scripts, fix bugs/hardcoded paths, and verify executable permissions and clean `shellcheck` output.
  - [ ] Refactor `dotfiles/.local/bin/to_resolve` so it stream-copies video (`-c:v copy`) and converts only AAC audio tracks into DaVinci Resolve-compatible uncompressed PCM (`-c:a pcm_s16le` / `pcm_s24le` in a `.mov` container, skipping files that do not contain AAC audio), while preserving the existing CLI flow (`-d` flag to replace/delete the original file and live `ffmpeg` progress/status output in the terminal).

DELETE THIS AFTER YOU IMPLEMENT EVERYTHING, MAKE NO MISTAKES
