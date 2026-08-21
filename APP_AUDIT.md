# App-audit — V0.02.06

Datum: 22 augustus 2026
Status: code-, alarm- en visuele regressie-audit afgerond; onderstaande
verbeterideeën zijn **niet geïmplementeerd**.

## In V0.02.06 gerepareerd en gecontroleerd

- Alle 120 gebundelde diergeluiden zijn gedecodeerd, gemeten en per soort als
  luistermontage beoordeeld. 48 rumoerige varianten zijn vervangen door schonere
  echte diergeluiden van hetzelfde soort; iedere verzameling houdt twintig
  unieke fragmenten.
- Een geplande dosis blijft voortaan ook na middernacht onbeantwoord tot hetzelfde
  medicijnalarm op dezelfde tijd opnieuw afgaat. Daardoor kan een geldige late
  **Taken** de eerdere geplande dag en streak nog correct afronden.
- Recent door V0.02.05 te vroeg opgeslagen automatische missers en
  streakbreuken worden veilig herberekend. Handmatig gemarkeerde gemiste innames
  worden niet gewijzigd.

## In V0.02.05 gerepareerd en gecontroleerd

- Lokale telefoontijden worden via een volledige IANA-aliaslaag aan de compacte
  tijdzonedatabase gekoppeld. Daardoor blijft een medicatiemoment ook in zones
  zoals `Europe/Amsterdam` correct over zomer- en wintertijd.
- Basisalarmen en snoozes gebruiken exact geplande Android-alarmen en
  `USAGE_ALARM`; genegeerde vervolgmeldingen gebruiken `USAGE_NOTIFICATION`.
  De gekozen huisdiergeluiden blijven per route behouden en zonder diergeluid
  gebruikt Android het eigen alarm- of notificatiegeluid.
- Iedere snooze is opnieuw exact tien minuten. Negeren geeft standaard drie
  meldingen met vijf minuten ertussen; alleen de expliciete herhaalinstelling
  laat die keten doorlopen. Die instelling staat voor nieuwe profielen en zonder
  huisdier standaard uit.
- **Taken** en **Not taken** annuleren alle plugin- en native onderdelen van de
  betreffende dosissessie. Appstart, een tik op het dier en voeren spelen het
  huisdiergeluid als gewone media af.
- Alle 1.980 combinaties van elf huisdieren, twintig outfits en negen
  hoofd-/halsaccessoires zijn automatisch begrensd en in drie aanvullende
  visuele controlerondes bekeken.

## Bekeken onderdelen

- Appstart, foutscherm, taalkeuze en navigatie
- Medicijnen, schemawijzigingen, vroege inname, gemiste doses en undo
- Lokale opslag, migraties, beschadigde data en gelijktijdige acties
- Android- en iOS-notificatieplanning, snooze, vervolgmeldingen en tijdzones
- Geschiedenis en week-, maand-, jaar- en totaaloverzichten
- Huisdiergroei, honger, geluid, spelen, shop en garderobe
- Speciale codes, waaronder de verborgen ingebouwde outfitset
- Contactrelay, externe links en de openbare download/updateknop
- Android-manifest, signing, GitHub-releaseworkflow en assets
- Statische analyse, Flutter-tests, package-status, builds en echte Android-appdata

## In V0.00.03 gerepareerd

- Meldingssynchronisaties lopen nu strikt na elkaar. Een start-, hervat- en
  opslaanactie kan daardoor niet meer tussendoor elkaars alarmen wissen.
- Als Android of iOS slechts een deel van een nieuwe planning accepteert, wordt
  die halve planning opgeruimd. De app laat dus niet ongemerkt een willekeurige
  subset herinneringen actief na een gemelde planningsfout.
- Medicatie-, historie- en huisdiermutaties zijn geserialiseerd. Snelle dubbele
  tikken kunnen geen dubbele dosis, dubbele aankoop, dubbel puntenaantal,
  botsende IDs of verloren wijzigingen meer veroorzaken.
- Beschadigde medicatie-, historie- of huisdierdata wordt als fout gemeld en
  blijft bewaard. Zij wordt niet langer stil als een lege lijst of een nieuw
  huisdier behandeld en daarna overschreven.
- Ongeldige opgeslagen tijden zoals `25:90`, onmogelijke datums en onbekende
  dosisstatussen worden geweigerd in plaats van genormaliseerd of als
  **ingenomen** geïnterpreteerd.
