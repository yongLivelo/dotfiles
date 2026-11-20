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

# a newer source with the same name must replace its stale output
clip stale.mp4
"$repo/.local/bin/to_resolve" >/dev/null
stale_at=$(stat -c %Y stale.mov)
sleep 1
clip stale.mp4
out=$("$repo/.local/bin/to_resolve" 2>&1)
case $out in *"skip: stale.mp4"*) echo "FAIL: newer source skipped"; fails=$((fails + 1)) ;; esac
new_at=$(stat -c %Y stale.mov)
check yes "$([ "$new_at" -gt "$stale_at" ] && echo yes || echo no)" 'newer source replaces stale output'
check no "$(present stale.mov.part)" 'stale replacement cleans up .part'

# a same-name source must not be replaced by a different source's derived output
ffmpeg -v error -f lavfi -i testsrc=size=64x64:rate=5:duration=1 \
  -c:v libx264 -y collide.mp4
ffmpeg -v error -f lavfi -i color=c=blue:size=32x32:rate=5:duration=1 \
  -c:v libx264 -y collide.mov
touch -d '2020-01-01 00:00:00' collide.mov
out=$("$repo/.local/bin/to_resolve" 2>&1)
status=$?
check 0 "$status" 'same-name source run exits 0'
check 32 "$(ffprobe -v error -select_streams v:0 -show_entries stream=width -of default=nw=1:nk=1 collide.mov)" \
  'unconverted same-name source keeps its own content'
check yes "$(present collide.mp4)" 'source behind the collision is kept'
case $out in *"same-name source"*) ;; *) echo "FAIL: collision warning missing: $out"; fails=$((fails + 1)) ;; esac

# in-place re-encode: a non-ProRes .mov is replaced through .part, keeping its name
clip same.mov
out=$("$repo/.local/bin/to_resolve")
status=$?
check 0 "$status" 'in-place run exits 0'
check prores "$(codec v:0 same.mov)" 'in-place mov is ProRes'
check pcm_s16le "$(codec a:0 same.mov)" 'in-place mov audio is PCM'
check no "$(present same.mov.part)" 'in-place .part cleaned up'
case $out in *"skip: same.mov"*) echo "FAIL: in-place mov was skipped"; fails=$((fails + 1)) ;; esac

# an in-place rewrite must keep the original file's permissions
ffmpeg -v error -f lavfi -i testsrc=size=64x64:rate=5:duration=1 -c:v libx264 -y perm.mov
chmod 660 perm.mov
"$repo/.local/bin/to_resolve" >/dev/null 2>&1
check 660 "$(stat -c %a perm.mov)" 'in-place conversion keeps permissions'

# in-place re-encode: a non-ProRes .mkv is replaced through .part, keeping its name
clip same.mkv
out=$("$repo/.local/bin/to_resolve")
status=$?
check 0 "$status" 'in-place mkv run exits 0'
check prores "$(codec v:0 same.mkv)" 'in-place mkv is ProRes'
check pcm_s16le "$(codec a:0 same.mkv)" 'in-place mkv audio is PCM'
check no "$(present same.mkv.part)" 'in-place mkv .part cleaned up'
case $out in *"skip: same.mkv"*) echo "FAIL: in-place mkv was skipped"; fails=$((fails + 1)) ;; esac

# in-place re-encode must keep every audio track (the default map keeps only one)
ffmpeg -v error -f lavfi -i testsrc=size=64x64:rate=10:duration=1 \
  -f lavfi -i sine=frequency=440:duration=1 -f lavfi -i sine=frequency=880:duration=1 \
  -map 0:v -map 1:a -map 2:a -c:v libx264 -c:a aac -y multi.mov
"$repo/.local/bin/to_resolve" >/dev/null
status=$?
check 0 "$status" 'multi-audio run exits 0'
check 2 "$(ffprobe -v error -select_streams a -show_entries stream=index -of csv=p=0 multi.mov | wc -l)" \
  'multi-audio mov keeps both audio tracks'

# an in-place rewrite must keep subtitles, not silently drop them
mkdir -p "$work/subs"
clip "$work/subs/in.mkv"
printf '1\n00:00:00,000 --> 00:00:00,500\nhi\n' >"$work/subs/s.srt"
ffmpeg -v error -i "$work/subs/in.mkv" -i "$work/subs/s.srt" -map 0 -map 1 \
  -c copy -c:s srt -y "$work/subs/sub.mkv"
