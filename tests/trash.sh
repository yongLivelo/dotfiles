#!/bin/bash

# trash-undo / trash-redo round trip in a throwaway trash.
# gio only trashes onto the home filesystem, so the work dir lives under $HOME.
# usage: tests/trash.sh

set -u
repo=$(dirname -- "$(readlink -f -- "$0")")/..
work=$(mktemp -d "$HOME/.cache/trash-test.XXXXXX") || exit 1
trap 'chmod -R u+rwX -- "$work" 2>/dev/null; rm -rf -- "$work"' EXIT

export XDG_DATA_HOME="$work/data"
export XDG_STATE_HOME="$work/state"
trash="$XDG_DATA_HOME/Trash"
state="$XDG_STATE_HOME/trash-redo"
src="$work/src"
mkdir -p "$trash/files" "$trash/info" "$src"

source "$repo/tests/lib.sh"

# fake a delete: file into Trash/files, spec-encoded path into Trash/info
trash_one() { # <name> <encoded-path> <deletion-date>
  echo "$1" >"$src/$1"
  mv -- "$src/$1" "$trash/files/$1"
  printf '[Trash Info]\nPath=%s\nDeletionDate=%s\n' "$2" "$3" \
    >"$trash/info/$1.trashinfo"
}

# metadata whose payload is already gone (some cleaner emptied Trash/files)
trash_info_only() { # <name> <encoded-path> <deletion-date>
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

# a fully blocked newest batch must stop undo, not skip ahead to an older batch
trash_one 'blocked.txt' "$src/blocked.txt" '2099-01-02T00:00:00'
trash_one 'earlier.txt' "$src/earlier.txt" '2099-01-01T00:00:00'
echo "pre-existing" >"$src/blocked.txt"
"$repo/.local/bin/trash-undo" >/dev/null
check no "$(present "$src/earlier.txt")" 'blocked newest batch does not restore older batch'
check yes "$(present "$trash/info/blocked.txt.trashinfo")" 'blocked .trashinfo kept'
check 0 "$(ls "$state"/batch.* 2>/dev/null | wc -l)" 'blocked batch records no redo'

rm -- "$src/blocked.txt"
"$repo/.local/bin/trash-undo" >/dev/null
check yes "$(present "$src/blocked.txt")" 'unblocked newest batch restored'
"$repo/.local/bin/trash-undo" >/dev/null
check yes "$(present "$src/earlier.txt")" 'older batch restored after newest'

"$repo/.local/bin/trash-redo" >/dev/null
check no "$(present "$src/earlier.txt")" 'redo re-trashes earlier.txt'
"$repo/.local/bin/trash-redo" >/dev/null
check no "$(present "$src/blocked.txt")" 'redo re-trashes blocked.txt'
check 'nothing to redo' "$("$repo/.local/bin/trash-redo" 2>&1)" 'empty state reports nothing to redo'

# a failed redo-state write must not lose the record of an already restored file
bin="$work/fail-bin"
mkdir -p "$bin"
cat >"$bin/mv" <<'EOF'
#!/bin/bash
/bin/mv "$@" || exit $?
chmod 400 "$XDG_STATE_HOME"/trash-redo/batch.* 2>/dev/null
EOF
chmod +x "$bin/mv"
trash_one 'record.txt' "$src/record.txt" '2099-04-01T00:00:00'
PATH="$bin:$PATH" "$repo/.local/bin/trash-undo" >/dev/null 2>&1
check yes "$(present "$src/record.txt")" 'failed state write still restores the file'
chmod 600 "$state"/batch.* 2>/dev/null
"$repo/.local/bin/trash-redo" >/dev/null 2>&1
check no "$(present "$src/record.txt")" 'redo uses the record written before the move'
check yes "$(present "$trash/files/record.txt")" 'redo puts the file back in trash'

# a restore that cannot write must say so instead of looking successful
mkdir -p "$src/ro"
trash_one 'locked.txt' "$src/ro/locked.txt" '2099-01-03T00:00:00'
chmod 500 "$src/ro"
out=$("$repo/.local/bin/trash-undo" 2>&1)
status=$?
chmod 700 "$src/ro"
check 1 "$status" 'unwritable restore exits 1'
case $out in *"failed: $src/ro/locked.txt"*) ;; *) echo "FAIL: unwritable restore output: $out"; fails=$((fails + 1)) ;; esac
check yes "$(present "$trash/info/locked.txt.trashinfo")" 'failed restore keeps the .trashinfo'
check no "$(present "$src/blocked.txt")" 'failed restore does not walk back to blocked.txt'
check no "$(present "$src/earlier.txt")" 'failed restore does not walk back to earlier.txt'

# metadata whose payload is gone must be dropped, not block the batch behind it
trash_info_only 'ghost.txt' "$src/ghost.txt" '2099-02-02T00:00:00'
trash_one 'real.txt' "$src/real.txt" '2099-02-01T00:00:00'
out=$("$repo/.local/bin/trash-undo" 2>&1)
status=$?
check 0 "$status" 'ghost entry does not fail undo'
check yes "$(present "$src/real.txt")" 'undo restores the batch behind a ghost entry'
check no "$(present "$trash/info/ghost.txt.trashinfo")" 'ghost metadata removed'
case $out in *"missing: $src/ghost.txt"*) ;; *) echo "FAIL: ghost output: $out"; fails=$((fails + 1)) ;; esac

# an unwritable state dir must fail before restoring anything
trash_one 'nostate.txt' "$src/nostate.txt" '2099-03-01T00:00:00'
chmod 500 "$state"
out=$("$repo/.local/bin/trash-undo" 2>&1)
status=$?
chmod 700 "$state"
check 1 "$status" 'unwritable state exits 1'
check no "$(present "$src/nostate.txt")" 'unwritable state restores nothing'
check yes "$(present "$trash/info/nostate.txt.trashinfo")" 'unwritable state keeps the .trashinfo'

# reading Path= must not fork one sed per trashed file
real_sed=$(command -v sed)
bin="$work/count-sed-bin"
mkdir -p "$bin"
cat >"$bin/sed" <<EOF
#!/bin/bash
printf 'x' >>"$work/sed-count"
exec "$real_sed" "\$@"
EOF
chmod +x "$bin/sed"
trash_one 'noseda.txt' "$src/noseda.txt" '2099-05-01T00:00:00'
trash_one 'nosedb.txt' "$src/nosedb.txt" '2099-05-01T00:00:00'
: >"$work/sed-count"
PATH="$bin:$PATH" "$repo/.local/bin/trash-undo" >/dev/null 2>&1
count=$(wc -c <"$work/sed-count")
check 0 "$count" 'undo does not fork sed per trashed file'
check yes "$(present "$src/noseda.txt")" 'undo still restores without sed'
check yes "$(present "$src/nosedb.txt")" 'undo still restores the whole batch without sed'

[ "$fails" = 0 ] && echo "ok: trash undo/redo"
exit "$fails"
