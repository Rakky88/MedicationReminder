# Versiegeschiedenis

## V0.02.08 — 2026-08-22

- Meet alle twintig kattenspinsels opnieuw op hoge-bandenergie en spectrale
  vlakheid. Identificeer daarmee varianten 13–20 als de duidelijke ruisgroep en
  vervang precies die acht door passages uit Rehanjo's schone CC0-opname van een
  echt spinnende kat.
- Verlaag de hoge-bandenergie van de acht vervangen varianten van 1,42–2,93%
  naar 0,001–0,003% en leg maximale ruisgrenzen vast in de reproduceerbare
  geluidsaudit.
- Zet alle twintig spinsels exact gelijk op −18,5 LUFS. Dat is 1,5 dB luider dan
  V0.02.07, terwijl de luidste piek onder −1,5 dBTP blijft.
- Behoud twintig unieke bestanden en controleer opnieuw alle 120 diergeluiden,
  de volledige Flutter-analyse en 180 regressietests.

## V0.02.07 — 2026-08-22

- Laat een tik op het huisdier het hongergeluid gebruiken zodra het dier
  hongerpunten heeft. Alleen een volledig gevoed dier gebruikt bij aanraken het
  vrolijke geluid; de afzonderlijke geluidsinstellingen blijven gerespecteerd.
- Normaliseer alle twintig kattenspinsels naar een rustig maar duidelijk niveau
  rond −20 LUFS. Het gemeten onderlinge verschil is maximaal 0,3 LU en de pieken
  blijven begrensd, zodat geen variant plotseling veel harder klinkt.
- Maak de tweepassige loudness-normalisatie reproduceerbaar in de bestaande
  echte-kattengeluidgenerator en voeg een regressietest voor alle hongerfasen toe.
- Sorteer de zichtbare taalkeuzes alfabetisch zonder de opgeslagen taalvoorkeur
  te wijzigen. Voorkom daarnaast dat **Test notification** buiten de taalpopup
  loopt op een scherm van 320 pixels breed en rond de release af met 180
  geslaagde Flutter-tests en een foutloze analyse.

## V0.02.06 — 2026-08-22

- Controleer alle 120 diergeluiden afzonderlijk en vervang 48 varianten met
  opvallend achtergrondgeluid door schonere geluiden van hetzelfde diersoort:
  vijftien hondenhijgen, twintig kippentokjes en dertien kukeleku's.
- Voeg een reproduceerbare geluidsaudit toe die ieder bestand decodeert, de
  stilte-/geluidsverhouding meet en bewaakt dat elke verzameling twintig unieke,
  geldige fragmenten houdt. Werk de Android-geluidskanalen bij waar de
  kukeleku-bestanden zijn gewijzigd.
- Houd een onbeantwoorde dosis en de bijbehorende streak na middernacht open tot
  hetzelfde medicijnalarm op dezelfde tijd opnieuw afgaat. Een ander alarm sluit
  die dosis niet langer ten onrechte af.
- Herstel bij het laden recente, voortijdige automatische missers en
  streakbreuken uit V0.02.05. Een expliciet door de gebruiker gekozen
  **Inname gemist** blijft vanzelfsprekend ongewijzigd.
- Breid de regressieset uit naar 178 geslaagde tests, inclusief late innames,
  het herhalen van hetzelfde alarm en alle 120 unieke geluidsbestanden.

## V0.02.04 — 2026-08-19

- Toon voor een ingevoerde code die in de huidige app geen actie uitvoert de
  neutrale melding **Deze code heeft op dit moment geen effect** in plaats van
  te suggereren dat de codefunctie niet werkt.
- Voeg een afzonderlijke no-effectstatus en passende Engelse, Nederlandse,
  Duitse, Franse en Spaanse tekst toe. Behoud de bestaande afwijkende meldingen
  voor ontgrendelde items, ongeldige of al gebruikte codes en echte
  verbindingsfouten.

## V0.02.03 — 2026-08-19

- Maak het transparante logo links in de bovenbalk van het hoofdscherm een
  toegankelijke knop die **Over deze app** opent. Gebruik een tikvlak van 48 bij
  48 pixels en behoud het bestaande uiterlijk van het beeldmerk.
- Verwijder het losse informatie-icoon uit de rechterkant van de bovenbalk,
  zodat de appnaam en overige acties meer ruimte en een rustiger aanblik krijgen.

## V0.02.02 — 2026-08-19

- Centreer in het merkblok van **Over deze app** het transparante logo, de
  tweekleurige appnaam, maker met bouwjaar en versie elk op dezelfde verticale
  middenlijn. Plaats de twee informatiebadges overzichtelijk onder elkaar en
  behoud de uitlijning ook op compacte schermen.

## V0.02.01 — 2026-08-19

- Vervang op Android 12 en nieuwer de gekleurde tegel van het launcher-icoon
  tijdens het opstarten door het vrijstaande transparante beeldmerk. Toon
  daaronder een transparant, tweekleurig **Medication Reminder**-woordmerk dat
  aansluit op de merkweergave binnen de app.
