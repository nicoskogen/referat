---
description: Transkriber et lydopptak og skriv et strukturert norsk møtereferat
argument-hint: <sti-til-lydfil>
allowed-tools: Bash, Read, Write, Skill
---

Lag et møtereferat fra lydfilen: **$1**

## Steg 1 — transkriber

Kjør transkriberingsskriptet. **Bruk `run_in_background: true`.** En times møte
tar 15–25 minutter, som er lenger enn Bash-verktøyets maksimale timeout — en
forgrunnskjøring vil bli drept midtveis.

```
${CLAUDE_PLUGIN_ROOT}/scripts/transcribe.sh "$1"
```

Si til brukeren at transkriberingen er i gang og omtrent hvor lang tid det tar,
og gå så videre når jobben melder seg ferdig. Ikke poll etter den.

Skriptet skriver stien til transkripsjonen på stdout og framdrift på stderr.
Hvis det avslutter med feil: vis feilmeldingen som den er og stopp. Meldingene
sier allerede hva som må gjøres (som regel: kjør `/referat-setup`). Ikke forsøk
å transkribere på andre måter og ikke installer noe på egen hånd.

## Steg 2 — skriv referatet

Les transkripsjonen og bruk ferdigheten `moetereferat` til å strukturere den.
Den definerer formatet — følg den framfor å finne på din egen struktur.

Skriv resultatet til `<lydfil uten filendelse>-referat.md`, altså ved siden av
lydfilen. Overskriv uten å spørre hvis filen finnes fra før; transkripsjonen er
kilden, referatet er avledet.

## Steg 3 — språkvask

Kjør ferdigheten `humanizer` over utkastet før du lagrer. Referatet er
AI-skrevet norsk prosa, og den norske delen av `humanizer` retter nettopp det
som lekker gjennom: anglisismer og direkte oversettelser, særskriving,
`sin`/`hans`, engelsk stor forbokstav i måneder og ukedager, sitattegn (`«…»`),
og formatering av tall, datoer, klokkeslett og prosent (`3,14`, `8. mai 2026`,
`kl. 14.30`, `20 %`).

**Fire ting skal ikke røres.** Et referat er et saksdokument, ikke en tekst som
skal lyde godt:

1. **Ingen fakta endres.** Navn, datoer, tall, frister og beslutninger står som
   de står. Språkvask er en formvask, ikke en omskriving.
2. **`[uklart]`-markeringer blir stående.** De er ikke en språklig svakhet — de
   er dokumentasjon på at talegjenkjenningen sviktet akkurat der.
3. **Forbehold beholdes.** `humanizer` fjerner vanligvis nølende formuleringer.
   Her uttrykker de reell usikkerhet om hva som faktisk ble sagt, og å stryke
   dem gjør referatet mer skråsikkert enn kildematerialet tillater.
4. **Strukturen beholdes.** Overskrifter, tabeller og punktlister er riktig form
   for et referat, ikke AI-preg. Ikke skriv dem om til løpende prosa.

Er `humanizer` ikke installert, hopp over steget og nevn det i oppsummeringen.
Referatet er fullt brukbart uten, bare språklig røffere.

## Steg 4 — oppsummer

Fortell brukeren hvor referatet ligger, og gi antall beslutninger og todos du
fant. Hvis lydkvaliteten gjorde deler av transkripsjonen uleselig, si det —
ikke skjul det bak et pent formatert dokument.
