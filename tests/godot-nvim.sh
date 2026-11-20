#!/bin/bash

# godot-nvim round trip: open a file at a line in a registered headless nvim.
# usage: tests/godot-nvim.sh

set -u
repo=$(dirname -- "$(readlink -f -- "$0")")/..
# --clean skips lazy.nvim, so load the plugin spec's config directly in tests
godot_setup=(--cmd "set rtp+=$repo/.config/nvim" --cmd "lua require('plugins.godot').config()")
work=$(mktemp -d "${TMPDIR:-/tmp}/godot-nvim-test.XXXXXX") || exit 1
sock="$work/rt/nvim-test.sock"
pid=
opid=
cpid=
ppid=
trap 'test -n "$pid" && kill "$pid" 2>/dev/null; test -n "$opid" && kill "$opid" 2>/dev/null; test -n "$cpid" && kill "$cpid" 2>/dev/null; test -n "$ppid" && kill "$ppid" 2>/dev/null; chmod -R u+rwX "$work" 2>/dev/null; rm -rf -- "$work"' EXIT

if ! command -v nvim >/dev/null; then
  echo "skip: nvim not installed"
  exit 0
fi

source "$repo/tests/lib.sh"

# the EXIT trap must stay quiet before the later nvim processes are started
self_copy=$(mktemp "$work/trapcheck.XXXXXX")
sed '/^trap .* EXIT$/a exit 0' "$0" >"$self_copy"
trap_err=$(bash "$self_copy" 2>&1)
check '' "$trap_err" 'early exit leaves the EXIT trap quiet'

# a spec with no repo must stay virtual or lazy.nvim rejects it at startup
spec=$(nvim --headless --clean --cmd "set rtp+=$repo/.config/nvim" --cmd "lua local s=require('plugins.godot'); print(s.virtual and type(s.config)=='function' and 'ok' or 'bad')" -c 'qa!' 2>&1)
check ok "$spec" 'godot plugin spec is valid for lazy.nvim'

mkdir -p "$work/rt"
export XDG_RUNTIME_DIR="$work/rt"
maps="$work/rt/nvim-projects-$(id -u)"
mkdir -p "$maps"
root="$work/Bob's back\\slash"
mkdir -p "$root"
: >"$root/project.godot"
printf 'extends Node\n%.0s' $(seq 1 60) >"$root/main.gd"

nvim --headless --clean --listen "$sock" >/dev/null 2>&1 &
pid=$!
for _ in $(seq 1 50); do
  nvim --headless --server "$sock" --remote-expr '1' >/dev/null 2>&1 && break
  sleep 0.1
done

hash=$(printf %s "$root" | sha256sum | cut -d' ' -f1)
printf '%s' "$sock" >"$maps/$hash"

"$repo/.local/bin/godot-nvim" "$root/main.gd" 42
check 0 "$?" 'external editor exits 0'
check "$root/main.gd" "$(nvim --headless --server "$sock" --remote-expr 'bufname("%")')" 'opens the exact path'
check 42 "$(nvim --headless --server "$sock" --remote-expr 'line(".")')" 'jumps to the given line'

# a line that is not a number must not reach the Vim expression
pwn="$work/pwned"
"$repo/.local/bin/godot-nvim" "$root/main.gd" "1 | call writefile(['x'], '$pwn')" >/dev/null 2>&1
check 2 "$?" 'non-numeric line exits 2'
check no "$(present "$pwn")" 'line argument cannot run vim code'

# a path containing a newline must open in the registered instance
nlroot="$work/newline dir"
mkdir -p "$nlroot"
: >"$nlroot/project.godot"
nlfile="$nlroot/a
b.gd"
printf 'one\ntwo\n' >"$nlfile"
printf '%s' "$sock" >"$maps/$(printf %s "$nlroot" | sha256sum | cut -d' ' -f1)"
"$repo/.local/bin/godot-nvim" "$nlfile" 2 >/dev/null 2>&1
check 0 "$?" 'newline path exits 0'
check "$nlfile" "$(nvim --headless --server "$sock" --remote-expr 'bufname("%")')" 'newline path opens exactly'
check 2 "$(nvim --headless --server "$sock" --remote-expr 'line(".")')" 'newline path jumps to the line'

# an nvim that owns a project map must register a live socket, then drop the map on exit
other="$work/other"
mkdir -p "$other"
: >"$other/project.godot"
(cd "$other" && exec nvim --headless --clean "${godot_setup[@]}" >/dev/null 2>&1 & echo $! >"$work/other.pid")
opid=$(cat "$work/other.pid")
hash=$(printf %s "$other" | sha256sum | cut -d' ' -f1)
omap="$maps/$hash"
registered=no
for _ in $(seq 1 50); do
  [ -f "$omap" ] && registered=yes && break
  sleep 0.1
