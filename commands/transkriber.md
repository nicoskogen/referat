---
description: Transkriber et lyd- eller videoopptak til referat, ren tekst eller undertekster
argument-hint: <sti-til-fil>
allowed-tools: Bash, Read, Write, Skill, AskUserQuestion
---

Transkriber **$1**.

## Steg 1 — finn ut hva brukeren vil ha ut

Tre resultater er mulige:

| Modus | Gir | Passer til |
|---|---|---|
| `referat` | `<navn>-referat.md` | Møtereferat med beslutninger og todos |
| `tekst` | `<navn>.txt` og `.vtt` | Ren transkripsjon, ingen tolkning |
| `srt` | `<navn>.srt` | Undertekster til videoredigering |

**Sier forespørselen allerede hvilken det er, ikke spør.** «Lag undertekster av
dette» er `srt`, «bare transkriber» er `tekst`, «lag referat» er `referat`.
Bruk `AskUserQuestion` bare når det faktisk er uklart, for eksempel når
kommandoen kjøres med en filsti og ingenting annet.

Modusen må velges **før** transkriberingen starter. Undertekster krever en annen
segmentering enn løpende tekst, så et feilvalg betyr at hele jobben må kjøres om
igjen.

## Steg 2 — transkriber

```
${CLAUDE_PLUGIN_ROOT}/scripts/transcribe.sh "$1" --modus <modus>
```

**Bruk `run_in_background: true`.** En times opptak tar 10–20 minutter, som er
lenger enn Bash-verktøyets maksimale timeout. En forgrunnskjøring blir drept
midtveis.

Video går rett inn. `.mp4`, `.mov` og andre videoformater trenger ingen
lydeksport først, så ikke be brukeren om å konvertere noe.

Si fra at jobben er i gang og omtrent hvor lang tid den tar, og gå videre når
den melder seg ferdig. Ikke poll etter den.

Skriptet skriver stien til resultatet på stdout. Feiler det, vis feilmeldingen
som den er og stopp. Meldingene sier allerede hva som må gjøres, som regel at
`/transkriber-setup` ikke er kjørt. Ikke forsøk å transkribere på andre måter og
ikke installer noe på egen hånd.

## Steg 3 — etterarbeid, avhengig av modus

### `tekst` og `srt`
Ingen etterbehandling. Fortell hvor filen ligger og hvor lang den er.

Ved `srt`: nevn at den kan importeres rett i redigeringsprogrammet, og at
linjene er delt på omtrent 42 tegn etter kringkastingsstandard.

**Ikke språkvask undertekster eller ren transkripsjon.** Begge skal gjengi det
som faktisk ble sagt. Retter du opp muntlig språk, stemmer ikke lenger teksten
med lyden.

### `referat`
1. Les transkripsjonen og bruk ferdigheten `moetereferat` til å strukturere den.
2. Kjør ferdigheten `humanizer` over utkastet. Fire ting skal ikke røres:
   - **Ingen fakta endres.** Navn, datoer, tall og beslutninger står som de står.
   - **`[uklart]`-markeringer blir stående.** De dokumenterer hvor
     talegjenkjenningen sviktet.
   - **Forbehold beholdes.** De uttrykker reell usikkerhet om hva som ble sagt.
   - **Strukturen beholdes.** Overskrifter og tabeller er riktig form for et
     referat, ikke AI-preg.
3. Skriv resultatet til `<fil uten filendelse>-referat.md`.

Er `humanizer` ikke installert, hopp over punkt 2 og nevn det.

## Steg 4 — oppsummer

Fortell hvor filen ligger. Ved referat: hvor mange beslutninger og todos du
fant. Gjorde lydkvaliteten deler av opptaket uleselig, si det — ikke skjul det
bak et pent formatert dokument.