- Kalendergrafieken gebruiken kalenderdagen in plaats van verstreken uren. Dit
  voorkomt een ontbrekende of verkeerd ingedeelde dag rond zomer-/wintertijd.
- Een herstelbare fout tijdens notificatie-initialisatie blokkeert de lokale
  medicatiegegevens en de rest van de app niet meer met **Something went wrong**.
- Opslagfouten en fouten bij historie wissen, wegvegen, codes, contact, delen,
  shop, garderobe en huisdierinstellingen worden opgevangen; laadindicatoren en
  knoppen blijven daarbij niet vaststaan.
- Een medicatiewijziging wordt nu opgeslagen voordat Android eventueel naar
  een systeemscherm voor alarmtoegang gaat. De invoer gaat daardoor niet meer
  verloren als de app daar wordt afgesloten; het scherm ververst bovendien al
  voordat de relatief zware alarmplanning wordt opgebouwd.
- Een reeds opgeslagen dosis blijft zichtbaar als alleen de afgeleide
  huisdierupdate of het direct sluiten van een notificatie mislukt. De volgende
  reconciliatie/synchronisatie kan dit herstellen.
- Undo werkt in een herstelbare volgorde: eerst afgeleide huisdierstatus, daarna
  de canonieke dosislog.
- Code-items kunnen niet via de gewone shoprepository worden gekocht. De vier
  voormalige supportersitems zijn gewone betaalde shopitems; categorie en prijs
  moeten voor iedere aankoop exact met de catalogus kloppen.
- Het ontbrekende generieke cataloguspad van de Doctor-outfit verwijst nu naar
  een werkelijk bestaand asset; alle uitgeruste varianten bleven intact.
- Decoratief huisdiergeluid kan een medicatieactie niet meer onderbreken en de
  huisdierkaart animeert alleen wanneer er werkelijk activiteit is.
- Een releasebuild zonder alle vier vaste signingwaarden stopt nu met een
  duidelijke fout. Daardoor kan geen debug-ondertekende APK per ongeluk als
  niet-updatebare openbare release worden gepubliceerd.

## Open beperkingen en handmatige controles

Deze punten zijn niet automatisch als fout te bewijzen en zijn niet gewijzigd:

1. **Alarmen op meerdere echte toestellen.** Test nog op Samsung, Pixel en een
   tweede Oppo/OnePlus met batterijbesparing aan en uit, na herstart, na een
   tijdzonewissel en met exact-alarmtoegang geweigerd. Fabrikanten behandelen
   achtergrondalarmen verschillend.
2. **Begrensde Android-planning.** De app plant maximaal 144 toekomstige
   dosisinstanties om onder veelvoorkomende limieten van 500 Android-alarmen te
   blijven. Bij veel schema's of als de app maandenlang niet wordt geopend,
   raakt die horizon eerder op. Openen of bewerken vult hem opnieuw aan.
3. **Tijdzonewijziging zonder appstart.** Bij hervatten wordt alles in de nieuwe
   lokale tijdzone gepland. Een toestel dat van tijdzone wisselt terwijl de app
   daarna niet wordt geopend, kan bestaande datumalarmen nog volgens de oude
   absolute tijd uitvoeren.
4. **iOS niet fysiek geverifieerd.** De iOS-code respecteert de limiet van 64
   geplande notificaties, maar een Mac, Xcode, signing en echt iOS-toestel zijn
   nodig voor eindcontrole.
5. **Geen herstel na verwijderen of toestelverlies.** Updates met dezelfde
   app-ID en signingkey behouden data, maar verwijderen/wissen heeft zonder
   export of gecontroleerde back-up geen herstelpad.
6. **Back-up- en encryptiebeleid.** Medicatie staat in de afgeschermde lokale
   appopslag, maar niet in een eigen versleutelde database. Androids standaard
   back-upgedrag en het gewenste privacybeleid moeten vóór brede publicatie
   bewust worden gekozen en beschreven.
7. **Openbare code is niet geheim.** De app geeft in de UI geen hint over de
   ingebouwde code, maar deze blijft vindbaar in de openbare broncode/APK.
   Alleen servervalidatie kan toekomstige campagnecodes echt
   geheim, intrekbaar en wereldwijd eenmalig maken.
