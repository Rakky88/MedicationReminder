# Versiegeschiedenis

## V0.00.04 — 2026-08-15

- Voeg een blijvende medicatiestreak toe die alleen stijgt wanneer alle
  geplande innames van een kalenderdag zijn voltooid. Eén gemiste inname reset
  de huidige streak; medicatievrije dagen tellen niet en verbreken hem niet.
- Laat de streak vanaf kitten, pup of ei meelopen en toon hem compact op de
  huisdierkaart, inclusief de beste behaalde reeks wanneer die hoger is.
- Voeg in de dierenwinkel het tweede tabblad **Streak-items** toe. Alle
  beloningen blijven voor volwassen dieren zichtbaar, zijn gratis en worden
  blijvend claimbaar bij 40, 100, 150, 200, 250, 300, 365, 500, 750 en 1000
  dagen op basis van de beste streak.
- Voeg dertien nieuwe transparante beloningsassets toe: hoeden, brillen,
  outfits en speeltjes, met bij 365 dagen een complete vierdelige jubileumset.
- Pas elk streak-item automatisch aan de anatomie van alle vijf volwassen
  katten, vijf volwassen honden en de volwassen kip aan, zowel in de app als in
  notificatie-afbeeldingen.
- Voeg opslag-, reset-, undo-, permanente ontgrendel-, gratis aankoop-,
  shoptab- en 143 visuele dier-itemcombinatietests toe.

## V0.00.03 — 2026-08-15

- Voorkom dat gelijktijdige meldingssynchronisaties elkaars planning wissen en
  ruim een gedeeltelijk mislukte planning volledig op.
- Serialiseer lokale medicatie-, historie- en huisdiermutaties, zodat snelle
  dubbele tikken geen records, punten of instellingen kunnen overschrijven.
- Meld beschadigde lokale gegevens zonder ze stil als leeg te behandelen of bij
  de volgende wijziging te overschrijven.
- Weiger ongeldige opgeslagen tijden, datums en dosisstatussen in plaats van ze
  stil naar een ander tijdstip of naar `ingenomen` om te zetten.
- Herstel de dagindeling van week- en maandgrafieken rond zomer- en wintertijd.
- Laat een herstelbare fout bij notificatie-initialisatie niet langer de hele app
  vervangen door **Something went wrong**.
- Sla medicatiewijzigingen vóór een eventueel Android-systeemscherm op en
  ververs het hoofdscherm vóór de alarmplanning. Dit voorkomt verloren invoer
  en maakt opslaan merkbaar responsiever.
- Verbeter foutafhandeling bij opslaan, historie wissen, codes inwisselen,
  garderobe/shop, contact, delen en decoratieve huisdiergeluiden.
- Blokkeer aankopen van code- en supportersitems buiten hun bedoelde
  ontgrendelroute en valideer de categorie en catalogusprijs.
- Stop de continue huisdieranimatie wanneer het dier niets doet, om onnodige
  schermupdates en batterijverbruik te voorkomen.
- Laat releasebuilds hard falen als één van de vaste signinggegevens ontbreekt,
  zodat een niet-updatebare debug-ondertekende APK niet als release kan eindigen.
- Voeg een volledige app-audit met nog niet uitgevoerde verbeterideeën toe.

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
