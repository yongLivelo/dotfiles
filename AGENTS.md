# AGENTS.md

## Deploy
- `stow .` from repo root to symlink everything into `$HOME`
- `.stow-global.ignore` skips `other/` (browser/Vimium C configs)

## tmux
- Prefix is `C-a` (not default `C-b`)
- Base index 1 for windows and panes

## Fish shell (`.config/fish/`)
- `vi` key bindings; `jk` escapes insert/visual mode
- `alias ls eza` — eza replaces ls
- `y` function opens yazi then cds into the exit dir
- Shell theme: `oh-my-posh` with `theme.json` (Noctalia palette)

## Neovim (`.config/nvim/` — AstroNvim v6)
- Leader is Space, localleader is comma
- Mason ensures: lua-language-server, stylua, prettierd, black, rust-analyzer, jdtls, pyright, debugpy, tree-sitter-cli
- Formatter configs: `.stylua.toml` (Lua), `selene.toml` (linter), `.luarc.json` (LSP)
- Formatters run on save via null-ls (stylua, black, prettierd, gdformat)
- Update plugins: `:Lazy update`

## Sesh (`.config/sesh/`)
- Tmuxifier layouts in `.config/sesh/layouts/`
- Connected sessions: `dotfiles`, `apis-api` (Java/Maven), `apis-cmssi` (Node.js)

## Noctalia theme
- Tokyo Night color palette used across kitty, niri, yazi, fish prompt, tmux, vimium-c
- niri theme override in `noctalia.kdl`
- yazi custom flavor in `yazi/flavors/`

## Styling conventions
- Lua: 120 cols, 2-space indent, double quotes, Unix LF (`.stylua.toml`)
- No CI, no pre-commit, no npm/Python project files at repo root
- Git remote is SSH-only (`git@github.com:yongLivelo/dotfiles.git`)