8. **Contact en externe steun.** De contactrelay is voorbereid maar pas actief
   met een endpoint en serversecrets. De Ko-fi-link opent extern en is bewust
   niet gekoppeld aan digitale beloningen in de app.
9. **Native regressietests.** Dart-/widgetlogica is uitgebreid getest; voor de
   Kotlin AlarmManager-laag ontbreken nog Robolectric/instrumentatietests voor
   reboot, grensalarm, snooze en package-update.
10. **Packageversies.** Alle directe packages gebruiken de nieuwste onder deze
    Flutter-SDK oplosbare versies. `intl 0.20.3` bestaat, maar Flutter houdt deze
    projectcombinatie nog op `0.20.2`; niet forceren zonder SDK-upgrade.
11. **Cloudflare-testomgeving.** De relay-validatietests konden op deze pc niet
    worden uitgevoerd omdat Node.js niet geïnstalleerd is. De relay staat in de
    huidige APK bovendien niet aan.

## Aanbevolen verbeteringen — niet geïmplementeerd

| Prioriteit | Idee | Positief effect | Belangrijk aandachtspunt |
|---|---|---|---|
| Hoog | Versleutelde export/import met schema, checksum en herstelpreview | Veilige verhuizing naar een nieuw toestel en herstel na verwijderen | Test terugzetten vanuit iedere oudere appversie; nooit stil bestaande data vervangen |
| Hoog | Scherm **Herinneringscontrole** | Toont notificatierecht, exact-alarmstatus, batterijbeperking, laatste succesvolle sync, planningshorizon en een testknop | Geef concrete toestelspecifieke uitleg zonder te beloven dat Android elk alarm exact uitvoert |
| Hoog | Refill-/voorraadbeheer per medicijn | Waarschuwt tijdig wanneer tabletten bijna op zijn | Houd voorraadcorrecties simpel en presenteer dit niet als medisch advies |
| Hoog | Tijdelijke pauze en schema-uitzonderingen | Vakantie, ziekenhuisopname of tijdelijke kuuronderbreking zonder geschiedenis te vervuilen | Bewaar begin/einde expliciet zodat geen fantoommissers ontstaan |
| Hoog | Toegankelijkheidsronde | Nederlandse semantieklabels, grote tekst, schermlezer, kleurcontrast en **verminder beweging** | Test minimaal op 200% tekstschaal en TalkBack/VoiceOver |
| Midden | Veilige updatecontrole via een klein ondertekend versiebestand | Laat zien wanneer een nieuwere GitHub-release bestaat en opent daarna de bestaande downloadknop | Geen stille APK-installatie; toon herkomst, versie en checksum |
| Midden | CSV/PDF-export van geselecteerde geschiedenis | Gebruiker kan een eigen overzicht delen met arts of apotheek | Alleen na expliciete keuze; verberg standaard medicijnnamen en andere gevoelige data |
| Midden | Tijdzone-/rebootreceiver die alleen de planningshorizon vernieuwt | Minder afhankelijk van het opnieuw openen van de app na reizen of een OS-wijziging | Alarmenlimiet, gelijktijdigheid en OEM-gedrag opnieuw op echte toestellen testen |
| Midden | Privacyinstelling voor Android-back-up en optionele appvergrendeling | Gebruiker kiest bewust tussen herstelgemak en maximale lokale afscherming | Leg biometrie, herstel en sleutelverlies helder uit |
| Midden | Crashdiagnose die lokaal exporteerbaar is | Een gebruiker kan bij een fout technische status delen zonder medicatie-inhoud | Standaard lokaal en geredigeerd; geen stille analytics of gezondheidsdata uploaden |
| Laag | Thuisschermwidget met alleen volgende tijd | Sneller zien wat het volgende moment is | Medicijnnaam standaard verbergen op vergrendeld scherm/widget |
| Laag | Vastgepinde GitHub Actions en Node-lockfile voor de relay | Reproduceerbaardere en strengere supply-chaincontrole | Onderhoud automatisch laten melden wanneer pins verouderd zijn |

## Publicatieadvies

Voor een kleine privétest is de huidige APK bruikbaar. Voor bredere verspreiding
zijn vooral een herstelbare export/import, een expliciet back-up/privacybeleid,
multi-vendor alarmtests en een herinneringsdiagnosescherm de waardevolste
volgende stappen. Deze audit heeft die functies bewust niet toegevoegd.
