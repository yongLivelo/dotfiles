# Setup

Machine rebuild guide for EndeavourOS.

## 1. OS Installation

Install EndeavourOS (Titan Nova) with graphical defaults. Set timezone and sync clock:

```bash
sudo timedatectl set-timezone Asia/Manila
sudo timedatectl set-ntp true
timedatectl  # verify NTP service: active
```

## 2. Packages

### Official Repos (`pacman`)

```bash
# Desktop, terminal, shell & essentials
sudo pacman -Syu niri xwayland-satellite xdg-desktop-portal-gnome \
  xdg-desktop-portal-gtk noctalia kitty neovim tmux opencode \
  steam zoxide eza fzf fd git fish btop yazi stow docker kwallet bluez bluez-utils

# Development & tools
sudo pacman -S base-devel pacman-contrib github-cli lazygit keychain \
  nodejs npm go rust zig clang jdk-openjdk uv dbeaver mariadb zed unzip \
  texlive cairo pango python-matplotlib tk stylua

# Media, fonts & desktop apps
# ttf-jetbrains-mono-nerd supplies the Nerd Font icons used by the fish prompt
# and LazyVim; the plain package is what kitty's font family resolves to.
sudo pacman -S ttf-jetbrains-mono ttf-jetbrains-mono-nerd noto-fonts noto-fonts-cjk noto-fonts-emoji \
  mpv ffmpeg imagemagick easyeffects kdenlive audacity obs-studio haruna cava rnote \
  imv gwenview zathura zathura-pdf-mupdf wl-clipboard wl-clip-persist \
  firefox firefoxpwa telegram-desktop discord libreoffice-still godot
```

### Docker

```bash
sudo systemctl enable --now docker
sudo usermod -aG docker $USER  # log out and back in to apply
```

### Bluetooth

```bash
sudo systemctl enable --now bluetooth
```

### AUR (`yay`)

```bash
yay -S google-chrome sesh-bin python-pywalfox claude-code antigravity-cli zoom xdg-desktop-portal-termfilechooser
```

### Standalone Installers

```bash
# oh-my-posh (theme in ~/.config/fish/theme.json)
curl -s https://ohmyposh.dev/install.sh | bash -s

# herdr
curl -fsSL https://herdr.dev/install.sh | sh
```

## 3. Dotfiles (stow)

Repo root mirrors `$HOME`. Symlink all configs:

```bash
git clone git@github.com:yongLivelo/dotfiles.git ~/dotfiles
cd ~/dotfiles
stow --no-folding .           # symlink configs to $HOME
stow --no-folding --delete .  # undo
```

`--no-folding` links files, never a whole directory: without it, a fresh home gets `~/.local` as one symlink into the repo, and every program that writes there (Neovim plugins, the installers below) writes into git.

`others/` (wallpapers, vimium theme) is tracked but not stowed; configs point at `~/dotfiles/others/` directly.

## 4. Shell & Terminal

### Fish

Set fish as login shell:

```bash
chsh -s /usr/bin/fish
```

Plugins (`fisher`, `nvm.fish`) are vendored in `.config/fish/` so a fresh stow gives a working shell offline; `fisher update` writes through the symlink, so it edits tracked files (commit the result). The prompt and aliases are configured in `.config/fish/`.

### Tmux

Install plugins (`C-a I` after cloning):

```bash
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
```

`extended-keys on` is set so modified keys (e.g. `Ctrl-Shift-C`) reach Neovim intact; in Neovim `Ctrl-C` (normal mode) quits and `Ctrl-Shift-C` saves and quits.

## 5. App Setup

### OpenCode

1. Run `opencode auth login`.

### Godot

In Editor → Editor Settings → **Text Editor → External**:

- Enable **Use External Editor**
- Exec Path: `~/.local/bin/godot-nvim`
- Exec Flags: `{file} {line}`

Instances register sockets per project; running `:GodotPin` locks focus to the current Neovim instance until its next `:cd`.

### VS Code

Run `.local/bin/vscode-task-gen [dir]` to create `.vscode/tasks.json` with a shell task; it prompts for the label, command, and working directory.

