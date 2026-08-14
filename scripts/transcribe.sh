#!/usr/bin/env bash
#
# Transkriberer lyd eller video til norsk tekst med NB-Whisper via whisper.cpp.
# Alt kjører lokalt — ingenting forlater maskinen.
#
#   transcribe.sh <fil>                    ren tekst (.txt + .vtt)
#   transcribe.sh <fil> --modus srt        undertekster (.srt)
#   transcribe.sh <fil> --modus srt --maks-lengde 64
#
# Video går rett inn: ffmpeg henter ut lydsporet, så .mp4 og .mov trenger
# ingen eksport først.
#
# Skriver stien til resultatet på stdout. Framdrift går til stderr, slik at
# `RES=$(transcribe.sh fil.mov)` fungerer.

set -euo pipefail

MODEL_DIR="${NB_WHISPER_DIR:-$HOME/.cache/nb-whisper}"
MODUS="tekst"
MAKS_LENGDE=42          # tegn per undertekstlinje, kringkastingsstandard

die() { printf 'transkriber: %s\n' "$1" >&2; exit 1; }

[ $# -ge 1 ] || die "bruk: transcribe.sh <fil> [--modus tekst|srt] [--maks-lengde N]"
IN="$1"; shift
[ -f "$IN" ] || die "finner ikke filen: $IN"

while [ $# -gt 0 ]; do
    case "$1" in
        --modus)        MODUS="${2:-}"; shift 2 ;;
        --maks-lengde)  MAKS_LENGDE="${2:-}"; shift 2 ;;
        *)              die "ukjent valg: $1" ;;
    esac
done
case "$MODUS" in
    tekst|referat|srt) ;;
    *) die "ukjent modus: $MODUS (gyldige: tekst, referat, srt)" ;;
esac

# Homebrew har levert binæren under begge navn.
WHISPER=""
for candidate in whisper-cli whisper-cpp; do
    if command -v "$candidate" >/dev/null 2>&1; then WHISPER="$candidate"; break; fi
done
[ -n "$WHISPER" ] || die "whisper.cpp mangler. Kjør /transkriber-setup først."
command -v ffmpeg >/dev/null 2>&1 || die "ffmpeg mangler. Kjør /transkriber-setup først."

MODEL=""
for m in "$MODEL_DIR/ggml-model-q5_0.bin" "$MODEL_DIR/ggml-model.bin"; do
    [ -f "$m" ] && { MODEL="$m"; break; }
done
[ -n "$MODEL" ] || die "NB-Whisper-modellen mangler i $MODEL_DIR. Kjør /transkriber-setup først."

OUT_BASE="${IN%.*}"
if [ "$MODUS" = "srt" ]; then
    RESULTAT="$OUT_BASE.srt"
    # -ml deler segmentene til undertekstlengde, -sow bryter på hele ord.
    FORMAT_FLAGG=(-osrt -ml "$MAKS_LENGDE" -sow)
else
    RESULTAT="$OUT_BASE.txt"
    # Ingen -ml her: naturlige segmenter gir bedre løpende tekst og referat.
    FORMAT_FLAGG=(-otxt -ovtt)
fi

# En times opptak tar 10–20 minutter. Ikke gjør det om igjen uten grunn.
if [ -f "$RESULTAT" ] && [ "$RESULTAT" -nt "$IN" ]; then
    printf 'transkriber: bruker eksisterende resultat (%s)\n' "$RESULTAT" >&2
    printf '%s\n' "$RESULTAT"
    exit 0
fi

# whisper.cpp tar kun 16 kHz mono PCM WAV. ffmpeg henter lydsporet ut av video
# på samme måte som fra en lydfil, så .mp4 og .mov fungerer uten eksport.
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
WAV="$WORK/audio.wav"

printf 'transkriber: henter ut lyd (16 kHz mono)…\n' >&2
ffmpeg -nostdin -loglevel error -y -i "$IN" -vn -ar 16000 -ac 1 -c:a pcm_s16le "$WAV" \
    || die "ffmpeg fant ikke lyd i $IN. Har filen et lydspor?"
[ -s "$WAV" ] || die "lydsporet i $IN er tomt"

printf 'transkriber: kjører NB-Whisper (modus: %s)…\n' "$MODUS" >&2
"$WHISPER" -m "$MODEL" -f "$WAV" -l no "${FORMAT_FLAGG[@]}" -of "$OUT_BASE" -pp >&2 \
    || die "whisper.cpp feilet under transkribering"

# To opprydninger i whisper.cpp sin utdata:
#   - spesialtokens som <|nocaptions|> lekker av og til ut i teksten
#   - hver tekstlinje får et innledende mellomrom, som enkelte
#     videoredigeringsprogrammer viser som et synlig innrykk i underteksten
for f in "$OUT_BASE.txt" "$OUT_BASE.vtt" "$OUT_BASE.srt"; do
    [ -f "$f" ] && LC_ALL=C sed -i '' -E -e 's/<\|[a-zA-Z0-9_.-]+\|>//g' -e 's/^[[:space:]]+//' "$f"
done

[ -s "$RESULTAT" ] || die "resultatet ble tomt — inneholder opptaket faktisk tale?"
printf '%s\n' "$RESULTAT"
