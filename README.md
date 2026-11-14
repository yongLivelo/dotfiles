# Setup

How this machine is put together, roughly in the order it was built.

## 1. OS installation

EndeavourOS **Titan Nova** (latest release), installed from the live ISO with the graphical installer and its defaults — desktop, partitions, boot loader, dracut and the login manager all came from there.

## 2. Packages from pacman

EndeavourOS supplied most of the list (KDE, firmware, filesystem tools, printers, etc.). The rest was installed by hand in a few batches:

```bash
# desktop / WM / terminal
sudo pacman -Syu niri xwayland-satellite xdg-desktop-portal-gnome \
  xdg-desktop-portal-gtk alacritty noctalia kitty nvim tmux opencode \
  steam zoxide eza fzf fd git fish btop yazi

# tools, fonts, media
sudo pacman -Syu nodejs npm python-pywalfox ttf-jetbrains-mono easyeffects \
  kdenlive audacity mpv wl-clipboard telegram-desktop discord stow docker

# extras
sudo pacman -S base-devel pacman-contrib dbeaver mariadb go rust zig clang \
  lazygit github-cli keychain wl-clip-persist cava rnote zathura zathura-pdf-mupdf imv \
  haruna obs-studio jdk-openjdk firefox firefoxpwa uv godot libreoffice-still
```

Grouped, the things that matter:

| Category     | Packages                                                                                                                                                                                                            |
| ------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Shell / CLI  | `fish`, `eza`, `fzf`, `fd`, `zoxide`, `btop`, `yazi`, `tmux`, `keychain`, `stow`, `tldr`, `duf`, `glances`, `downgrade`, `pkgfile`, `plocate`, `wget`, `unzip`                                                      |
| Desktop      | `niri`, `noctalia`, `kitty`, `alacritty`, `xwayland-satellite`, `wl-clipboard`, `wl-clip-persist`, `plasma-login-manager`, `xdg-desktop-portal-*`                                                                   |
| Dev          | `neovim`, `nodejs`/`npm`, `go`, `rust`, `zig`, `clang`, `docker`, `lazygit`, `github-cli`, `mariadb`, `dbeaver`, `meld`, `jdk-openjdk`, `uv`, `godot`                                                               |
| Media / apps | `obs-studio`, `kdenlive`, `audacity`, `easyeffects`, `haruna`, `mpv`, `zathura` (`zathura-pdf-mupdf`), `imv`, `libreoffice-still`, `rnote`, `steam`, `discord`, `telegram-desktop`, `firefox`, `firefoxpwa`, `cava` |
| Fonts        | `ttf-jetbrains-mono`, `noto-fonts` (+ `cjk`, `emoji`, `extra`)                                                                                                                                                      |

## 3. AUR via yay

`yay` came with EndeavourOS; these packages are the ones installed from the AUR:

| Package           | Why                                              |
| ----------------- | ------------------------------------------------ |
| `python-pywalfox` | Pywalfox CLI, pairs with the Firefox extension   |
| `sesh-bin`        | session manager behind the `C-a C-a` tmux picker |
| `claude-code`     | Claude Code CLI                                  |
| `antigravity-cli` | Antigravity CLI                                  |
| `zoom`            | video calls                                      |

```bash
yay -S python-pywalfox sesh-bin claude-code antigravity-cli zoom
```

## 4. Apps installed without a package manager

| App        | Install                                              | Lands in                                                      |
| ---------- | ---------------------------------------------------- | ------------------------------------------------------------- |
| oh-my-posh | `curl -s https://ohmyposh.dev/install.sh \| bash -s` | `~/.local/bin/oh-my-posh`, theme in `.config/fish/theme.json` |
| herdr      | `curl -fsSL https://herdr.dev/install.sh \| sh`      | `~/.local/bin/herdr`, config in `~/.config/herdr/config.toml` |

Everything else — fisher, `nvm.fish`, the yazi plugin, the LazyVim config — is already committed in this repo and arrives with `stow .`; nvim downloads its pinned plugins on first launch.

## 5. Dotfiles (stow)

Repo root mirrors `$HOME`; every config is symlinked in:

```bash
cd ~/dotfiles
stow .
stow --delete .   # undo
```

`.stow-local-ignore` keeps `.git`, `.gitignore`, `AGENTS.md`, `README.md`, `.markdownlint.json` and `others/` out of `$HOME` — `others/` holds backgrounds and the Vimium C theme, which are copied by hand, not linked.

## 6. Fish

Make it the login shell:

```bash
chsh -s /usr/bin/fish
```

Everything else — plugins, prompt, key bindings — comes from `.config/fish`, linked by stow.

## 7. tmux

Clone the plugin manager, then install the plugins from `.tmux.conf` (`C-a I`):

```bash
git clone [https://github.com/tmux-plugins/tpm](https://github.com/tmux-plugins/tpm) ~/.tmux/plugins/tpm
```

## 8. Godot

Installed from the repos (`godot`). Scripts open in Neovim via the wrapper in this repo, `.local/bin/godot-nvim`:

1. Editor → Editor Settings → **Text Editor → External**
2. ✅ Use External Editor, Exec Path `~/.local/bin/godot-nvim`, Exec Flags `{file} {line} {col}`

Every nvim instance listens on `$XDG_RUNTIME_DIR/nvim-<pid>.sock` and claims the current project (or cwd) in `$XDG_RUNTIME_DIR/nvim-projects/<sha256>` if no live instance already owns it (nvim `config/options.lua`). Opening extra nvims won't hijack it; run `:GodotPin` to switch ownership to the current instance. The wrapper walks up from the script to `project.godot`, finds that project's instance, and sends `:edit +<line> <file>` to it — or opens `kitty nvim` in the project root if none is live.

## 9. Firefox

Installed from the repos (`firefox` + `firefoxpwa`), then set up by hand:

1. Extensions: **Vimium C**, **NordPass**, **Pywalfox**, **PWAs for Firefox**.
2. Vimium C → options → custom CSS: copy-paste `others/vimiumc-tokyonight-theme.css`.
3. Colors come from Noctalia: its native host (`~/.mozilla/native-messaging-hosts/pywalfox.json` → `/usr/bin/noctalia`) feeds the Pywalfox extension, so no daemon to run.
4. Web apps (via **PWAs for Firefox**): open [Photopea](https://www.photopea.com/) and install it as a PWA.

## 10. OpenCode

Installed from the repo. Two manual steps after that:

- Set up the secrets in `.config/opencode/` (`service.json` and any `.env*`) — those are gitignored.
- Install the **Graphify** skill: `uv tool install graphifyy && graphify install` (`sudo pacman -S uv` first if missing; `graphify install` detects the assistant and registers `/graphify`).

## 11. Git & GitHub

1. Create an SSH key and add it to `ssh-agent` by following [GitHub's SSH key generation guide](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent).
2. Authenticate `gh`: run `gh auth login` → select **SSH** → select `/home/{user}/.ssh/id_ed255192.pub` and press **Enter** when prompted for the SSH key → select **Paste an authentication token** → paste your auth token.

## 12. Rebuild order

1. EndeavourOS ISO → installer defaults.
2. `stow .` from this repo.
3. pacman batches (§2), then `yay -S` (§3).
4. oh-my-posh + herdr scripts, `chsh -s /usr/bin/fish`.
5. Clone tpm and press `C-a I`; nvim installs LazyVim plugins on first launch.
6. Firefox add-ons, Vimium C CSS, and Photopea PWA (§9).
7. OpenCode: secrets + Graphify skill (§10).
8. Godot external editor (§8).
9. SSH key + `gh auth login` (§11).
