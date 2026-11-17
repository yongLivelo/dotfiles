#!/bin/bash

# to_resolve round trip: mp4 -> ProRes/PCM .mov, idempotent skip, -d delete,
# TypeScript .ts skipped, and a failed conversion exits non-zero.
# usage: tests/to_resolve.sh

set -u
repo=$(dirname -- "$(readlink -f -- "$0")")/..
work=$(mktemp -d "${TMPDIR:-/tmp}/to-resolve-test.XXXXXX") || exit 1
trap 'rm -rf -- "$work"' EXIT
cd "$work" || exit 1

if ! command -v ffmpeg >/dev/null || ! command -v ffprobe >/dev/null; then
  echo "skip: ffmpeg/ffprobe not installed"
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
codec() { ffprobe -v error -select_streams "$1" -show_entries stream=codec_name -of default=nw=1:nk=1 "$2"; }
clip() { # <output>
  ffmpeg -v error -f lavfi -i testsrc=size=64x64:rate=10:duration=1 \
    -f lavfi -i sine=frequency=440:duration=1 -shortest \
    -c:v libx264 -c:a aac -y "$1"
}

clip in.mp4
"$repo/.local/bin/to_resolve" >/dev/null
status=$?
check 0 "$status" 'first run exits 0'
check yes "$(present in.mov)" 'mp4 converted to mov'
check prores "$(codec v:0 in.mov)" 'video is ProRes'
check pcm_s16le "$(codec a:0 in.mov)" 'audio is PCM'
check no "$(present in.mov.part)" '.part cleaned up'
check yes "$(present in.mp4)" 'original kept without -d'

"$repo/.local/bin/to_resolve" >/dev/null
status=$?
check 0 "$status" 'second run exits 0'
check prores "$(codec v:0 in.mov)" 'already-converted file skipped'

clip del.mp4
"$repo/.local/bin/to_resolve" -d >/dev/null
status=$?
check 0 "$status" '-d run exits 0'
check yes "$(present del.mov)" '-d still writes the mov'
check no "$(present del.mp4)" '-d removes the original'

printf 'export const x = 1\n' >main.ts
clip ts.mp4
"$repo/.local/bin/to_resolve" >/dev/null
status=$?
check 0 "$status" 'TypeScript .ts skipped, run exits 0'
check yes "$(present main.ts)" 'TypeScript .ts left alone'
check no "$(present main.mov)" 'no mov made from TypeScript'

# standalone audio: mp3 -> pcm_s24le wav, then skipped on the next run
ffmpeg -v error -f lavfi -i sine=frequency=440:duration=1 -c:a libmp3lame -y tone.mp3
"$repo/.local/bin/to_resolve" >/dev/null
status=$?
check 0 "$status" 'audio run exits 0'
check yes "$(present tone.wav)" 'mp3 converted to wav'
check pcm_s24le "$(codec a:0 tone.wav)" 'audio is PCM'
out=$("$repo/.local/bin/to_resolve" 2>&1)
status=$?
check 0 "$status" 'second audio run exits 0'
check yes "$(present tone.mp3)" 'original audio kept'
case $out in *"skip: tone.wav (already PCM)"*) ;; *) echo "FAIL: audio skip output: $out"; fails=$((fails + 1)) ;; esac

printf 'not a video\n' >bad.mp4
"$repo/.local/bin/to_resolve" >/dev/null 2>&1
status=$?
check 1 "$status" 'failed conversion exits 1'
check no "$(present bad.mov)" 'failed conversion leaves no output'
check yes "$(present bad.mp4)" 'failed conversion keeps the original'

[ "$fails" = 0 ] && echo "ok: to_resolve"
exit "$fails"
