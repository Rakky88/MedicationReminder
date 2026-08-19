# Versiegeschiedenis

## V0.01.02 — 2026-08-19

- Toon op het hoofdscherm het app-logo naast een automatisch passend, volledig
  zichtbaar opschrift **Medication Reminder**.
- Verkort **Medication streak** naar **Streak** en verwijder de overbodige
  privacyuitleg op het hoofdscherm.
- Verwijder de twee lange toelichtingen uit het medicatieformulier en laat in de
  huisdierinstellingen alleen de titels van de drie geluidsschakelaars staan.
- Speel het eerste geplande medicatiealarm op Android via afzonderlijke
  alarmkanalen af, met het diergeluid of anders het standaard alarmgeluid. Houd
  vervolg- en snoozemeldingen op de notificatiekanalen.
- Speel miauwen, spinnen en de equivalente hond- en kipgeluiden in de geopende
  app via het gewone mediakanaal af.
- Voeg onderaan **Over deze app** een rechtstreekse Ko-fi-knop toe voor
  `https://ko-fi.com/rgroot88` en verwijder de oude storesteun-placeholder.
- Maak de voormalige supporterskroon, -bril, -cape en het supportershart als
  gewone winkelitems koopbaar voor respectievelijk 850, 650, 1100 en 700 happy
  points.
- Verhoog het Android-buildnummer naar 6 voor updates over V0.01.01.

## V0.01.01 — 2026-08-15

- Zet het Android-buildnummer op 5, zodat deze APK als update over V0.00.04
  geïnstalleerd kan worden.
- Herstel de door de gebruiker geselecteerde pasvormen van hoeden, brillen en
  strikjes per volwassen diervariant. De fez is op de geselecteerde honden en
  kip duidelijk smaller en behoudt zijn lage, brimloze vorm.
- Verwijder het storende uitstekende rechter brilsteeltje uit de klassieke
  brillen en plaats de geselecteerde brillen opnieuw op de gemeten ooglijn.
- Vernauw en verplaats de geselecteerde petten, kronen, tovenaarshoeden,
  lauwerkransen en streakpetten zonder eerder goedgekeurde varianten te wijzigen.
- Vervang de Dragon-modebeelden voor alle vijf katten, vijf honden en de kip:
  natuurlijke voorpoten of vleugels komen nu zichtbaar door de kostuumopeningen.
- Maak Dragon mode alleen in de jonge/middelste levensfase als standaard
  uitgeschakelde instelling zichtbaar en gebruik daar per dier een complete,
  passende sprite voor.
- Houd alle streak-items voor volwassen dieren altijd zichtbaar in het tweede
  shoptabblad, maar vergrendel gratis claimen tot de vereiste streak is gehaald.
- Gebruik generieke meldingstekst en -afbeelding wanneer nog geen huisdier is
  gekozen, en hernoem de garderobegroep **Bow ties** naar **Ties**.
- Leg de vaste tik-en-selecteer-review voor nieuwe assets vast, voeg de
  Dragon-pagina weer aan de emulatorcontrole toe en voeg een script toe dat een
  geëxporteerde selectielijst als controlesheets rendert.

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
