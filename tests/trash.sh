#!/bin/bash

# trash-undo / trash-redo round trip in a throwaway trash.
# gio only trashes onto the home filesystem, so the work dir lives under $HOME.
# usage: tests/trash.sh

set -u
repo=$(dirname -- "$(readlink -f -- "$0")")/..
work=$(mktemp -d "$HOME/.cache/trash-test.XXXXXX") || exit 1
trap 'rm -rf -- "$work"' EXIT

export XDG_DATA_HOME="$work/data"
export XDG_STATE_HOME="$work/state"
trash="$XDG_DATA_HOME/Trash"
state="$XDG_STATE_HOME/trash-redo"
src="$work/src"
mkdir -p "$trash/files" "$trash/info" "$src"

fails=0
check() { # <expected> <actual> <what>
  [ "$1" = "$2" ] || {
    echo "FAIL: $3: got '$2', want '$1'"
    fails=$((fails + 1))
  }
}
present() { [ -e "$1" ] || [ -L "$1" ] && echo yes || echo no; }

# fake a delete: file into Trash/files, spec-encoded path into Trash/info
trash_one() { # <name> <encoded-path> <deletion-date>
  echo "$1" >"$src/$1"
  mv -- "$src/$1" "$trash/files/$1"
  printf '[Trash Info]\nPath=%s\nDeletionDate=%s\n' "$2" "$3" \
    >"$trash/info/$1.trashinfo"
}

new=2026-01-02T03:04:05
old=2026-01-01T00:00:00
trash_one 'a b.txt' "$src/a%20b.txt" "$new"
trash_one 'h#1.txt' "$src/h%231.txt" "$new"
trash_one '100%.txt' "$src/100%25.txt" "$new"
trash_one 'uni-ü.txt' "$src/uni-%C3%BC.txt" "$new"
trash_one 'old.txt' "$src/old.txt" "$old"

"$repo/.local/bin/trash-undo" >/dev/null
check yes "$(present "$src/a b.txt")" 'restore name with space'
check yes "$(present "$src/h#1.txt")" 'restore name with hash'
check yes "$(present "$src/100%.txt")" 'restore name with percent'
check yes "$(present "$src/uni-ü.txt")" 'restore unicode name'
check no "$(present "$src/old.txt")" 'older batch untouched'
check yes "$(present "$trash/info/old.txt.trashinfo")" 'older .trashinfo kept'
check 4 "$(wc -l <"$state"/batch.*)" 'batch remembers four paths'

"$repo/.local/bin/trash-undo" >/dev/null
check yes "$(present "$src/old.txt")" 'second undo walks back'

"$repo/.local/bin/trash-redo" >/dev/null
check no "$(present "$src/old.txt")" 'redo re-trashes last undo'
check yes "$(present "$trash/files/old.txt")" 'redo moved it to trash'

"$repo/.local/bin/trash-redo" >/dev/null
check no "$(present "$src/a b.txt")" 'redo re-trashes the four'
check yes "$(present "$trash/files/a b.txt")" 'redo file landed in trash'

# a stale batch must be pruned, not block the redo behind it
ln -s "$work/gone" "$src/link"
printf '%s\n' "$src/link" >"$state/batch.AAA"
printf '%s\n' "$work/missing" >"$state/batch.ZZZ"
touch -d '2020-01-01 00:00:01' "$state/batch.AAA"
touch -d '2020-01-01 00:00:02' "$state/batch.ZZZ"
out=$("$repo/.local/bin/trash-redo")
check no "$(present "$src/link")" 'dangling symlink re-trashed'
check no "$(present "$state/batch.ZZZ")" 'stale batch pruned'
check no "$(present "$state/batch.AAA")" 'symlink batch consumed'
case $out in *"trashed: $src/link"*) ;; *) echo "FAIL: redo output: $out"; fails=$((fails + 1)) ;; esac

# an already-existing destination file must be skipped and allow walking back to earlier batch
trash_one 'blocked.txt' "$src/blocked.txt" '2099-01-02T00:00:00'
trash_one 'earlier.txt' "$src/earlier.txt" '2099-01-01T00:00:00'
echo "pre-existing" >"$src/blocked.txt"
"$repo/.local/bin/trash-undo" >/dev/null
check yes "$(present "$src/earlier.txt")" 'undo walks back past skipped existing file'
check yes "$(present "$trash/info/blocked.txt.trashinfo")" 'blocked .trashinfo kept'

"$repo/.local/bin/trash-redo" >/dev/null
check no "$(present "$src/earlier.txt")" 'redo re-trashes earlier.txt'
check 'nothing to redo' "$("$repo/.local/bin/trash-redo" 2>&1)" 'empty state reports nothing to redo'

[ "$fails" = 0 ] && echo "ok: trash undo/redo"
exit "$fails"
