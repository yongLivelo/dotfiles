# dotfiles

Managed with GNU Stow. Repo root mirrors `$HOME`.

## Stow

```bash
stow .          # symlink everything into $HOME
stow --delete . # remove symlinks
```

`.stow-local-ignore` excludes `.git`, `.gitignore`, `AGENTS.md`, `README.md`, `.markdownlint.json`, and `others/` — anything there is **not** symlinked into `$HOME` (e.g. `others/` holds backgrounds and misc files, never stowed).

## Config layout

| Path                         | What                                                                                                                                                                                                                                                     |
| ---------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `.config/fish/`              | Fish shell (vi mode, `jk` to exit insert, oh-my-posh, zoxide, fzf, keychain)                                                                                                                                                                             |
| `.config/nvim/`              | Neovim (LazyVim); Lua formatted with stylua (`stylua.toml`)                                                                                                                                                                                              |
| `.config/kitty/`             | Kitty terminal (JetBrains Mono, noctalia theme)                                                                                                                                                                                                          |
| `.config/niri/`              | Niri WM (noctalia bar)                                                                                                                                                                                                                                   |
| `.config/noctalia/`          | Noctalia desktop shell (Tokyo-Night theme)                                                                                                                                                                                                               |
| `.config/yazi/`              | Yazi file manager with custom plugins/flavors; `keymap.toml` binds `u`/`U` to trash undo/redo                                                                                                                                                            |
| `.config/btop/`              | Btop system monitor                                                                                                                                                                                                                                      |
| `.config/sesh/`              | Sesh session manager config + window scripts                                                                                                                                                                                                             |
| `.config/opencode/`          | OpenCode config (see below)                                                                                                                                                                                                                              |
| `.config/zathura/`           | Zathura document viewer (Tokyo-Night theme, recolor mode)                                                                                                                                                                                                |
| `.config/imv/`               | imv image viewer (Tokyo-Night palette, vi binds)                                                                                                                                                                                                         |
| `.config/mpv/`               | mpv media player (Wayland, hardware decoding, JetBrains Mono OSD)                                                                                                                                                                                        |
| `.config/mimeapps.list`      | Default applications (imv for images, zathura for PDF, mpv for video)                                                                                                                                                                                    |
| `.local/bin/`                | Scripts: `godot-nvim` (Godot external editor), `to_resolve` (in-place re-encode to ProRes/PCM for Resolve), `trash-undo` / `trash-redo` (restore or re-trash the last deleted batch), `sesh-term` (sesh picker; `--popup` draws it via `fzf-tmux`) |
| `.local/share/applications/` | Launchers for apps installed outside pacman (`com.blackmagicdesign.resolve.desktop`, `nvim.desktop`)                                                                                                                                                     |
| `.markdownlint.json`         | markdownlint rules for nvim (`markdownlint-cli2` via Mason): MD013, MD060 off                                                                                                                                                                            |
| `.tmux.conf`                 | Tmux (tpm plugins)                                                                                                                                                                                                                                       |

## Notable non-defaults

- Tmux prefix is `C-a` (not `C-b`); press `C-a C-a` to open the sesh+fzf session picker
- Outside tmux, Ctrl-A in fish also opens the sesh picker
- Sesh sessions are defined in `.config/sesh/sesh.toml`; window layouts are fish scripts in `.config/sesh/scripts/*.fish`
- `n` aliases `nvim`; `y` opens yazi and auto-cds on exit
- `ls` aliases `eza`
- `imv` aliases `imv-dir` (opens directory so arrow keys cycle images)
- `cd` aliases `zoxide`
- `EDITOR` is `nvim`
- Noctalia applies Tokyo-Night themes to btop, kitty, niri, yazi, GTK, Qt, and more
- In yazi, `d` trashes (recoverable) and `D` deletes permanently; `u` restores the last deleted batch and `U` re-trashes it, so repeated `u` walks further back through the trash
- Resolve's free Linux build can't decode H.264/H.265/AAC, so `to_resolve` re-encodes media for Resolve (video to ProRes 422 + PCM in place; audio to PCM in place for `.wav/.aiff`, otherwise to a same-base `.wav`, with `-d` removing the original in that case) before importing; keep backups because originals may be replaced on success

## OpenCode config

- `.config/opencode/opencode.jsonc` is schema-only — no custom instructions, agents, or permission rules live here.
- `.config/opencode/.gitignore` intentionally keeps `node_modules/`, package manifests (`package.json`, lockfiles), `service.json`, and herdr-installed files out of git; only `opencode.jsonc`, `cli.json` and `themes/` are tracked.
- Neovim integrates with OpenCode via `nickjvandyke/opencode.nvim` (keymaps `<C-o>`, `<C-x>`, `go` and `goo`, defined in `.config/nvim/lua/plugins/myplugins.lua`).

## Tests

`tests/trash.sh` runs `trash-undo` / `trash-redo` against a throwaway trash (`XDG_DATA_HOME`/`XDG_STATE_HOME` under `$HOME/.cache`, since gio only trashes onto the home filesystem). It is not stowed (`^tests` in `.stow-local-ignore`).

## Docs

`README.md` is the rebuild-from-scratch guide (package lists, install steps); this file is the map for working on the repo. Whenever a change adds, renames, or removes a config, script, or keybind, update **both** files in the same commit.