done
check yes "$registered" 'running nvim registers the project socket'
sock_path=$(cat "$omap" 2>/dev/null)
check 1 "$(nvim --headless --server "$sock_path" --remote-expr '1' 2>/dev/null)" 'registered socket is live'
check 700 "$(stat -c %a "$work/rt/nvim-$opid.sock" 2>/dev/null)" 'registered socket is owner-only'
nvim --headless --server "$sock_path" --remote-send '<cmd>qa!<cr>' >/dev/null 2>&1
for _ in $(seq 1 50); do
  [ -e "$omap" ] || break
  sleep 0.1
done
check no "$(present "$omap")" 'project map removed on exit'

# :cd must move the registration: old map gone, same live socket under the new root
a="$work/proj-a"
b="$work/proj-b"
mkdir -p "$a" "$b"
: >"$a/project.godot"
: >"$b/project.godot"
(cd "$a" && exec nvim --headless --clean "${godot_setup[@]}" >/dev/null 2>&1 & echo $! >"$work/cd.pid")
cpid=$(cat "$work/cd.pid")
amap="$maps/$(printf %s "$a" | sha256sum | cut -d' ' -f1)"
bmap="$maps/$(printf %s "$b" | sha256sum | cut -d' ' -f1)"
for _ in $(seq 1 50); do
  [ -f "$amap" ] && break
  sleep 0.1
done
asock=$(cat "$amap" 2>/dev/null)
nvim --headless --server "$asock" --remote-expr "execute('cd ' . fnameescape('$b'))" >/dev/null 2>&1
for _ in $(seq 1 50); do
  [ -f "$bmap" ] && [ ! -e "$amap" ] && break
  sleep 0.1
done
check no "$(present "$amap")" 'old project map removed on :cd'
check "$asock" "$(cat "$bmap" 2>/dev/null)" ':cd registers the same socket'
check 1 "$(nvim --headless --server "$asock" --remote-expr '1' 2>/dev/null)" 'socket survives :cd'

# :GodotPin forces the map back when another instance or a crash lost it
rm -f "$bmap"
nvim --headless --server "$asock" --remote-expr 'execute("GodotPin")' >/dev/null 2>&1
check "$asock" "$(cat "$bmap" 2>/dev/null)" ':GodotPin re-registers the live socket'
nvim --headless --server "$asock" --remote-send '<cmd>qa!<cr>' >/dev/null 2>&1

# no registered instance: it must start the terminal editor in the project root
fallback="$work/fallback"
mkdir -p "$fallback/bin"
: >"$fallback/project.godot"
: >"$fallback/script.gd"
cat >"$fallback/bin/kitty" <<'EOF'
#!/bin/sh
printf '%s\n' "$PWD" >"$OUT/cwd"
printf '%s\n' "$@" >"$OUT/args"
EOF
chmod +x "$fallback/bin/kitty"
OUT="$fallback" PATH="$fallback/bin:$PATH" "$repo/.local/bin/godot-nvim" "$fallback/script.gd" 7
check "$fallback" "$(cat "$fallback/cwd" 2>/dev/null)" 'fallback opens in the project root'
check "nvim
+7
$fallback/script.gd" "$(cat "$fallback/args" 2>/dev/null)" 'fallback starts nvim at the line'

# a planted project map must not redirect Godot to a stranger's nvim
plant="$work/plant"
mkdir -p "$plant/rt" "$plant/other" "$plant/root" "$plant/bin"
: >"$plant/root/project.godot"
: >"$plant/root/s.gd"
nvim --headless --clean --listen "$plant/other/sock" >/dev/null 2>&1 & ppid=$!
for _ in $(seq 1 50); do
  nvim --headless --server "$plant/other/sock" --remote-expr '1' >/dev/null 2>&1 && break
  sleep 0.1
done
cat >"$plant/bin/kitty" <<EOF
#!/bin/sh
printf '%s\n' "\$@" >"$plant/args"
EOF
chmod +x "$plant/bin/kitty"
phash=$(printf %s "$plant/root" | sha256sum | cut -d' ' -f1)
ln -s "$plant/other" "$plant/rt/nvim-projects-$(id -u)"
printf '%s' "$plant/other/sock" >"$plant/other/$phash"
XDG_RUNTIME_DIR="$plant/rt" PATH="$plant/bin:$PATH" "$repo/.local/bin/godot-nvim" "$plant/root/s.gd" 1 >/dev/null 2>&1
check '' "$(nvim --headless --server "$plant/other/sock" --remote-expr 'bufname("%")' 2>/dev/null)" 'symlinked map dir cannot redirect the editor'
check yes "$(present "$plant/args")" 'symlinked map dir falls back to a fresh nvim'

