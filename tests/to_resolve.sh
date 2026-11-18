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

source "$repo/tests/lib.sh"
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

# in-place re-encode: a non-ProRes .mov is replaced through .part, keeping its name
clip same.mov
out=$("$repo/.local/bin/to_resolve")
status=$?
check 0 "$status" 'in-place run exits 0'
check prores "$(codec v:0 same.mov)" 'in-place mov is ProRes'
check pcm_s16le "$(codec a:0 same.mov)" 'in-place mov audio is PCM'
check no "$(present same.mov.part)" 'in-place .part cleaned up'
case $out in *"skip: same.mov"*) echo "FAIL: in-place mov was skipped"; fails=$((fails + 1)) ;; esac

# in-place re-encode: a non-ProRes .mkv is replaced through .part, keeping its name
clip same.mkv
out=$("$repo/.local/bin/to_resolve")
status=$?
check 0 "$status" 'in-place mkv run exits 0'
check prores "$(codec v:0 same.mkv)" 'in-place mkv is ProRes'
check pcm_s16le "$(codec a:0 same.mkv)" 'in-place mkv audio is PCM'
check no "$(present same.mkv.part)" 'in-place mkv .part cleaned up'
case $out in *"skip: same.mkv"*) echo "FAIL: in-place mkv was skipped"; fails=$((fails + 1)) ;; esac

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

# .ts must be skipped even when ffprobe is unavailable
bin="$work/no-ffprobe-bin"
mkdir -p "$bin" "$work/no-ffprobe"
ln -s "$(command -v ffmpeg)" "$bin/ffmpeg"
(
  cd "$work/no-ffprobe" || exit 1
  printf 'export const x = 2\n' >main.ts
  PATH="$bin" "$repo/.local/bin/to_resolve" >/dev/null 2>&1
)
status=$?
check 0 "$status" 'TypeScript skipped without ffprobe'
check no "$(present "$work/no-ffprobe/main.mov")" 'no mov from TypeScript without ffprobe'

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

# compressed AIFF must convert in place; AIFF needs big-endian PCM
ffmpeg -v error -f lavfi -i sine=frequency=440:duration=1 -c:a adpcm_ima_qt -y tone.aiff
"$repo/.local/bin/to_resolve" >/dev/null 2>&1
status=$?
check 0 "$status" 'compressed aiff run exits 0'
check pcm_s24be "$(codec a:0 tone.aiff)" 'compressed aiff converted to PCM in place'
check no "$(present tone.aiff.part)" 'aiff .part cleaned up'

printf 'not a video\n' >bad.mp4
"$repo/.local/bin/to_resolve" >/dev/null 2>&1
status=$?
check 1 "$status" 'failed conversion exits 1'
check no "$(present bad.mov)" 'failed conversion leaves no output'
check yes "$(present bad.mp4)" 'failed conversion keeps the original'

# an unknown flag must not be silently ignored
clip flag.mp4
"$repo/.local/bin/to_resolve" -D >/dev/null 2>&1
status=$?
check 2 "$status" 'unknown flag exits 2'
check no "$(present flag.mov)" 'unknown flag converts nothing'

# a successful conversion must not dump ffmpeg's banner on stderr
mkdir -p "$work/quiet"
clip "$work/quiet/quiet.mp4"
(
  cd "$work/quiet" || exit 1
  err=$("$repo/.local/bin/to_resolve" 2>&1 >/dev/null)
  case $err in *"ffmpeg version"*) exit 1 ;; *) exit 0 ;; esac
)
check 0 "$?" 'conversion keeps ffmpeg quiet'

[ "$fails" = 0 ] && echo "ok: to_resolve"
exit "$fails"
