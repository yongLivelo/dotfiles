# dotfiles

Managed with GNU Stow. Repo root mirrors `$HOME`.

## Stow

```bash
stow --no-folding .           # symlink everything into $HOME, file by file
stow --no-folding --delete .  # remove symlinks
```

`--no-folding` matters: without it, a fresh home with no `~/.local` gets that whole directory as one symlink into the repo, and program state (Neovim plugins, installers) then lands in git.

`.stow-local-ignore` excludes `.git`, `.gitignore`, `AGENTS.md`, `README.md`, `others/` and `tests/` — anything there is **not** symlinked into `$HOME` (e.g. `others/` holds backgrounds and misc files, never stowed).

## Config layout

| Path                                          | What                                                                                                                                                                                                                                      |
| --------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `.config/fish/`                               | Fish shell (vi mode, `jk` to exit insert, oh-my-posh, zoxide, fzf, keychain)                                                                                                                                                              |
| `.config/nvim/`                               | Neovim (LazyVim); Lua formatted with stylua (`stylua.toml`)                                                                                                                                                                               |
| `.config/kitty/`                              | Kitty terminal (JetBrains Mono, noctalia theme)                                                                                                                                                                                           |
| `.config/niri/`                               | Niri WM (noctalia bar)                                                                                                                                                                                                                    |
| `.config/noctalia/`                           | Noctalia desktop shell (Tokyo-Night theme)                                                                                                                                                                                                |
| `.config/yazi/`                               | Yazi file manager with custom plugins/flavors; `keymap.toml` binds `u`/`U` to trash undo/redo                                                                                                                                             |
| `.config/btop/`                               | Btop system monitor                                                                                                                                                                                                                       |
| `.config/sesh/`                               | Sesh session manager config + window scripts                                                                                                                                                                                              |
| `.config/opencode/`                           | OpenCode config (see below)                                                                                                                                                                                                               |
| `.config/zathura/`                            | Zathura document viewer (Tokyo-Night theme)                                                                                                                                                                                               |
| `.config/imv/`                                | imv image viewer (Tokyo-Night palette, vi binds)                                                                                                                                                                                          |
| `.config/mpv/`                                | mpv media player (Wayland, hardware decoding, JetBrains Mono OSD)                                                                                                                                                                         |
| `.config/environment.d/`                      | User session environment variables (`fzf.conf` sets Tokyo-Night `FZF_DEFAULT_OPTS` for portals/GUI-launched apps)                                                                                                                         |
| `.config/xdg-desktop-portal/`                 | Portal backend preferences (`niri-portals.conf` routes `FileChooser` to `termfilechooser`)                                                                                                                                                |
| `.config/xdg-desktop-portal-termfilechooser/` | Terminal file chooser config (`config` setting Kitty as terminal for Yazi)                                                                                                                                                                |
| `.config/*-mimeapps.list`                     | Default applications (`niri-mimeapps.list`: imv for images, zathura for PDF, mpv for video; `kde-mimeapps.list`: Gwenview for images, zathura for PDF, Haruna for video)                                                                                                                       |
| `.local/bin/`                                 | Scripts: `godot-nvim` (Godot external editor), `to_resolve` (re-encode to ProRes/PCM for Resolve), `trash-undo` / `trash-redo` (restore or re-trash the last deleted batch), `sesh-term` (sesh picker; `--popup` draws it via `fzf-tmux`), `vscode-task-gen` (generates `.vscode/tasks.json`) |
| `.local/share/applications/`                  | Launchers for apps installed outside pacman (`com.blackmagicdesign.resolve.desktop`, `nvim.desktop`)                                                                                                                                      |
| `.tmux.conf`                                  | Tmux (tpm plugins)                                                                                                                                                                                                                        |

## Notable non-defaults

