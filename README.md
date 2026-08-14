# Referat

Norwegian meeting transcription for Claude Code. Point it at a recording, get
back a structured meeting summary with decisions and todos.

- **Audio never leaves your machine.** Transcription runs locally.
- **No API key.** The summary is written by Claude Code in your session, on the
  Pro/Max subscription you already have.
- **No per-meeting cost.**
- **Built for Norwegian.** Uses NB-Whisper from the National Library of Norway,
  not generic Whisper.

The output is Norwegian. If your meetings aren't in Norwegian, this isn't the
tool you want.

## Why NB-Whisper

Generic Whisper is 2–3× worse on Norwegian. Word error rate:

| Model | NST bokmål | Common Voice nynorsk |
|---|---|---|
| **NB-Whisper Large** | **2.2 %** | **12.6 %** |
| Whisper large-v3 | 6.8 % | 30.0 % |

The gap is widest on dialect, which is exactly where generic models fall over.
NB-Whisper is trained on 66,000 hours of Norwegian speech covering real dialects
and both written standards.

## Requirements

- macOS on Apple Silicon
- [Homebrew](https://brew.sh)
- Claude Code, signed in with a Pro or Max subscription
- ~1.5 GB free disk space

## Install

In Claude Code:

```
/plugin marketplace add nicoskogen/referat
/plugin marketplace add floka-as/floka-marketplace
/plugin install referat
/referat-setup
```

Then **restart Claude Code** so the plugin loads.

`/referat-setup` installs `whisper-cpp` and `ffmpeg` via Homebrew, downloads the
1 GB model to `~/.cache/nb-whisper/`, verifies its checksum, and runs a smoke
test. A few minutes, once.

The second marketplace provides [`humanizer`](https://github.com/Floka-as/floka-marketplace/tree/main/humanizer),
used to clean up the Norwegian prose. It installs automatically as a dependency,
but Claude Code won't pull a plugin from a marketplace you haven't added
yourself.

You don't need to clone this repo. No Python, no HuggingFace token.

## Usage

```
/referat ~/Downloads/mote.m4a
```

Any format ffmpeg reads: `m4a`, `mp3`, `wav`, `mp4`, `aiff`. It doesn't matter
whether the recording came from Teams, Zoom, Meet, or a phone on the table.

Three files land next to the audio:

| File | Contents |
|---|---|
| `<name>.txt` | Raw transcript |
| `<name>.vtt` | Transcript with timestamps |
| `<name>-referat.md` | The finished summary |

Expect roughly 10–20 minutes per hour of audio on an M1 Pro. The transcript is
cached, so re-running `/referat` on the same file is instant.

## How it works

```
audio ──► ffmpeg ──► whisper.cpp + NB-Whisper ──► transcript
          16k mono     local, Metal-accelerated        │
                                                        ▼
                                        Claude Code reads it in-session
                                                        ▼
                                                   referat.md
```

Transcription is a local bash step. The summary is written by Claude Code
itself, which is already authenticated with your subscription — that's why no
API key is involved anywhere.

## Limitations

- **No speaker diarization.** The summary records what was said, not who said
  it, unless names are spoken aloud. Adding it would mean Python, PyTorch and a
  gated HuggingFace model, which would make installation much worse for everyone
  to benefit a few.
- **English product names are transcribed poorly.** The model is trained on
  Norwegian. Ordinary Norwegian comes through well; English loanwords and brand
  names need proofreading.
- **Read it before you send it.** Speech recognition fails on cross-talk and bad
  microphones. The summary marks passages it isn't sure about with `[uklart]`,
  but that won't catch everything.
- **You run it yourself.** There's no automation that picks up meetings on its
  own. Unattended runs would need API access, and therefore an API key billed
  separately from your subscription.
- **macOS on Apple Silicon only**, for now.

A good microphone matters more than any model choice. A recording from a
mic in the middle of the table beats a laptop across the room every time.

## Credits

- [NB-Whisper](https://huggingface.co/NbAiLab/nb-whisper-large) — National
  Library of Norway, Apache 2.0
- [whisper.cpp](https://github.com/ggerganov/whisper.cpp) — MIT
- [humanizer](https://github.com/Floka-as/floka-marketplace/tree/main/humanizer)
  — Floka AS, MIT

## License

MIT