# an owned map dir pointing outside the runtime dir is just as untrusted
rm -f "$plant/args"
rm -f "$plant/rt/nvim-projects-$(id -u)"
mkdir "$plant/rt/nvim-projects-$(id -u)"
printf '%s' "$plant/other/sock" >"$plant/rt/nvim-projects-$(id -u)/$phash"
XDG_RUNTIME_DIR="$plant/rt" PATH="$plant/bin:$PATH" "$repo/.local/bin/godot-nvim" "$plant/root/s.gd" 1 >/dev/null 2>&1
check '' "$(nvim --headless --server "$plant/other/sock" --remote-expr 'bufname("%")' 2>/dev/null)" 'foreign socket path cannot redirect the editor'
check yes "$(present "$plant/args")" 'foreign socket path falls back to a fresh nvim'
kill "$ppid" 2>/dev/null
ppid=

# a dead cwd must not break startup: vim.fs.root asserts when getcwd() is empty
dead="$work/dead"
mkdir -p "$dead"
err=$(
  (
    cd "$dead" && rmdir "$dead" && exec nvim --headless --clean "${godot_setup[@]}" -c 'qa!'
  ) 2>&1
)
check '' "$err" 'startup in a deleted cwd stays quiet'

# a hostile project-map path must warn, not throw a Lua traceback
hostile="$work/hostile"
mkdir -p "$hostile/rt"
printf x >"$hostile/rt/nvim-projects-$(id -u)"
err=$(XDG_RUNTIME_DIR="$hostile/rt" nvim --headless --clean \
  "${godot_setup[@]}" -c 'qa!' 2>&1)
check 0 "$?" 'hostile project dir does not break nvim startup'
case $err in *'stack traceback'*) echo "FAIL: hostile dir threw: $err"; fails=$((fails + 1)) ;; esac
case $err in *'Godot pinning disabled'*) ;; *) echo "FAIL: hostile dir warning missing: $err"; fails=$((fails + 1)) ;; esac

# a planted symlink must not be followed: chmod would hit an arbitrary directory
linkroot="$work/link"
mkdir -p "$linkroot/rt" "$linkroot/target"
chmod 755 "$linkroot/target"
ln -s "$linkroot/target" "$linkroot/rt/nvim-projects-$(id -u)"
err=$(XDG_RUNTIME_DIR="$linkroot/rt" nvim --headless --clean \
  "${godot_setup[@]}" -c 'qa!' 2>&1)
check 0 "$?" 'symlinked project dir does not break nvim startup'
check 755 "$(stat -c %a "$linkroot/target")" 'symlinked project dir is not chmodded'
case $err in *'Godot pinning disabled'*) ;; *) echo "FAIL: symlink warning missing: $err"; fails=$((fails + 1)) ;; esac

# a read-only runtime dir must warn instead of failing pinning silently
ro="$work/readonly"
mkdir -p "$ro/rt"
chmod 555 "$ro/rt"
err=$(XDG_RUNTIME_DIR="$ro/rt" nvim --headless --clean \
  "${godot_setup[@]}" -c 'qa!' 2>&1)
check 0 "$?" 'read-only runtime dir does not break nvim startup'
case $err in *'Godot pinning disabled'*) ;; *) echo "FAIL: read-only dir warning missing: $err"; fails=$((fails + 1)) ;; esac

# a directory at the map path must warn instead of failing pinning silently
blocked="$work/blocked-map"
mkdir -p "$blocked/rt/nvim-projects-$(id -u)" "$blocked/project"
: >"$blocked/project/project.godot"
blocked_hash=$(printf %s "$blocked/project" | sha256sum | cut -d' ' -f1)
mkdir "$blocked/rt/nvim-projects-$(id -u)/$blocked_hash"
err=$(cd "$blocked/project" && XDG_RUNTIME_DIR="$blocked/rt" nvim --headless --clean \
  "${godot_setup[@]}" -c 'qa!' 2>&1)
check 0 "$?" 'unwritable map path does not break nvim startup'
case $err in *'Godot pinning disabled'*) ;; *) echo "FAIL: unwritable map warning missing: $err"; fails=$((fails + 1)) ;; esac

[ "$fails" = 0 ] && echo "ok: godot-nvim"
exit "$fails"
