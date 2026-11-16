# Setup

How this machine is put together, roughly in the order it was built.

## 1. OS installation

EndeavourOS **Titan Nova** (latest release), installed from the live ISO with the graphical installer and its defaults — desktop, partitions, boot loader, dracut and the login manager all came from there.

The installer left the clock unsynced, so set the timezone and turn on NTP before anything else — a wrong clock breaks TLS and pacman signature checks:

```bash
sudo timedatectl set-timezone Asia/Manila   #only if you actually want PH time
sudo timedatectl set-ntp true
timedatectl                                 # expect "System clock synchronized: yes", "NTP service: active"
```

## 2. Packages from pacman

EndeavourOS supplied most of the list (KDE, firmware, filesystem tools, printers, etc.). The rest was installed by hand in a few batches:

```bash
# desktop / WM / terminal
sudo pacman -Syu niri xwayland-satellite xdg-desktop-portal-gnome \
  xdg-desktop-portal-gtk alacritty noctalia kitty nvim tmux opencode \
  steam zoxide eza fzf fd git fish btop yazi

# tools, fonts, media
sudo pacman -Syu nodejs npm ttf-jetbrains-mono easyeffects \
  kdenlive audacity mpv ffmpeg wl-clipboard telegram-desktop discord stow docker

# extras
sudo pacman -S base-devel pacman-contrib dbeaver mariadb go rust zig clang \
  lazygit github-cli keychain wl-clip-persist cava rnote zathura zathura-pdf-mupdf imv \
  haruna obs-studio jdk-openjdk firefox firefoxpwa uv godot libreoffice-still zed unzip \
```

Grouped, the things that matter:

| Category      | Packages                                                                                                                                                                                                            |
| ------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Shell / CLI   | `fish`, `eza`, `fzf`, `fd`, `zoxide`, `btop`, `yazi`, `tmux`, `keychain`, `stow`, `tldr`, `duf`, `glances`, `downgrade`, `pkgfile`, `plocate`, `wget`, `unzip`                                                      |
| Desktop       | `niri`, `noctalia`, `kitty`, `alacritty`, `xwayland-satellite`, `wl-clipboard`, `wl-clip-persist`, `xdg-desktop-portal-*`                                                                                           |
| Dev           | `neovim`, `zed`, `nodejs`/`npm`, `go`, `rust`, `zig`, `clang`, `docker`, `lazygit`, `github-cli`, `mariadb`, `dbeaver`, `jdk-openjdk`, `uv`, `godot`                                                                |
| Media / apps  | `obs-studio`, `kdenlive`, `audacity`, `easyeffects`, `haruna`, `mpv`, `zathura` (`zathura-pdf-mupdf`), `imv`, `libreoffice-still`, `rnote`, `steam`, `discord`, `telegram-desktop`, `firefox`, `firefoxpwa`, `cava` |
| Fonts         | `ttf-jetbrains-mono`, `noto-fonts` (+ `cjk`, `emoji`, `extra`)                                                                                                                                                      |

## 3. AUR via yay

`yay` came with EndeavourOS; these packages are the ones installed from the AUR:

| Package            | Why                                               |
| ------------------ | ------------------------------------------------- |
| `python-pywalfox`  | Pywalfox CLI, pairs with the Firefox extension    |
| `sesh-bin`         | session manager behind the `C-a C-a` tmux picker  |
| `claude-code`      | Claude Code CLI                                   |
| `antigravity-cli`  | Antigravity CLI                                   |
| `zoom`             | video calls                                       |
| `xdg-desktop-portal-termfilechooser` | Yazi terminal file picker portal backend for Niri |

```bash
yay -S python-pywalfox sesh-bin claude-code antigravity-cli zoom xdg-desktop-portal-termfilechooser
```

## 4. Apps installed without a package manager

| App        | Install                                              | Lands in                                                      |
| ---------- | ---------------------------------------------------- | ------------------------------------------------------------- |
| oh-my-posh | `curl -s https://ohmyposh.dev/install.sh \| bash -s` | `~/.local/bin/oh-my-posh`, theme in `.config/fish/theme.json` |
| herdr      | `curl -fsSL https://herdr.dev/install.sh \| sh`      | `~/.local/bin/herdr`, config in `~/.config/herdr/config.toml` |

