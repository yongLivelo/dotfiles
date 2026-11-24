# Development & Dotfiles TODO List

## 1. Yazi File Operations & Image Clipboard Plugin

> **Goal:** Create a unified file operation history plugin with global undo/redo support and external image paste functionality for Yazi file manager.

* [ ] **Unified Action Stack (Undo/Redo)**
  * [ ] Implement event history tracking for file creation, deletion, renaming, and pasting.
  * [ ] Add working `undo` and `redo` actions linked to Yazi keybindings.
  * [ ] Ensure state persistence across file operations within the session.

* [ ] **External Clipboard Image Support**
  * [ ] Detect image data from system clipboard (`xclip`, `wl-clipboard`, or `pngpaste`).
  * [ ] Automatically generate default filename / prompt for target file name upon paste.
  * [ ] Save image directly to the active Yazi directory.

## 2. Neovim + AI Harness Workflow (`sidekick.nvim` / Custom Plugin)

> **Goal:** Build a dedicated Neovim prompt buffer and workflow selector to interact seamlessly with AI tools (Agy, Claude Code, OpenCode).

* [ ] **Dedicated Prompt Buffer**
  * [ ] Create a dedicated floating or split scratch buffer for drafting queries/prompts.
  * [ ] Add keybindings to send prompt text + code selection context directly to the active AI harness.

* [ ] **Harness Dispatcher & Switcher**
  * [ ] Build a picker/selector to switch seamlessly between harnesses:
    * [ ] `claude code`
    * [ ] `agy`
    * [ ] `opencode`

* [ ] **Plugin Commands, Skills & Tool Autocomplete**
  * [ ] Integrate harness slash commands, plugins, and custom skills into Neovim completion (`nvim-cmp` / `blink.cmp`).
  * [ ] Add dynamic completion for harness tool invocations (e.g. `@file`, `/cmd`, or skill triggers) inside the Neovim prompt buffer.
  * [ ] Expose available harness commands directly via Neovim command-line completion and keybindings.

* [ ] **Terminal / Output Navigation**
  * [ ] Bind custom Neovim keybindings to scroll and inspect the active harness output buffer without changing window focus.

* [ ] **Plugin Integrations**
  * [ ] **Picker Integration (Telescope / Snacks / FZF-Lua):** Dynamic UI for switching AI harnesses and selecting prompt templates.
  * [ ] **Statusline Integration (Lualine / Heirline):** Display active AI harness name, status (idle/running), and selected model.
  * [ ] **Which-Key Mappings:** Group all AI commands under a dedicated prefix key (e.g., `<leader>a`).

* [ ] **User Commands (`:AI...`)**
  * [ ] `:AISend` – Send visual selection or active prompt buffer to the running harness.
  * [ ] `:AISwitch` – Open interactive picker to change active AI harness on the fly.
  * [ ] `:AIToggle` – Quick toggle open/close of the dedicated prompt window and terminal pane.
  * [ ] `:AIInline` – Request inline code edits or explanations directly at cursor position.

## 3. Comprehensive Ponytail Audit

> ⚠️ **Prerequisite:** Defer execution until access to a high-capacity frontier model (e.g., Claude Opus / Hydrogen) is available.

* [ ] Obtain required frontier model API access.
* [ ] Configure local audit scripts to feed codebase context to the model.
* [ ] Execute comprehensive ponytail-audit and record findings/remediations.

## 4. Dotfiles Polish & Zero-Error Verification

> **Goal:** Audit, standardize, and test the entire dotfiles repository across Niri, KDE Plasma, Neovim, Tmux, Fish, and terminal utilities so every symlink, keybind, theme, and script works cleanly with zero errors.

* [ ] **Symlink & Stow Hygiene**
  * [ ] Verify all GNU Stow packages deploy cleanly with zero conflicts or broken symlinks.
  * [ ] Ensure `AGENTS.md` and `README.md` accurately reflect current directory structure, prefixes, and package dependencies.

* [ ] **Environment & Dual-DE Isolation (Niri vs. KDE Plasma)**
  * [ ] Audit `mimeapps.list` and environment variables so Niri (`zathura`, `imv`, `mpv`, `kitty` + `nvim`) and KDE Plasma (`okular`, `gwenview`, `haruna`, `Zed`) never override each other.
  * [ ] Verify XDG autostart, portal services (`xdg-desktop-portal`), and Wayland/XWayland fallbacks (`xwayland-satellite`) launch without errors.

* [ ] **Shell, Multiplexer & Editor Health**
  * [ ] Run `:checkhealth` in Neovim (LazyVim) and resolve all warnings, missing providers, or broken lazy plugin specs.
  * [ ] Verify Fish shell startup time, `keychain` SSH/GPG agent loading, `sesh` + `fzf` session switching (`C-a C-a`), and Vi keybindings.
  * [ ] Confirm consistent Tokyo Night theming and Nerd Font rendering across Kitty, Noctalia, Tmux, LazyVim, Yazi, Zathura, `imv`, `mpv`, Oh My Posh, and Vimium C.

* [ ] **Keybind Conflict & Script Validation**
  * [ ] Audit global and app-level keybindings (Niri, Tmux `C-a`, Neovim, Fish, Yazi) for collisions or dead mappings.
  * [ ] Lint and test all custom shell/FFmpeg scripts with `shellcheck` and ensure clean exit codes on edge cases.
  * [ ] Test a fresh bootstrap/stow dry-run to guarantee reproducible setup on a clean system.