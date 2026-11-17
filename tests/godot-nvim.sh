#!/bin/bash

# godot-nvim round trip: open a file at a line in a registered headless nvim.
# usage: tests/godot-nvim.sh

set -u
repo=$(dirname -- "$(readlink -f -- "$0")")/..
work=$(mktemp -d "${TMPDIR:-/tmp}/godot-nvim-test.XXXXXX") || exit 1
sock="$work/gd.sock"
pid=
trap 'test -n "$pid" && kill "$pid" 2>/dev/null; rm -rf -- "$work"' EXIT

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

# an nvim that owns a project map must drop it on exit, or Godot sees a dead socket
other="$work/other"
mkdir -p "$other"
: >"$other/project.godot"
(cd "$other" && nvim --headless --clean --cmd "luafile $repo/.config/nvim/lua/config/options.lua" -c 'qa!') >/dev/null 2>&1
check 0 "$?" 'options.lua exits cleanly'
hash=$(printf %s "$other" | sha256sum | cut -d' ' -f1)
check no "$(present "$work/rt/nvim-projects/$hash")" 'project map removed on exit'

[ "$fails" = 0 ] && echo "ok: godot-nvim"
exit "$fails"