Everything else — fisher, `nvm.fish`, the yazi plugin, the LazyVim config — is already committed in this repo and arrives with `stow .`; nvim downloads its pinned plugins on first launch.

## 5. Dotfiles (stow)

Repo root mirrors `$HOME`; every config is symlinked in (including `.config/niri-mimeapps.list` and `.config/kde-mimeapps.list` for desktop-specific file associations):

```bash
cd ~/dotfiles
stow .
stow --delete .   # undo
```

`.stow-local-ignore` keeps `.git`, `.gitignore`, `AGENTS.md`, `README.md` and `others/` out of `$HOME` — `others/` holds backgrounds and the Vimium C theme, which are copied by hand, not linked.

Scripts in `.local/bin/` need the executable bit before committing (`chmod +x .local/bin/<script>`) — stow only creates the symlink, so a `644` file is not runnable from `$HOME`.

## 6. Fish

Make it the login shell:

```bash
chsh -s /usr/bin/fish
```

Everything else — plugins, prompt, key bindings — comes from `.config/fish`, linked by stow.

## 7. tmux

Clone the plugin manager, then install the plugins from `.tmux.conf` (`C-a I`):

```bash
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
```

## 8. Godot

Installed from the repos (`godot`). Scripts open in Neovim via the wrapper in this repo, `.local/bin/godot-nvim`:

1. Editor → Editor Settings → **Text Editor → External**

2. ✅ Use External Editor, Exec Path `~/.local/bin/godot-nvim`, Exec Flags `{file} {line} {col}`

Every nvim instance listens on `$XDG_RUNTIME_DIR/nvim-<pid>.sock` and claims the current project (or cwd) in `$XDG_RUNTIME_DIR/nvim-projects/<sha256>` if no live instance already owns it (nvim `config/options.lua`). Opening extra nvims won't hijack it; run `:GodotPin` to switch ownership to the current instance. The wrapper walks up from the script to `project.godot`, finds that project's instance, and sends `:edit +<line> <file>` to it — or opens `kitty nvim` in the project root if none is live.

## 9. Firefox

Installed from the repos (`firefox` + `firefoxpwa`). Log in to your Firefox account to sync and sign in to extensions, accounts, bookmarks, settings, history, etc. as needed.

## 10. OpenCode

Installed from the repo. Two manual steps after that:

- Set up the secrets in `.config/opencode/` (`service.json` and any `.env*`) — those are gitignored.

- Install the **Graphify** skill: `uv tool install graphifyy && graphify install` (`sudo pacman -S uv` first if missing; `graphify install` detects the assistant and registers `/graphify`).

## 11. Git & GitHub