- Laat de bovenbalk voortaan op alle appschermen geleidelijk van de gewone
  oppervlaktekleur naar de subtiele grijze scrollkleur en schaduw verlopen.
  Alle schermen gebruiken daarvoor dezelfde overgang over de eerste 80
  scrollpixels.

## V0.02.00 — 2026-08-19

- Start een nieuwe installatie voortaan expliciet in het Engels, ongeacht de
  telefoontaal. Blijf bij een update altijd de eerder gekozen taal uit de
  lokale appopslag gebruiken.
- Voeg volledige Duitse, Franse en Spaanse vertalingen toe naast Engels en
  Nederlands. Vertaal ook shopnamen, weekdagen, medicijnnamen in meldingen,
  actieknoppen, notificatiekanalen en de 500 wisselende dierherinneringen.
- Verwijder na een reproduceerbare runtime-audit 28 ongebruikte bron- en
  tussensprites uit de APK. Alle 361 werkelijk gebruikte groei-, outfit-,
  accessoire-, speelgoed- en Dragon-sprites blijven aanwezig; de onnodige
  verpakte afbeeldingsdata daalt met 11,03 MiB.

- Voeg naast het prullenbakje van iedere herinneringstijd een penknop toe om
  die tijd rechtstreeks te bewerken. Open de kiezer op de bestaande tijd en
  behoud daarbij de instelling voor vroegtijdig innemen.
- Geef **Over deze app** een nieuwe responsieve merkheader met een vrijstaand
  transparant logo, tweekleurige appnaam, subtiele merkkleuren en compacte
  badges voor maker, jaar en versie. Gebruik hetzelfde transparante beeldmerk
  overal waar het logo binnen de app wordt getoond.
- Verwerk de afgeronde V12-garderobeselectie in een gerichte V13-eindcontrole.
  Til de Beagle-kroon op, verbreed beide geselecteerde teckelkronen, laat de
  kippenlauwerkrans iets zakken, maak de drie kattenbrillen breder en lijn de
  twee Beagle-brillen en de grotere eierbril opnieuw horizontaal uit.
- Rond de V13-selectie af met een minimale V14-hercontrole: verschuif alleen de
  ronde bril van de grijze kat en tuxedo-kat vijf pixels naar links.
- Vereenvoudig de tien Dragon-kostuums voor katten en honden naar V6: behoud
  de natuurlijke voorpoten maar verwijder de geforceerde ronde pootgaten en
  laat de groene schubben bij de schouders doorlopen. Behoud voor het kuiken
  exact de goedgekeurde V5-bron. Geef de millenniumkip daarnaast echte
  zwart-gouden vleugelopeningen.

## V0.01.03 — 2026-08-19

- Verwijder het contactgedeelte en de knop naar het contactformulier uit het
  informatiescherm.
- Laat de staafdiagram in de geschiedenis de ingenomen en gemiste segmenten
  daadwerkelijk over de volle balkbreedte in duidelijk groen en rood tekenen.
- Open de Ko-fi-knop rechtstreeks in het compacte fooiformulier en toon op het
  informatiescherm met het officiële PayPal-monogram dat de betaling via PayPal
  verloopt.
- Rond de volledige V9-garderobecontrole af en herstel alle 55 geselecteerde
  dier-itemcombinaties afzonderlijk. Maak de twee fezzen smaller, geef de vijf
  hondenhoeden een hogere tovenaarspunt en lijn de gemarkeerde brillen, kronen,
  petten, lauwerkransen en strikjes opnieuw op hun eigen kop of hals uit.
- Vervang de millennium- en Dragon-sprites door anatomische versies waarin de
  natuurlijke poten en vleugels door gesloten, donker omlijnde armgaten lopen,
  met de achterste stofrand achter de ledematen. Gebruik de V10-selectie voor
  een lege, gerichte V11-hercontrole van de 50 overgebleven combinaties.
- Verplaats alle losse teckelaccessoires 21 pixels naar de gemeten oogmiddellijn
  en het strikje 12 pixels naar de halsmiddellijn. Maak de hondenwizardhoed
  smaller en plaats de rand boven de ogen zonder de punt af te snijden.
- Gebruik op het hoofdscherm het strak uitgesneden transparante beeldmerk zonder
  groen/blauw vlak en geef de volledige appnaam een vet, tweekleurig Flutter-
  opschrift dat ook op een smal scherm automatisch passend blijft.
- Laat de grijze kleur en subtiele schaduw van de bovenbalk geleidelijk over de
  eerste 80 scrollpixels verschijnen in plaats van plotseling in te schakelen.
- Vervang **Reminders enabled** in het medicatieformulier door de standaard
  uitgeschakelde optie **Notifications only**. Ingeschakeld gebruikt ook het
  eerste medicatiemoment het notificatiekanaal; uitgeschakeld blijft het echte
  alarmkanaal gebruiken. De schakelaar op de hoofdpagina blijft herinneringen
  voor de medicatie volledig aan- of uitzetten.

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