- Tmux prefix is `C-a` (not `C-b`); press `C-a C-a` to open the sesh+fzf session picker
- Outside tmux, Ctrl-A in fish also opens the sesh picker
- Sesh sessions are defined in `.config/sesh/sesh.toml`; window layouts are fish scripts in `.config/sesh/scripts/*.fish`
- `n` aliases `nvim`; `y` opens yazi and auto-cds on exit
- `ls` aliases `eza`
- `imv` aliases `imv-dir` (opens directory so arrow keys cycle images)
- `cd` aliases `zoxide`
- `EDITOR` is `nvim`
- In Neovim, `Ctrl-C` in normal mode quits and `Ctrl-Shift-C` in normal, insert or visual mode saves and quits (`<cmd>wqa<cr>`); Kitty unbinds its `kitty_mod+c` copy shortcut and tmux sets `extended-keys on` so the shift modifier survives
- In Neovim, `snacks.image` is enabled for inline image previews in markdown/buffers via Kitty graphics
- Noctalia applies Tokyo-Night themes to btop, kitty, niri, yazi, GTK, Qt, and more (wallpaper path in `.config/noctalia/noctalia-config.toml` points to `others/backgrounds/`)
- In yazi, `d` trashes (recoverable) and `D` deletes permanently; `u` restores the last deleted batch and `U` re-trashes it, so repeated `u` walks further back through the trash
- `fisher` and `nvm.fish` are vendored in `.config/fish/` (`fish_plugins` lists them) so a fresh stow gives a working shell offline; `fisher update` rewrites those tracked files — shortcut: the vendored copies go stale, delete them and let `fisher update` install on rebuild if that becomes a problem
- Resolve's free Linux build can't decode H.264/H.265/AAC, so `to_resolve` re-encodes media for Resolve (video to ProRes 422 + PCM in place for `.mov/.qt/.mkv`, otherwise to a same-base `.mov`; audio to PCM in place for `.wav/.aiff`, otherwise to a same-base `.wav`, with `-d` removing the original in that case) before importing; keep backups because originals may be replaced on success

## OpenCode config

- `.config/opencode/opencode.jsonc` configures the default model, plugins (superpowers, ponytail), and MCP servers (e.g. GitHub, Postgres) — no custom instructions, agents, or permission rules live here.
- `.config/opencode/.gitignore` intentionally keeps `node_modules/`, package manifests (`package.json`, lockfiles), `service.json`, and herdr-installed files out of git; `opencode.jsonc`, `cli.json`, `commands/`, `skills/` and the `.gitignore` itself are tracked.
- `.config/opencode/skills/` holds local skills, one `<name>/SKILL.md` each (e.g. `socratic-tutor`), loaded on demand when their description matches the task.
- The theme is the built-in `tokyonight` from `cli.json`; `opencode` is not in Noctalia's `theme.templates.community_ids`, so no theme file is generated here.
- Neovim integrates with OpenCode via `nickjvandyke/opencode.nvim` (keymaps `<C-o>`, `<C-x>`, `go` and `goo`, defined in `.config/nvim/lua/plugins/myplugins.lua`).

## Tests

`tests/trash.sh` runs `trash-undo` / `trash-redo` against a throwaway trash (`XDG_DATA_HOME`/`XDG_STATE_HOME` under `$HOME/.cache`, since gio only trashes onto the home filesystem) and checks that an unwritable restore is reported instead of silently dropped. `tests/to_resolve.sh` generates a one-second clip and checks the conversion (including in-place `.mov`/`.mkv` re-encodes), the skip path, `-d`, and the failure exit code. `tests/godot-nvim.sh` checks the external editor against a headless nvim, including a path with a quote and a backslash, and that `:cd` moves the socket registration. `tests/vscode-task-gen.sh` checks the generated `tasks.json` (typed/blank cwd, empty command, overwrite decline) and that a failing writer leaves an existing file untouched. `tests/lib.sh` holds the shared `check`/`present` helpers the four tests source. None are stowed (`^tests` in `.stow-local-ignore`).

## Docs

`README.md` is the rebuild-from-scratch guide (package lists, install steps); this file is the map for working on the repo. Whenever a change adds, renames, or removes a config, script, or keybind, update **both** files in the same commit.
