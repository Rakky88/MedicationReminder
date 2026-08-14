# Versiegeschiedenis

## V0.00.02 — 2026-08-14

- Zorg dat het dynamisch gebruikte Android-notificatie-icoon en de alarmsounds
  niet uit releasebuilds worden verwijderd.
- Herstel daarmee de opstartfout van de eerste openbare Android-release.
- Verwijder overlappende wekelijkse Android-reservemeldingen die soms tegelijk
  met de datumgebonden dosisnotificatie afgingen.
- Houd voldoende marge onder Android's alarmenlimiet en voorkom dat een
  leverancierslimiet de app of herstartontvanger kan laten crashen.
- Wis oude native vervolgalarms vóór een nieuwe planning, zodat een eerder
  afgebroken synchronisatie zichzelf bij de volgende Save kan herstellen.

## V0.00.01 — 2026-08-14

- Vaste versieaanduiding toegevoegd aan **Over deze app**.
- Een vroeg als ingenomen afgevinkt alarm wordt voor die dag overgeslagen; ook
  de bijbehorende vervolgmeldingen worden gestopt.
- Geheime `DOCTORWHO`-redeemset toegevoegd met fez, strikje, outfit en
  TARDIS-speeltje voor alle volwassen huisdieren.
- Vaste Android-downloadlink, deelknop en download/updateknop toegevoegd.
- Definitieve app-ID, release-signing en automatische GitHub Releases ingericht.