( cd "$work/subs" && "$repo/.local/bin/to_resolve" >/dev/null )
status=$?
check 0 "$status" 'subtitle run exits 0'
check prores "$(codec v:0 "$work/subs/sub.mkv")" 'subtitle mkv video is ProRes'
check subrip "$(ffprobe -v error -select_streams s:0 -show_entries stream=codec_name -of default=nw=1:nk=1 "$work/subs/sub.mkv")" \
  'subtitle track survives in-place conversion'

# every video track must survive, not just the first
ffmpeg -v error -f lavfi -i testsrc=size=64x64:rate=10:duration=1 \
  -f lavfi -i color=c=red:size=64x64:rate=10:duration=1 \
  -map 0:v -map 1:v -c:v libx264 -y two.mkv
"$repo/.local/bin/to_resolve" >/dev/null
status=$?
check 0 "$status" 'multi-video run exits 0'
check 2 "$(ffprobe -v error -select_streams v -show_entries stream=index -of csv=p=0 two.mkv | wc -l)" \
  'multi-video mkv keeps both video tracks'
check prores,prores "$(codec v:0 two.mkv),$(codec v:1 two.mkv)" 'multi-video mkv encodes both as ProRes'

# mov cannot carry webvtt, so a .webm with subtitles must still convert to .mov
printf '1\n00:00:00,000 --> 00:00:00,500\nhi\n' >web.srt
ffmpeg -v error -f lavfi -i testsrc=size=64x64:rate=10:duration=1 \
  -f lavfi -i sine=frequency=440:duration=1 -i web.srt \
  -map 0:v -map 1:a -map 2:s -c:v libvpx-vp9 -c:a libvorbis -c:s webvtt -y web.webm
"$repo/.local/bin/to_resolve" >/dev/null
status=$?
check 0 "$status" 'webm with webvtt run exits 0'
check mov_text "$(codec s:0 web.mov)" 'webvtt subtitle converted to mov_text'

# an mkv converted in place keeps its attachments
printf 'x' >font.ttf
ffmpeg -v error -f lavfi -i testsrc=size=64x64:rate=10:duration=1 \
  -f lavfi -i sine=frequency=440:duration=1 -c:v libx264 -c:a aac \
  -attach font.ttf -metadata:s:t mimetype=application/x-truetype-font -y attached.mkv
"$repo/.local/bin/to_resolve" >/dev/null
status=$?
check 0 "$status" 'mkv with attachment run exits 0'
check 1 "$(ffprobe -v error -select_streams t -show_entries stream=index -of csv=p=0 attached.mkv | wc -l)" \
  'in-place mkv keeps attachments'

# ...but a .mov target must not fail on the attachment it cannot store
cp attached.mkv attached.flv
out=$("$repo/.local/bin/to_resolve" 2>&1)
status=$?
check 0 "$status" 'mkv with attachment converts to mov'
check yes "$(present attached.mov)" 'mov output written despite attachment'
case $out in *"dropping attachments"*) ;; *) echo "FAIL: attachment warning missing: $out"; fails=$((fails + 1)) ;; esac

# an audio-only mov is Resolve-ready after one run and must not be re-encoded
ffmpeg -v error -f lavfi -i sine=frequency=440:duration=1 -c:a aac -y podcast.mov
"$repo/.local/bin/to_resolve" >/dev/null
out=$("$repo/.local/bin/to_resolve" 2>&1)
status=$?
check 0 "$status" 'audio-only mov second run exits 0'
check pcm_s16le "$(codec a:0 podcast.mov)" 'audio-only mov is PCM'
case $out in *"skip: podcast.mov (already ProRes/PCM)"*) ;; *) echo "FAIL: audio-only mov skip output: $out"; fails=$((fails + 1)) ;; esac

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

# TypeScript .mts is a module extension too: skip it like .ts
printf 'export const x = 3\n' >main.mts
out=$("$repo/.local/bin/to_resolve" 2>&1)
status=$?
check 0 "$status" 'TypeScript .mts skipped, run exits 0'
check yes "$(present main.mts)" 'TypeScript .mts left alone'
check no "$(present main.mov)" 'no mov made from TypeScript .mts'
case $out in *"skip: main.mts"*) ;; *) echo "FAIL: .mts skip output: $out"; fails=$((fails + 1)) ;; esac

# a filename argument would convert the whole folder unseen, so it is refused
clip arg.mp4
out=$("$repo/.local/bin/to_resolve" arg.mp4 2>&1)
status=$?
check 2 "$status" 'filename argument exits 2'
check no "$(present arg.mov)" 'filename argument converts nothing'

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

