# Referat

Norsk møtetranskribering for Claude Code. Du gir den et lydopptak, og får et
strukturert referat med beslutninger og todos tilbake.

Transkriberingen kjører på din egen maskin, så lyden lastes aldri opp noe sted.
Selve referatet skrives av Claude Code i økten din, på Pro- eller
Max-abonnementet du allerede har. Da er det ingen API-nøkkel å holde styr på, og
ingen kostnad per møte.

## Hvorfor NB-Whisper

Generisk Whisper er 2–3 ganger dårligere på norsk. Ordfeilrate:

| Modell | NST bokmål | Common Voice nynorsk |
|---|---|---|
| NB-Whisper Large | 2,2 % | 12,6 % |
| Whisper large-v3 | 6,8 % | 30,0 % |

Forskjellen er størst på dialekt, og det er nettopp der generiske modeller
svikter. NB-Whisper er trent av Nasjonalbiblioteket på 66 000 timer norsk tale
med ekte dialekter og begge målformer.

## Krav

- Mac med Apple Silicon
- [Homebrew](https://brew.sh)
- Claude Code, innlogget med Pro- eller Max-abonnement
- Rundt 1,5 GB ledig plass

## Installasjon

I Claude Code:

```
/plugin marketplace add nicoskogen/referat
/plugin marketplace add floka-as/floka-marketplace
/plugin install referat
/referat-setup
```

Start Claude Code på nytt etterpå, slik at pluginen lastes.

`/referat-setup` installerer `whisper-cpp` og `ffmpeg` via Homebrew, laster ned
modellen på 1 GB til `~/.cache/nb-whisper/`, sjekker kontrollsummen og tester
til slutt at alt virker. Det tar noen minutter, og du gjør det bare én gang.

Den andre katalogen er der for
[`humanizer`](https://github.com/Floka-as/floka-marketplace/tree/main/humanizer),
som vasker språket i referatet. Den installeres automatisk som avhengighet, men
Claude Code henter ikke plugins fra en katalog du ikke har lagt til selv.

Du trenger ikke klone noe, og verken Python eller HuggingFace-token er
involvert.

## Bruk

```
/referat ~/Downloads/mote.m4a
```

Det fungerer med alle formater ffmpeg kan lese: `m4a`, `mp3`, `wav`, `mp4`,
`aiff`. Opptak fra Teams, Zoom, Meet eller en telefon som lå på bordet går like
fint.

Du får tre filer ved siden av lydfilen:

| Fil | Innhold |
|---|---|
| `<navn>.txt` | Rå transkripsjon |
| `<navn>.vtt` | Transkripsjon med tidsstempler |
| `<navn>-referat.md` | Det ferdige referatet |

En time med lyd tar omtrent 10–20 minutter på en M1 Pro. Transkripsjonen
mellomlagres, så kjører du `/referat` på samme fil igjen, kommer svaret med én
gang.

## Slik virker det

```
lyd ──► ffmpeg ──► whisper.cpp + NB-Whisper ──► transkripsjon
        16k mono     lokalt, Metal-akselerert         │
                                                       ▼
                                       Claude Code leser den i økten
                                                       ▼
                                                 referat.md
```

Transkriberingen er et lokalt bash-steg. Referatet skrives av Claude Code, som
allerede er autentisert med abonnementet ditt, og det er derfor ingen API-nøkkel
dukker opp noe sted i kjeden.

## Begrensninger

Referatet skiller ikke mellom talere. Det forteller hva som ble sagt, ikke hvem
som sa det, med mindre navn nevnes i samtalen. Å legge det til ville dratt inn
Python, PyTorch og en tilgangsstyrt modell fra HuggingFace, og det er ikke verdt
det for noe bare enkelte har bruk for.

Engelske produktnavn blir dårlig gjengitt. Modellen er trent på norsk, så vanlig
norsk er til å stole på, mens engelske låneord og merkenavn som regel må rettes
for hånd.

Les gjennom referatet før du sender det videre. Talegjenkjenning svikter
fremdeles ved kryssprat og dårlige mikrofoner. Passasjer modellen var usikker
på, er merket `[uklart]`, men det fanger ikke alt.

Du må også kjøre det selv. Ingenting plukker opp møter automatisk, siden
uovervåket kjøring ville krevd API-tilgang og dermed en egen API-nøkkel utenfor
abonnementet.

Foreløpig virker det bare på macOS med Apple Silicon.

Hvor mikrofonen står betyr mer for resultatet enn hvilken modell du velger. Et
opptak fra en mikrofon på bordet blir merkbart bedre enn en laptop i andre enden
av rommet.

## Kreditering

- [NB-Whisper](https://huggingface.co/NbAiLab/nb-whisper-large),
  Nasjonalbiblioteket, Apache 2.0
- [whisper.cpp](https://github.com/ggerganov/whisper.cpp), MIT
- [humanizer](https://github.com/Floka-as/floka-marketplace/tree/main/humanizer),
  Floka AS, MIT

## Lisens

MIT
