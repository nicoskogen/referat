#!/usr/bin/env bash
#
# Transkriberer en lydfil til norsk tekst med NB-Whisper via whisper.cpp.
# Alt kjører lokalt — ingen lyd forlater maskinen.
#
# Skriver stien til transkripsjonen på stdout. Framdrift går til stderr, slik at
# `TRANSCRIPT=$(transcribe.sh fil.m4a)` fungerer.

set -euo pipefail

MODEL_DIR="${NB_WHISPER_DIR:-$HOME/.cache/nb-whisper}"

die() { printf 'referat: %s\n' "$1" >&2; exit 1; }

[ $# -ge 1 ] || die "bruk: transcribe.sh <lydfil>"
IN="$1"
[ -f "$IN" ] || die "finner ikke filen: $IN"

# Homebrew har levert binæren under begge navn. Prøv begge før vi gir opp.
WHISPER=""
for candidate in whisper-cli whisper-cpp; do
    if command -v "$candidate" >/dev/null 2>&1; then
        WHISPER="$candidate"
        break
    fi
done
[ -n "$WHISPER" ] || die "whisper.cpp mangler. Kjør /referat-setup først."
command -v ffmpeg >/dev/null 2>&1 || die "ffmpeg mangler. Kjør /referat-setup først."

# Foretrekk den kvantiserte modellen, fall tilbake til full presisjon.
MODEL=""
for m in "$MODEL_DIR/ggml-model-q5_0.bin" "$MODEL_DIR/ggml-model.bin"; do
    [ -f "$m" ] && { MODEL="$m"; break; }
done
[ -n "$MODEL" ] || die "NB-Whisper-modellen mangler i $MODEL_DIR. Kjør /referat-setup først."

OUT_BASE="${IN%.*}"
TRANSCRIPT="$OUT_BASE.txt"

# En times møte tar 20+ minutter å transkribere. Ikke gjør det på nytt uten grunn.
if [ -f "$TRANSCRIPT" ] && [ "$TRANSCRIPT" -nt "$IN" ]; then
    printf 'referat: bruker eksisterende transkripsjon (%s)\n' "$TRANSCRIPT" >&2
    printf '%s\n' "$TRANSCRIPT"
    exit 0
fi

# whisper.cpp tar kun 16 kHz mono PCM WAV — m4a/mp3 må konverteres først.
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
WAV="$WORK/audio.wav"

printf 'referat: konverterer lyd til 16 kHz mono…\n' >&2
ffmpeg -nostdin -loglevel error -y -i "$IN" -ar 16000 -ac 1 -c:a pcm_s16le "$WAV" \
    || die "ffmpeg klarte ikke å lese lyd fra $IN"

printf 'referat: transkriberer med %s (dette tar tid)…\n' "$(basename "$MODEL")" >&2
"$WHISPER" -m "$MODEL" -f "$WAV" -l no -otxt -ovtt -of "$OUT_BASE" -pp >&2 \
    || die "whisper.cpp feilet under transkribering"

# whisper.cpp lekker av og til spesialtokens som <|nocaptions|> eller
# <|endoftext|> ut i teksten. De skal ikke havne i referatet.
for f in "$TRANSCRIPT" "$OUT_BASE.vtt"; do
    [ -f "$f" ] && LC_ALL=C sed -i '' -E 's/<\|[a-zA-Z0-9_.-]+\|>//g' "$f"
done

[ -s "$TRANSCRIPT" ] || die "transkripsjonen ble tom — sjekk at lydfilen faktisk inneholder tale"
printf '%s\n' "$TRANSCRIPT"
