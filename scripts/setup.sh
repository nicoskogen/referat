#!/usr/bin/env bash
#
# Engangsoppsett for transkriber: installerer whisper.cpp + ffmpeg og laster ned
# NB-Whisper-modellen fra Nasjonalbiblioteket.
#
#   ./setup.sh          laster ned kvantisert modell (1031 MB) — anbefalt
#   ./setup.sh --full   laster ned full presisjon (2951 MB)

set -euo pipefail

MODEL_DIR="${NB_WHISPER_DIR:-$HOME/.cache/nb-whisper}"
BASE_URL="https://huggingface.co/NbAiLab/nb-whisper-large/resolve/main"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Kontrollsummer hentet fra Hugging Face. En avbrutt nedlasting gir en modell
# som "virker" men produserer søppel — derfor verifiserer vi alltid.
MODEL_NAME="ggml-model-q5_0.bin"
MODEL_SHA="feb5951ae694a62cfeb81fb501f6cfa8cc50d96bcddb1e4e8215f7006bac23a2"
MODEL_MB=1031

if [ "${1:-}" = "--full" ]; then
    MODEL_NAME="ggml-model.bin"
    MODEL_SHA="0f2f66f22e11a7c7da3c582d8e5c89cb2c0011753ba9c7c9731e320a4ba33e76"
    MODEL_MB=2951
fi

say_step() { printf '\n▸ %s\n' "$1"; }
die()      { printf '\n✗ transkriber: %s\n' "$1" >&2; exit 1; }

# ---------------------------------------------------------------- plattform
[ "$(uname -s)" = "Darwin" ] || die "setup.sh støtter foreløpig kun macOS."
if [ "$(uname -m)" != "arm64" ]; then
    printf '⚠  Ikke Apple Silicon — transkribering blir vesentlig tregere.\n'
fi

# ------------------------------------------------------------ avhengigheter
say_step "Sjekker avhengigheter"
command -v brew >/dev/null 2>&1 || die "Homebrew mangler. Installer fra https://brew.sh og kjør på nytt."

for pkg in whisper-cpp ffmpeg; do
    if brew list --formula "$pkg" >/dev/null 2>&1; then
        printf '  ✓ %s\n' "$pkg"
    else
        printf '  … installerer %s\n' "$pkg"
        brew install "$pkg" || die "klarte ikke å installere $pkg"
    fi
done

WHISPER=""
for candidate in whisper-cli whisper-cpp; do
    command -v "$candidate" >/dev/null 2>&1 && { WHISPER="$candidate"; break; }
done
[ -n "$WHISPER" ] || die "fant ikke whisper.cpp-binæren etter installasjon."
printf '  ✓ binær: %s\n' "$WHISPER"

# ------------------------------------------------------------------ modell
say_step "NB-Whisper-modell ($MODEL_NAME, ${MODEL_MB} MB)"
mkdir -p "$MODEL_DIR"
TARGET="$MODEL_DIR/$MODEL_NAME"

verify() {
    [ -f "$TARGET" ] || return 1
    printf '  … verifiserer kontrollsum\n'
    [ "$(shasum -a 256 "$TARGET" | awk '{print $1}')" = "$MODEL_SHA" ]
}

if verify; then
    printf '  ✓ modellen finnes allerede og er intakt\n'
else
    if [ -f "$TARGET" ]; then
        printf '  ⚠ ufullstendig nedlasting oppdaget — fortsetter\n'
    fi
    printf '  … laster ned fra Hugging Face (kan gjenopptas med Ctrl-C + ny kjøring)\n'
    curl -L -C - --fail --progress-bar -o "$TARGET" "$BASE_URL/$MODEL_NAME" \
        || die "nedlasting feilet. Kjør setup.sh på nytt for å gjenoppta."
    verify || die "kontrollsummen stemmer ikke. Slett $TARGET og prøv igjen."
    printf '  ✓ nedlastet og verifisert\n'
fi

# --------------------------------------------------------------- røyktest
say_step "Røyktest — syntetiserer norsk tale og transkriberer den"
if ! say -v '?' 2>/dev/null | grep -q 'nb_NO'; then
    printf '  ⚠ ingen norsk systemstemme funnet — hopper over røyktesten.\n'
    printf '    Oppsettet er sannsynligvis i orden. Test med en ekte lydfil.\n'
else
    WORK="$(mktemp -d)"
    trap 'rm -rf "$WORK"' EXIT
    PHRASE="Vi ble enige om å levere rapporten før fredag."
    say -v Nora -o "$WORK/smoke.aiff" "$PHRASE"

    if OUT=$("$SCRIPT_DIR/transcribe.sh" "$WORK/smoke.aiff" 2>/dev/null) \
        && grep -qiE 'rapport|fredag' "$OUT"; then
        printf '  ✓ transkriberte: %s\n' "$(tr -s ' \n' ' ' < "$OUT" | sed 's/^ *//')"
    else
        die "røyktesten feilet — modellen lastet, men transkriberingen ga ikke forventet tekst."
    fi
fi

say_step "Ferdig"
cat <<'EOF'
  Bruk:  /transkriber <sti-til-fil>

  Du blir spurt om du vil ha møtereferat, ren transkripsjon eller
  undertekster (.srt). Sier du det med én gang, slipper du spørsmålet:
  «lag undertekster av opptaket i nedlastinger».

  Video går rett inn. .mp4 og .mov trenger ingen lydeksport først.
  En times opptak tar typisk 10-20 minutter.
EOF
