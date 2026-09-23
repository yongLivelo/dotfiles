# dotfiles

Managed with GNU Stow. Repo root mirrors `$HOME`.

## Stow

```bash
stow .          # symlink everything into $HOME
stow --delete . # remove symlinks
```

`.stow-local-ignore` excludes `.git`, `AGENTS.md`, and `others/` — anything there is **not** symlinked into `$HOME` (e.g. `others/` holds backgrounds and misc files, never stowed).

## Config layout

| Path | What |
|---|---|
| `.config/fish/` | Fish shell (vi mode, `jk` to exit insert, oh-my-posh, zoxide, fzf, keychain) |
| `.config/nvim/` | Neovim (LazyVim); Lua formatted with stylua (`stylua.toml`) |
| `.config/kitty/` | Kitty terminal (JetBrains Mono, noctalia theme) |
| `.config/niri/` | Niri WM (noctalia bar) |
| `.config/noctalia/` | Noctalia desktop shell (Tokyo-Night theme) |
| `.config/yazi/` | Yazi file manager with custom plugins/flavors |
| `.config/btop/` | Btop system monitor |
| `.config/sesh/` | Sesh session manager config + tmuxifier layouts |
| `.config/opencode/` | OpenCode config (see below) |
| `.tmux.conf` | Tmux (tpm plugins) |

## Notable non-defaults

- Tmux prefix is `C-a` (not `C-b`); press `C-a C-a` to open the sesh+fzf session picker
- Outside tmux, Ctrl-A in fish also opens the sesh picker
- Sesh sessions are defined in `.config/sesh/sesh.toml`; window layouts are tmuxifier shell scripts in `.config/sesh/layouts/*.window.sh` (`TMUXIFIER_LAYOUT_PATH` points there)
- `n` aliases `nvim`; `y` opens yazi and auto-cds on exit
- `ls` aliases `eza`
- `cd` aliases `zoxide`
- `EDITOR` is `nvim`
- Noctalia applies Tokyo-Night themes to btop, kitty, niri, yazi, GTK, Qt, and more

## OpenCode config

- `.config/opencode/opencode.jsonc` is schema-only — no custom instructions, agents, or permission rules live here.
- `.config/opencode/.gitignore` intentionally keeps `node_modules/` and package manifests (`package.json`, lockfiles) out of git; only `opencode.jsonc` and `themes/` are tracked.
- Neovim integrates with OpenCode via `nickjvandyke/opencode.nvim` (keymaps under `<leader>o`, defined in `.config/nvim/lua/plugins/opencode-integration.lua`).
