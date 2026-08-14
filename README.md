# Referat

Norwegian meeting transcription for Claude Code. Point it at a recording and it
gives you back a structured summary with decisions and todos.

The transcription runs on your own machine, so the audio never gets uploaded
anywhere. The summary is written by Claude Code in your session, using the
Pro or Max subscription you already have, which means there is no API key to
manage and no cost per meeting.

The output is Norwegian. If your meetings are in another language this won't be
much use to you.

## Why NB-Whisper

Generic Whisper is 2–3 times worse on Norwegian. Word error rate:

| Model | NST bokmål | Common Voice nynorsk |
|---|---|---|
| NB-Whisper Large | 2.2 % | 12.6 % |
| Whisper large-v3 | 6.8 % | 30.0 % |

The difference is largest on dialect, which is where generic models tend to
fall apart. NB-Whisper was trained by the National Library of Norway on 66,000
hours of Norwegian speech covering real dialects and both written standards.

## Requirements

- macOS on Apple Silicon
- [Homebrew](https://brew.sh)
- Claude Code, signed in with a Pro or Max subscription
- About 1.5 GB of free disk space

## Install

In Claude Code:

```
/plugin marketplace add nicoskogen/referat
/plugin marketplace add floka-as/floka-marketplace
/plugin install referat
/referat-setup
```

Restart Claude Code afterwards so the plugin loads.

`/referat-setup` installs `whisper-cpp` and `ffmpeg` through Homebrew, downloads
the 1 GB model into `~/.cache/nb-whisper/`, checks its checksum and runs a smoke
test. It takes a few minutes and you only do it once.

The second marketplace is there for
[`humanizer`](https://github.com/Floka-as/floka-marketplace/tree/main/humanizer),
which cleans up the Norwegian prose in the summary. It gets installed
automatically as a dependency, but Claude Code will not pull a plugin from a
marketplace you haven't added yourself.

There is nothing to clone, and no Python or HuggingFace token involved.

## Usage

```
/referat ~/Downloads/mote.m4a
```

Any format ffmpeg can read works: `m4a`, `mp3`, `wav`, `mp4`, `aiff`. Recordings
from Teams, Zoom, Meet or a phone left on the table are all fine.

You get three files next to the audio:

| File | Contents |
|---|---|
| `<name>.txt` | Raw transcript |
| `<name>.vtt` | Transcript with timestamps |
| `<name>-referat.md` | The finished summary |

An hour of audio takes roughly 10 to 20 minutes on an M1 Pro. The transcript is
cached, so running `/referat` again on the same file returns immediately.

## How it works

```
audio ──► ffmpeg ──► whisper.cpp + NB-Whisper ──► transcript
          16k mono     local, Metal-accelerated        │
                                                        ▼
                                        Claude Code reads it in-session
                                                        ▼
                                                   referat.md
```

Transcription is a local bash step. The summary is written by Claude Code, which
is already authenticated with your subscription, and that is why no API key
appears anywhere in the pipeline.

## Limitations

There is no speaker diarization. The summary records what was said rather than
who said it, unless names come up in the conversation. Adding diarization would
pull in Python, PyTorch and a gated HuggingFace model, which seemed like a bad
trade for a feature only some people need.

English product names come out badly. The model is trained on Norwegian, so
ordinary Norwegian is reliable but English loanwords and brand names usually
need correcting by hand.

Read the summary before you send it anywhere. Speech recognition still fails on
cross-talk and poor microphones. Passages the model was unsure about are marked
`[uklart]`, though that won't catch everything.

You also have to run it yourself. Nothing picks up meetings automatically, since
unattended runs would need API access and therefore a separate API key outside
your subscription.

macOS on Apple Silicon only, for now.

One practical note: microphone placement affects the result more than which
model you pick. A recording from a microphone on the table will transcribe
noticeably better than a laptop at the other end of the room.

## Credits

- [NB-Whisper](https://huggingface.co/NbAiLab/nb-whisper-large), National
  Library of Norway, Apache 2.0
- [whisper.cpp](https://github.com/ggerganov/whisper.cpp), MIT
- [humanizer](https://github.com/Floka-as/floka-marketplace/tree/main/humanizer),
  Floka AS, MIT

## License

MIT
