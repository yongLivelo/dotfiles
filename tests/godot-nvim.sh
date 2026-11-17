#!/bin/bash

# godot-nvim round trip: open a file at a line in a registered headless nvim.
# usage: tests/godot-nvim.sh

set -u
repo=$(dirname -- "$(readlink -f -- "$0")")/..
work=$(mktemp -d "${TMPDIR:-/tmp}/godot-nvim-test.XXXXXX") || exit 1
sock="$work/gd.sock"
pid=
opid=
trap 'test -n "$pid" && kill "$pid" 2>/dev/null; test -n "$opid" && kill "$opid" 2>/dev/null; rm -rf -- "$work"' EXIT

if ! command -v nvim >/dev/null; then
  echo "skip: nvim not installed"
  exit 0
fi

fails=0
check() { # <expected> <actual> <what>
  [ "$1" = "$2" ] || {
    echo "FAIL: $3: got '$2', want '$1'"
    fails=$((fails + 1))
  }
}
present() { [ -e "$1" ] || [ -L "$1" ] && echo yes || echo no; }

mkdir -p "$work/rt/nvim-projects"
export XDG_RUNTIME_DIR="$work/rt"
root="$work/Bob's back\\slash"
mkdir -p "$root"
: >"$root/project.godot"
printf 'extends Node\n%.0s' $(seq 1 60) >"$root/main.gd"

nvim --headless --clean --listen "$sock" >/dev/null 2>&1 &
pid=$!
for _ in $(seq 1 50); do
  nvim --server "$sock" --remote-expr '1' >/dev/null 2>&1 && break
  sleep 0.1
done

hash=$(printf %s "$root" | sha256sum | cut -d' ' -f1)
printf '%s' "$sock" >"$work/rt/nvim-projects/$hash"

"$repo/.local/bin/godot-nvim" "$root/main.gd" 42 7
check 0 "$?" 'external editor exits 0'
check "$root/main.gd" "$(nvim --server "$sock" --remote-expr 'bufname("%")')" 'opens the exact path'
check 42 "$(nvim --server "$sock" --remote-expr 'line(".")')" 'jumps to the given line'

# an nvim that owns a project map must register a live socket, then drop the map on exit
other="$work/other"
mkdir -p "$other"
: >"$other/project.godot"
(cd "$other" && nvim --headless --clean --cmd "luafile $repo/.config/nvim/lua/config/options.lua" >/dev/null 2>&1 & echo $! >"$work/other.pid")
opid=$(cat "$work/other.pid")
hash=$(printf %s "$other" | sha256sum | cut -d' ' -f1)
omap="$work/rt/nvim-projects/$hash"
registered=no
for _ in $(seq 1 50); do
  [ -f "$omap" ] && registered=yes && break
  sleep 0.1
done
check yes "$registered" 'running nvim registers the project socket'
sock_path=$(cat "$omap" 2>/dev/null)
check 1 "$(nvim --server "$sock_path" --remote-expr '1' 2>/dev/null)" 'registered socket is live'
nvim --server "$sock_path" --remote-send '<cmd>qa!<cr>' >/dev/null 2>&1
for _ in $(seq 1 50); do
  [ -e "$omap" ] || break
  sleep 0.1
done
check no "$(present "$omap")" 'project map removed on exit'

# a dead cwd must not break startup: vim.fs.root asserts when getcwd() is empty
dead="$work/dead"
mkdir -p "$dead"
err=$(bash -c "cd '$dead' && rmdir '$dead' && exec nvim --headless --clean --cmd 'luafile $repo/.config/nvim/lua/config/options.lua' -c 'qa!'" 2>&1)
check '' "$err" 'startup in a deleted cwd stays quiet'

[ "$fails" = 0 ] && echo "ok: godot-nvim"
exit "$fails"
