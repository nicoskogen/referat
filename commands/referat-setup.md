---
description: Engangsoppsett — installer whisper.cpp og last ned NB-Whisper-modellen
argument-hint: "[--full]"
allowed-tools: Bash
---

Kjør engangsoppsettet for referat-pluginen.

```
${CLAUDE_PLUGIN_ROOT}/scripts/setup.sh $ARGUMENTS
```

**Bruk `run_in_background: true`** — nedlastingen er på 1 GB (eller 2,9 GB med
`--full`) og går ofte over Bash-verktøyets timeout.

Skriptet installerer `whisper-cpp` og `ffmpeg` via Homebrew, laster ned
NB-Whisper til `~/.cache/nb-whisper/`, verifiserer kontrollsummen og kjører til
slutt en røyktest med den norske systemstemmen.

Vis utdataene til brukeren når jobben er ferdig. Skriptet er trygt å kjøre på
nytt: det hopper over det som allerede er på plass og gjenopptar en avbrutt
nedlasting. Hvis det feiler, vis feilmeldingen som den er — ikke prøv å
installere avhengighetene manuelt.