# without ffprobe, a converted same-name output must still be refreshed by mtime
ln -s "$(command -v mv)" "$bin/mv"
ln -s "$(command -v rm)" "$bin/rm"
guard="$work/no-ffprobe-guard"
mkdir -p "$guard"
clip "$guard/guard.mp4"
ffmpeg -v error -f lavfi -i testsrc=size=32x32:rate=5:duration=1 \
  -c:v prores_ks -profile:v 2 -y "$guard/guard.mov"
touch -d '2020-01-01 00:00:00' "$guard/guard.mov"
(
  cd "$guard" || exit 1
  out=$(PATH="$bin" "$repo/.local/bin/to_resolve" 2>&1)
  case $out in *"same-name source"*) echo "FAIL: false collision without ffprobe: $out" >&2; exit 1 ;; esac
)
check 0 "$?" 'no-ffprobe guard does not mislabel converted output'
check 64 "$(ffprobe -v error -select_streams v:0 -show_entries stream=width -of default=nw=1:nk=1 "$guard/guard.mov")" \
  'no-ffprobe run still refreshes converted output'

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

# a newer audio source must replace its stale wav
ffmpeg -v error -f lavfi -i sine=frequency=660:duration=1 -c:a libmp3lame -y oldtone.mp3
"$repo/.local/bin/to_resolve" >/dev/null
wav_at=$(stat -c %Y oldtone.wav)
sleep 1
ffmpeg -v error -f lavfi -i sine=frequency=220:duration=1 -c:a libmp3lame -y oldtone.mp3
out=$("$repo/.local/bin/to_resolve" 2>&1)
case $out in *"skip: oldtone.mp3"*) echo "FAIL: newer audio source skipped"; fails=$((fails + 1)) ;; esac
new_wav_at=$(stat -c %Y oldtone.wav)
check yes "$([ "$new_wav_at" -gt "$wav_at" ] && echo yes || echo no)" 'newer audio source replaces stale wav'

# a same-name unconverted wav must not be replaced by another source's output
ffmpeg -v error -f lavfi -i 'sine=frequency=440:sample_rate=44100:duration=1' -ac 1 \
  -c:a libmp3lame -y collide.mp3
ffmpeg -v error -f lavfi -i 'sine=frequency=880:sample_rate=44100:duration=1' -ac 2 \
  -c:a adpcm_ima_wav -y collide.wav
touch -d '2020-01-01 00:00:00' collide.wav
out=$("$repo/.local/bin/to_resolve" 2>&1)
status=$?
check 0 "$status" 'same-name audio source run exits 0'
check 2 "$(ffprobe -v error -select_streams a:0 -show_entries stream=channels -of default=nw=1:nk=1 collide.wav)" \
  'unconverted same-name audio source keeps its own content'
case $out in *"same-name source"*) ;; *) echo "FAIL: audio collision warning missing: $out"; fails=$((fails + 1)) ;; esac

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

# an unreadable in-place container must fail, not be mistaken for an empty ProRes file
mkdir -p corrupt
printf 'not a video\n' >corrupt/bad.mov
out=$( cd corrupt && "$repo/.local/bin/to_resolve" 2>&1 )
status=$?
check 1 "$status" 'corrupt in-place container exits 1'
case $out in *"skip: bad.mov"*) echo "FAIL: corrupt mov was skipped: $out"; fails=$((fails + 1)) ;; esac
check yes "$(present corrupt/bad.mov)" 'corrupt in-place container kept'

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

# an interrupted encode must clean up its .part file
mkdir -p "$work/interrupt/bin"
cat >"$work/interrupt/bin/ffmpeg" <<'EOF'
#!/bin/bash
for a in "$@"; do last=$a; done
printf data >"$last"
sleep 2
EOF
chmod +x "$work/interrupt/bin/ffmpeg"
printf x >"$work/interrupt/clip.mp4"
(
  cd "$work/interrupt" || exit 1
  PATH="$work/interrupt/bin:$PATH" "$repo/.local/bin/to_resolve" >/dev/null 2>&1 &
  pid=$!
  sleep 0.3
  kill -TERM "$pid" 2>/dev/null
  wait "$pid" 2>/dev/null
  exit 0
)
sleep 2.5
check '' "$(compgen -G "$work/interrupt/*.part*")" 'interrupted encode leaves no .part'

# a fixed .part name would let two runs corrupt each other
check '' "$(compgen -G '*.part*')" 'no .part leftovers'

[ "$fails" = 0 ] && echo "ok: to_resolve"
exit "$fails"
