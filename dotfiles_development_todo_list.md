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