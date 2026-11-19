#!/bin/bash

# vscode-task-gen: a typed working directory is used verbatim, a blank one
# falls back to ${workspaceFolder}, an empty command is rejected, declining the
# overwrite prompt aborts, and a failing writer leaves an existing tasks.json
# untouched.
# usage: tests/vscode-task-gen.sh

set -u
repo=$(dirname -- "$(readlink -f -- "$0")")/..
gen="$repo/.local/bin/vscode-task-gen"
work=$(mktemp -d "${TMPDIR:-/tmp}/vscode-task-gen-test.XXXXXX") || exit 1
trap 'rm -rf -- "$work"' EXIT
cd "$work" || exit 1

if ! command -v python3 >/dev/null; then
  echo "skip: python3 not installed"
  exit 0
fi

source "$repo/tests/lib.sh"
cwd_of() { python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["tasks"][0]["options"]["cwd"])' "$1"; }

# a typed working directory is preserved verbatim
printf 'foo\ncmd\n/tmp/x\n' | "$gen" p1 >/dev/null 2>&1
check 0 "$?" 'typed cwd run exits 0'
check /tmp/x "$(cwd_of p1/.vscode/tasks.json)" 'typed cwd preserved verbatim'

# stdin at EOF must abort without leaving a .vscode folder behind
"$gen" p5 </dev/null >/dev/null 2>&1
check 1 "$?" 'EOF at a prompt exits 1'
check no "$(present p5/.vscode)" 'EOF creates no .vscode folder'

# a blank working directory falls back to ${workspaceFolder}
printf 'foo\ncmd\n\n' | "$gen" p2 >/dev/null 2>&1
check 0 "$?" 'blank cwd run exits 0'
check '${workspaceFolder}' "$(cwd_of p2/.vscode/tasks.json)" 'blank cwd -> workspaceFolder'

# an empty command is rejected and writes nothing
printf 'foo\n\n\n' | "$gen" p3 >/dev/null 2>&1
check 1 "$?" 'empty command exits 1'
check no "$(present p3/.vscode/tasks.json)" 'empty command writes nothing'

# declining the overwrite prompt aborts and keeps the existing file
printf 'foo\ncmd\n\n' | "$gen" p4 >/dev/null 2>&1
before=$(cat p4/.vscode/tasks.json)
printf 'n\n' | "$gen" p4 >/dev/null 2>&1
check 1 "$?" 'declining overwrite exits 1'
check "$before" "$(cat p4/.vscode/tasks.json)" 'declining overwrite keeps the file'

# EOF at the overwrite prompt also aborts and keeps the file
"$gen" p4 </dev/null >/dev/null 2>&1
check 1 "$?" 'EOF at the overwrite prompt exits 1'
check "$before" "$(cat p4/.vscode/tasks.json)" 'EOF at the overwrite prompt keeps the file'

# a failing writer must not clobber the existing file
bin="$work/bin"
mkdir -p "$bin"
printf '#!/bin/bash\nexit 1\n' >"$bin/python3"
chmod +x "$bin/python3"
printf 'y\nfoo\ncmd\n\n' | PATH="$bin:$PATH" "$gen" p4 >/dev/null 2>&1
check 1 "$?" 'failing writer exits 1'
check "$before" "$(cat p4/.vscode/tasks.json)" 'failing writer keeps the file'
check '' "$(compgen -G 'p4/.vscode/tasks.json.*')" 'failing writer leaves no temp file'

# a failing writer on a fresh project must not leave an empty .vscode folder
printf 'foo\ncmd\n\n' | PATH="$bin:$PATH" "$gen" p6 >/dev/null 2>&1
check 1 "$?" 'failing writer on a fresh dir exits 1'
check no "$(present p6/.vscode)" 'failing writer creates no .vscode folder'

[ "$fails" = 0 ] && echo "ok: vscode-task-gen"
exit "$fails"