### Canva (offline PWA)

Open [canva.com](https://www.canva.com/) in Chrome and install it as an app: menu → **Cast, save, and share → Install page as app** (or the install icon in the address bar). With Firefox, use the PWAsForFirefox extension, or `firefoxpwa runtime install` then `firefoxpwa site install https://www.canva.com/`.

Sign in, then mark designs for offline use: **Projects → Available offline → More → Make available offline** (also listed at `canva.com/offline-designs`). Offline editing works only for designs marked this way — you cannot create new ones — and needs Chrome, Edge, Safari, Firefox 152+, or the Canva desktop app (not private/incognito windows).

While offline, edits save locally and sync when you reconnect. Work offline for at most 14 days, keep ~2 GB free, avoid adding video/audio, and stay signed in until **All changes synced** (signing out removes offline designs).

### Git & GitHub

```bash
ssh-keygen -t ed25519 -C "<email>"  # skip if ~/.ssh/id_ed25519 exists
gh auth login  # SSH -> uploads ~/.ssh/id_ed25519.pub -> paste token
```

### KDE Plasma (Fallback Session)

Log into Plasma once to configure:

1. **Login screen:** Select wallpaper from `others/backgrounds/`.
2. **Theme:** Breeze Dark.
3. **User:** Create standard account `user` / `password`.
4. **Mouse:** Acceleration Profile: **Flat**, Speed: `0.4`.

### DaVinci Resolve Studio 21

Download Linux `.zip` from Blackmagic support, then install with OpenCL support:

```bash
unzip DaVinci_Resolve_*_Linux.zip
chmod +x DaVinci_Resolve_*_Linux.run
sudo pacman -S opencl-mesa
./DaVinci_Resolve_*_Linux.run
```

Apply license bypass patches:

```bash
cd /opt/resolve
sudo perl -pi -e 's/\x03\x00\x89\x45\xFC\x83\x7D\xFC\x00\x74\x11\x48\x8B\x45\xC8\x8B/\x03\x00\x89\x45\xFC\x83\x7D\xFC\x00\xEB\x11\x48\x8B\x45\xC8\x8B/g' bin/resolve
sudo perl -pi -e 's/\x74\x11\x48\x8B\x45\xC8\x8B\x55\xFC\x89\x50\x58\xB8\x00\x00\x00/\xEB\x11\x48\x8B\x45\xC8\x8B\x55\xFC\x89\x50\x58\xB8\x00\x00\x00/g' bin/resolve
sudo perl -0777 -pi -e 's/(\x40\x84\xED)\x74(.\xBF\x16\x00\x00\x00\xBE.\x01\x00\x00\xE8)/$1\x75$2/g' bin/resolve
```

Before importing media, run `.local/bin/to_resolve [-d]` to transcode unsupported video/audio to ProRes 422 + PCM (`.mov` / `.wav`). It works on the whole current folder; it refuses a filename argument.

### Manim

Install system dependencies, then create and verify a project with `uv`:

```bash
sudo pacman -Syu base-devel cairo pango  # also in §2

uv init manimations
cd manimations
uv add manim
uv run manim checkhealth
source .venv/bin/activate.fish
```

## 6. Rebuild Checklist

1. Install OS defaults, timezone & NTP (§1).
2. Install packages via `pacman` and `yay` (§2).
3. Stow dotfiles: `cd ~/dotfiles && stow --no-folding .` (§3).
4. Run standalone installers (oh-my-posh, herdr) & set `chsh -s /usr/bin/fish` (§2, §4).
5. Clone TPM and press `C-a I` in tmux (§4).
6. Log in to Firefox sync.
7. Configure OpenCode credentials (§5).
8. Authenticate GitHub CLI (`gh auth login`).
9. Configure KDE Plasma settings (§5).
10. Install Canva as an offline PWA (§5).
11. Install DaVinci Resolve (§5).

## 7. Tests

Run `tests/trash.sh`, `tests/to_resolve.sh`, `tests/godot-nvim.sh`, and `tests/vscode-task-gen.sh` from the repo root.