1. Create an SSH key and add it to `ssh-agent` by following [GitHub's SSH key generation guide](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent).

2. Authenticate `gh`: run `gh auth login` → select **SSH** → select `/home/{user}/.ssh/id_ed25519.pub` and press **Enter** when prompted for the SSH key → select **Paste an authentication token** → paste your auth token.

## 12. KDE Plasma Setup

Keep KDE Plasma installed alongside Niri as a fallback session (keep `plasma-integration`, `xdg-desktop-portal-kde` installed so Qt theming and Dolphin file associations work in both sessions). Log in using **KDE Plasma** first (not Niri) and configure the following manually in **System Settings**:

1. **Login Wallpaper:** Go to **Login Screen** → **Configure Appearance** and select a background image from `others/backgrounds/`.
2. **Global Theme:** Go to **Appearance & Style** → **Colors & Themes** (or **Global Theme**) and switch to **Breeze Dark**.
3. **Standard User:** Go to **Users** → **Add New User**, create a **Standard** account named `user` with the password `password`.
4. **Mouse Settings:** Go to **Input & Output** → **Mouse & Touchpad** → **Mouse**, set **Acceleration profile** to **Flat** (disables pointer precision), and set **Pointer speed** to `0.4`.

## 13. DaVinci Resolve

DaVinci Resolve **Studio 21** (cracked/patched license check), no package in the repos. Download the Linux `.zip` from [Blackmagic's support page](https://www.blackmagicdesign.com/support/family/davinci-resolve-and-fusion), then:

```bash
unzip DaVinci_Resolve_*_Linux.zip
chmod +x DaVinci_Resolve_*_Linux.run
sudo pacman -S opencl-mesa   # Resolve needs an OpenCL runtime
./DaVinci_Resolve_*_Linux.run
```

The installer unpacks everything into `/opt/resolve`. This repo provides a user launcher override (`.local/share/applications/com.blackmagicdesign.resolve.desktop`, pointing at `/opt/resolve/bin/resolve`) so Resolve appears correctly in the launcher (and avoids duplicate entries if the installer added one). Restow after changes: `stow .`.

Then patch `bin/resolve` to bypass the license check (based on [this guide](https://www.reddit.com/r/LinuxCrackSupport/comments/1vpucp8/davinci_resolve_studio_21xx_bypass_licence_guide/)):

```bash
cd /opt/resolve
sudo perl -pi -e 's/\x03\x00\x89\x45\xFC\x83\x7D\xFC\x00\x74\x11\x48\x8B\x45\xC8\x8B/\x03\x00\x89\x45\xFC\x83\x7D\xFC\x00\xEB\x11\x48\x8B\x45\xC8\x8B/g' bin/resolve

sudo perl -pi -e 's/\x74\x11\x48\x8B\x45\xC8\x8B\x55\xFC\x89\x50\x58\xB8\x00\x00\x00/\xEB\x11\x48\x8B\x45\xC8\x8B\x55\xFC\x89\x50\x58\xB8\x00\x00\x00/g' bin/resolve

sudo perl -0777 -pi -e 's/(\x40\x84\xED)\x74(.\xBF\x16\x00\x00\x00\xBE.\x01\x00\x00\xE8)/$1\x75$2/g' bin/resolve
```

Even if Studio supposedly supports a codec, other problems can still come up on Linux, so run `.local/bin/to_resolve` on videos and audio before importing to make sure they work reliably in DaVinci Resolve.

`.local/bin/to_resolve` re-encodes for Resolve. For videos (`*.mp4 *.mov *.mkv *.webm *.avi *.m4v *.ts *.flv`) it converts to ProRes 422 + PCM s16le in place, keeping the same filename/extension (skips files already ProRes+PCM when `ffprobe` is available). For audio (`*.mp3 *.aac *.m4a *.ogg *.opus *.flac *.wma`) it writes 24-bit PCM in place when the container supports it (`.wav`, `.aiff/.aif`), skipping files already PCM when `ffprobe` is available; otherwise it creates a same-base `.wav` file (e.g. `.m4a` → `.wav`). Some containers may not accept ProRes/PCM and will be left unchanged on failure; keep backups before running. With `-d`, the original audio file is deleted after a successful conversion when the output is a separate `.wav`.

Resolve needs a GPU it recognises. `sudo pacman -S opencl-mesa` is what makes the iGPU visible — it pulls `libclc` and `spirv-llvm-translator`, which rusticl needs to compile kernels. Without them the log says `No matched GPUs found` / `Unsupported GPU Processing Mode`; with them, `GPUDetect` logs `Detected 1 GPUs` + `Selected compute API: OpenCL`.

## 14. Rebuild order

1. EndeavourOS ISO → installer defaults, then timezone + NTP (§1).
2. `stow .` from this repo (links configs, `niri-mimeapps.list`, and `kde-mimeapps.list`).
3. pacman batches (§2), then `yay -S` (§3).
4. oh-my-posh + herdr scripts, `chsh -s /usr/bin/fish`.
5. Clone tpm and press `C-a I`; nvim installs LazyVim plugins on first launch.
6. Firefox login and sync/sign-in for extensions, bookmarks, settings, history, etc. (§9).
7. OpenCode: secrets + Graphify skill (§10).
8. Godot external editor (§8).
9. SSH key + `gh auth login` (§11).
10. KDE Plasma login wallpaper, Breeze Dark theme, standard `user` account, and mouse settings (§12).
11. DaVinci Resolve install + `opencl-mesa` (§13).
