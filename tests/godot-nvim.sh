#!/bin/bash

# godot-nvim round trip: open a file at a line in a registered headless nvim.
# usage: tests/godot-nvim.sh

set -u
repo=$(dirname -- "$(readlink -f -- "$0")")/..
work=$(mktemp -d "${TMPDIR:-/tmp}/godot-nvim-test.XXXXXX") || exit 1
sock="$work/gd.sock"
pid=
opid=
cpid=
trap 'test -n "$pid" && kill "$pid" 2>/dev/null; test -n "$opid" && kill "$opid" 2>/dev/null; test -n "$cpid" && kill "$cpid" 2>/dev/null; rm -rf -- "$work"' EXIT

if ! command -v nvim >/dev/null; then
  echo "skip: nvim not installed"
  exit 0
fi

source "$repo/tests/lib.sh"

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

"$repo/.local/bin/godot-nvim" "$root/main.gd" 42 7
check 0 "$?" 'external editor exits 0'
check "$root/main.gd" "$(nvim --headless --server "$sock" --remote-expr 'bufname("%")')" 'opens the exact path'
check 42 "$(nvim --headless --server "$sock" --remote-expr 'line(".")')" 'jumps to the given line'

# an nvim that owns a project map must register a live socket, then drop the map on exit
other="$work/other"
mkdir -p "$other"
: >"$other/project.godot"
(cd "$other" && exec nvim --headless --clean --cmd "luafile $repo/.config/nvim/lua/config/options.lua" >/dev/null 2>&1 & echo $! >"$work/other.pid")
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
(cd "$a" && exec nvim --headless --clean --cmd "luafile $repo/.config/nvim/lua/config/options.lua" >/dev/null 2>&1 & echo $! >"$work/cd.pid")
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

# a dead cwd must not break startup: vim.fs.root asserts when getcwd() is empty
dead="$work/dead"
mkdir -p "$dead"
err=$(bash -c "cd '$dead' && rmdir '$dead' && exec nvim --headless --clean --cmd 'luafile $repo/.config/nvim/lua/config/options.lua' -c 'qa!'" 2>&1)
check '' "$err" 'startup in a deleted cwd stays quiet'

[ "$fails" = 0 ] && echo "ok: godot-nvim"
exit "$fails"
