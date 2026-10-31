#!/bin/sh
# Two synthetic takes of the same 1-minute pitch, made with macOS `say`
# (voice Luciana, pt-BR): one rushed with no pauses, one paced with pauses.
# Output: /tmp/vox-samples/{rushed,paced}.wav (16 kHz mono), not committed.
set -e
here=$(dirname "$0")
out=/tmp/vox-samples
mkdir -p "$out"
text=$(cat "$here/pitch.txt")
paced=$(printf '%s' "$text" | sed 's/\([.?!]\) /\1 [[slnc 900]] /g; s/, /, [[slnc 250]] /g')
say -v Luciana -r 215 -o "$out/rushed.aiff" "$text"
say -v Luciana -r 140 -o "$out/paced.aiff" "$paced"
for take in rushed paced; do
  ffmpeg -loglevel error -y -i "$out/$take.aiff" -ac 1 -ar 16000 "$out/$take.wav"
done
echo "$out/rushed.wav $out/paced.wav"
