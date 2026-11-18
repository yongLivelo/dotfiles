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
  xdg-desktop-portal-gtk noctalia kitty nvim tmux opencode \
  steam zoxide eza fzf fd git fish btop yazi stow docker kwallet

# Development & tools
sudo pacman -S base-devel pacman-contrib github-cli lazygit keychain \
  nodejs npm go rust zig clang jdk-openjdk uv dbeaver mariadb zed unzip pgformatter \
  texlive cairo pango python-matplotlib tk

# Media, fonts & desktop apps
sudo pacman -S ttf-jetbrains-mono noto-fonts noto-fonts-cjk noto-fonts-emoji \
  mpv ffmpeg easyeffects kdenlive audacity obs-studio haruna cava rnote \
  imv zathura zathura-pdf-mupdf wl-clipboard wl-clip-persist \
  firefox firefoxpwa telegram-desktop discord libreoffice-still godot
```

### Docker

```bash
sudo systemctl enable --now docker
sudo usermod -aG docker $USER  # log out and back in to apply
```

### AUR (`yay`)

```bash
yay -S sesh-bin python-pywalfox claude-code antigravity-cli zoom xdg-desktop-portal-termfilechooser gdscript-formatter
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
cd ~/dotfiles
stow .           # symlink configs to $HOME
stow --delete .  # undo
```

`others/` (wallpapers, vimium theme) is tracked but not stowed; configs point at `~/dotfiles/others/` directly.

## 4. Shell & Terminal

### Fish
Set fish as login shell:
```bash
chsh -s /usr/bin/fish
```
Plugins (`fisher`, `nvm.fish`), prompt, and aliases are pre-configured in `.config/fish/`.

### Tmux
Install plugins (`C-a I` after cloning):
```bash
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
```

`extended-keys on` is set so modified keys (e.g. `Ctrl-Shift-C`) reach Neovim intact; in Neovim `Ctrl-C` (normal mode) quits and `Ctrl-Shift-C` saves and quits.

## 5. App Setup

### OpenCode
1. **Authentication:** Run `opencode auth login` (or import via `opencode auth import < backup.json`). Environment keys go in `~/.config/opencode/.env`.
2. **Service password:** Generated in `~/.config/opencode/service.json` on first run (or set via `opencode service set password <pass>`).
3. **MCPs:** Configured in `.config/opencode/opencode.jsonc`. Add tokens (e.g. `GITHUB_PERSONAL_ACCESS_TOKEN`) to `~/.config/opencode/.env`. Check with `opencode mcp list`.
4. **Graphify skill:** `uv tool install graphifyy && graphify install`.
5. **Theme:** built-in `tokyonight` in `cli.json`; Noctalia does not generate an OpenCode theme.

### Godot
In Editor → Editor Settings → **Text Editor → External**:
- Enable **Use External Editor**
- Exec Path: `~/.local/bin/godot-nvim`
- Exec Flags: `{file} {line}`

Instances register sockets per project; running `:GodotPin` locks focus to the current Neovim instance.

### VS Code
Run `.local/bin/vscode-task-gen [dir]` to create `.vscode/tasks.json` with a shell task; it prompts for the label, command, and working directory.

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

Before importing media, run `.local/bin/to_resolve [-d]` to transcode unsupported video/audio to ProRes 422 + PCM (`.mov` / `.wav`).

### Manim
Install system dependencies, then create and verify a project with `uv`:

```bash
sudo pacman -Syu base-devel cairo pango  # also in §2

uv init manimations
cd manimations
uv add manim
uv run manim checkhealth
```

## 6. Rebuild Checklist

1. Install OS defaults, timezone & NTP (§1).
2. Install packages via `pacman` and `yay` (§2).
3. Stow dotfiles: `cd ~/dotfiles && stow .` (§3).
4. Run standalone installers (oh-my-posh, herdr) & set `chsh -s /usr/bin/fish` (§2, §4).
5. Clone TPM and press `C-a I` in tmux (§4).
6. Log in to Firefox sync.
7. Configure OpenCode credentials & Graphify (§5).
8. Authenticate GitHub CLI (`gh auth login`).
9. Configure KDE Plasma settings (§5).
10. Install & patch DaVinci Resolve (§5).

## 7. Tests

Run `tests/trash.sh`, `tests/to_resolve.sh`, and `tests/godot-nvim.sh` from the repo root.
