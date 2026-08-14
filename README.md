# Medication Reminder

Een privacyvriendelijke Flutter-app voor eenvoudige, ADHD-vriendelijke medicatieherinneringen. De app bewaart medicijnen, schema's en innamegeschiedenis lokaal op het apparaat.

## Huidige status — V0.00.01

De ondertekende Android-releasebuild werkt. De meest recente geverifieerde APK
staat na een build in:

`medication_reminder_app/build/app/outputs/flutter-apk/app-release.apk`

Geverifieerd met Flutter 3.44.9 en Dart 3.12.2:

- `flutter analyze`: geen issues
- `flutter test`: 109 tests geslaagd
- `flutter build apk --release`: geslaagd en met de vaste releasekey ondertekend

De vaste openbare Android-downloadlink is:

<https://github.com/Rakky88/MedicationReminder/releases/latest/download/MedicationReminder.apk>

Via **Over deze app** kan die link worden gekopieerd of direct worden geopend
om de app te installeren of over een oudere, gelijk ondertekende versie bij te
werken.

## Functionaliteit

- Meerdere medicijnen toevoegen, bewerken, pauzeren en verwijderen
- Optionele dosering of instructie per medicijn
- Meerdere herinneringstijden en vrij te kiezen weekdagen
- Tijdzone- en zomertijdvriendelijke wekelijkse notificaties
- Herplannen bij appstart en wanneer de app na een tijdzonewijziging terugkomt
- Notificatieacties voor **10 min uitstellen** (altijd links) en **App openen**
  (altijd rechts), met wisselende accentkleur. Een inname kan alleen bewust in de app worden
  geregistreerd; na openen staat daarvoor direct een opvallende snelkaart klaar.
- Iedere melding gebruikt uitsluitend de gekozen app-taal (Nederlands of Engels).
- Op Android volgt bij geen reactie na vijf minuten een nieuwe melding. Met de
  miauwschuif ingeschakeld blijft de keten na drie onbeantwoorde meldingen iedere
  vijf minuten terugkomen. Snoozen heeft een aparte teller; vanaf de derde snooze
  hervat de escalatie dan na vijf minuten. Innemen of overslaan in de app stopt
  alleen de bijbehorende dosisketen.
- Bij openen na een alarm staan twee duidelijk verschillende keuzes klaar:
  groen **Ingenomen** en rood **Inname gemist**. Voor gemist volgt nog een
  uitleg en bevestiging. Na afhandeling verdwijnen innemen, gemist en snooze
  tot het volgende alarm.
- Een onbeantwoord alarm wordt automatisch als gemist geregistreerd zodra een
  volgend alarm afgaat. De oude snooze- en vijfminutenketen wordt dan beëindigd.
- Doses registreren als ingenomen of gemist
- Bescherming tegen per ongeluk dubbel registreren
- Undo na een registratie
- Lokale geschiedenis, netjes gegroepeerd per dag, met groene innames en rode
  gemiste innames, individuele verwijdering en bevestigd volledig wissen. Wissen
  of wegvegen verbergt alleen de historieweergave; de onderliggende dosisstatus
  blijft veilig bewaard en kan daardoor niet opnieuw als gemist terugkomen.
- Innamegrafieken voor een vrij te kiezen week, maand of jaar en voor de volledige
  geschiedenis
- Nederlands en Engels, inclusief opgeslagen taalvoorkeur
- Donker thema via de systeeminstelling
- Per medicijn staat een privacyschakelaar om de medicijnnaam wel of niet in
  meldingen te tonen. Bestaande en nieuwe medicijnen blijven standaard verborgen.
- Migratie van de oude lijst met losse tijdstempels

### Optioneel medicatiehuisdier

- Adopteer optioneel een kat (standaard) of een van vijf honden en geef het dier
  een naam. Er zijn vijf katten, waaronder een volledig zwarte kat met een klein
  wit befje.
- Nadat een kat volwassen is geworden en een nieuw thuis krijgt, wordt de kip
  als derde soort ontgrendeld. Zij groeit van ei naar kuiken en volwassen kip.
- Het huisdier blijft bovenaan het hoofdscherm zichtbaar en toont wat het doet.
- Een geldige geplande inname voert het dier; dezelfde dosis kan nooit twee
  beloningen geven. Extra medicatie nemen helpt het spel dus niet.
- Een kat spint na een geregistreerde inname en miauwt rond medicatietijd; een
  hond hijgt of blaft en een kip tokkt of kraait op diezelfde momenten.
- Ieder van die zes gedragstypen heeft twintig unieke, goed hoorbare fragmenten
  uit echte CC0-/publiekedomein-opnamen. De app gebruikt per dier en stemming een
  afzonderlijk geschudde verzameling: alle twintig varianten komen langs voordat
  een geluid opnieuw mag worden gekozen. Ook Android-meldingen kunnen willekeurig
  kiezen uit twintig miauwen, blaffen of kukeleku-geluiden.
- Elk dier groeit na 14 succesvolle medicatiedagen naar de jonge fase en na 60
  succesvolle medicatiedagen naar de volwassen fase. Meerdere geldige
  innames op dezelfde kalenderdag leveren samen maximaal één groeidag op. De
  interne groeipunten en voortgangsbalk zijn niet zichtbaar voor de gebruiker.
- Gemiste innames maken de kat geleidelijk hongeriger. Een handmatig gemiste
  inname telt meteen; een onbeantwoord moment telt zodra het volgende alarm
  afgaat (met twee uur als terugvalcontrole). Elke volgende geldige
  inname herstelt precies één hongerstap. Honger is begrensd op vijf stappen.
- Bij elke hongerstap wordt de kat geleidelijk smaller en minder kleurrijk. Bij
  herstel wordt de lichaamsbouw per geldige inname weer één stap gezonder, tot
  de normale bouw volledig terug is. De smallere, fletsere bouw en ribaccenten
  zijn ook zichtbaar in de kattenafbeelding van Android-meldingen.
- Android-meldingen tonen het actuele huisdier, honger en aangeklede attributen. Ze
  wisselen tussen 24 opvallend verschillende landschappen en patronen, twintig
  miauwen, verschillende kaders en schalen, sterke accentkleuren en 500 korte,
  willekeurige teksten in de gekozen taal. De snoozeknop blijft links en openen
  blijft rechts. Ook zonder huisdier worden de visuele thema's gebruikt. Het dier
  blijft steeds horizontaal gecentreerd. Android bepaalt
  zelf of een systeemmelding van boven, onder of een zijkant animeert; een app
  kan die richting niet betrouwbaar afdwingen.
- Alle 500 meldingsteksten hebben een geteste maximale lengte. Een Android-
  vervolgherinnering plakt niet langer een tweede volledige zin achter de
  huisdierzin, zodat de boodschap ook in de compacte melding volledig leesbaar
  blijft. Een optioneel zichtbare medicijnnaam valt onder dezelfde lengtegrens.
- Alleen vanaf de volwassen fase verdient en toont het huisdier happy points;
  daarvoor zijn ook Shop en Garderobe volledig verborgen. Per kalenderdag is 30
  punten beschikbaar, verdeeld over alle ingestelde alarmmomenten van die dag.
  Een alarm op tijd levert zijn volledige aandeel op; dat aandeel daalt lineair
  tot nul na 30 minuten. Bij twee alarmen is dit dus maximaal 15 per alarm en
  één punt minder per twee minuten vertraging.
- Volwassen dieren krijgen een shop met hoeden/petten, brillen,
  drie outfits en drie speeltjes. Het goedkoopste item kost 210 punten (een
  perfecte week). Per categorie kan steeds maximaal één item zichtbaar zijn.
  Elke outfit gebruikt een afzonderlijk, anatomisch passend eindbeeld voor alle
  vijf volwassen katten, vijf volwassen honden en de volwassen kip; stof, hals,
  poten en vleugels vallen daardoor niet meer als een universele laag over het
  verkeerde lichaam. Ook iedere hoed en bril gebruikt per volwassen diervariant
  een eigen, op schedel en ooglijn passende weergave; de originele dier- en
  outfitafbeeldingen blijven daarbij ongewijzigd. Een uitgerust item blijft zichtbaar op alle dierenschermen en
  in nieuwe meldingen. Een gekocht item krijgt een duidelijke groene status
  **Gekocht** en kan daarna in de garderobe worden gebruikt of afgedaan. Shop en
  garderobe staan compact naast elkaar; de actuele dierpreview blijft in de
  garderobe tijdens het scrollen zichtbaar. Na de kipontgrendeling verschijnen
  ook een strohoed, eierbril, tuinbroek en maïsspeeltje, bruikbaar door alle dieren.
- Hoeden en brillen worden vanuit de ongewijzigde bronafbeeldingen per volwassen
  diervariant apart in breedte, hoogte en ankerpunt afgeleid. Alle 110 combinaties
  zijn op volledige resolutie gecontroleerd op de normale sprites en op een
  aangeklede variant. De automatische regressietest bewaakt nu behalve canvas,
  centrering en ooglijn ook een minimale hoofdvullende breedte, zodat een hoed of
  bril bij een latere wijziging niet ongemerkt weer te klein kan worden.
- Een volwassen huisdier wil op twee of drie volledig willekeurige momenten per
  kalenderdag spelen. De momenten worden eenmaal per dag gegenereerd, liggen
  minimaal 33 minuten uit elkaar en blijven opgeslagen. Precies één minuut lang
  verschijnt rechtsonder een opvallende, pulserende ronde speelknop. Eén geldige
  klik geeft een bericht van de kat en eenmalig 10 happy points.
- Voor ieder huisdier hebben het vrolijke en hongerige geluid ieder een eigen
  schakelaar, met soortspecifieke tekst. Een derde, duidelijk uitgelegde schakelaar
  bepaalt of meldingen na drie genegeerde meldingen of drie
  snoozes iedere vijf minuten blijven terugkomen. Als deze uitstaat, stopt die
  extra herhaalketen; gewone herinneringen blijven werken.
- Niet-verkrijgbare beloningsitems worden niet in de shop getoond. De vier
  supportersitems verschijnen dus pas nadat ze daadwerkelijk zijn ontgrendeld.
  Na een later door de store geverifieerde eerste bijdrage kan de app eenmalig
  100 happy points en de supporterskroon, -bril, -cape en het supportershart
  geven. Volgende bijdragen geven geen tweede beloning.

## Informatie, contact en veilige ondersteuning

Via het informatie-icoon staat in de app: **Gemaakt door Rick Groot · 2026**.
Contact verloopt volledig via een formulier in de app; er wordt geen externe
mailapp meer geopend en het doeladres staat niet in de APK of broncode. In
`medication_reminder_app/relay/cloudflare-worker` staat nu de beveiligde
HTTPS-relay met serversecrets, strikte validatie, honeypot, rate limiting en
bescherming tegen dubbele verzending. Voor de eerste online koppeling zijn nog
een geautoriseerd Cloudflare-account en een Resend-API-sleutel nodig. Een gratis
privetest kan via het testadres van Resend uitsluitend naar het e-mailadres van
het eigen Resend-account sturen. Voor publicatie hoort een eigen afzenderdomein
te worden geverifieerd; de gratis providerlimieten zijn ruim voldoende, maar een
nog niet bestaand domein kan jaarlijkse registratiekosten hebben. Daarna wordt de Worker-URL tijdens de build
ingesteld met `--dart-define=CONTACT_FORM_ENDPOINT=https://...`. De huidige
testbuild meldt daarom eerlijk dat verzenden nog niet gekoppeld is.

**Instellingen** en **Over deze app** zijn samengevoegd tot één informatiescherm.
Daar staat het codeveld tussen Contact en Doneren. De app toont geen hints naar
actieve codes. De ingebouwde Doctor-set geeft na een geldige invoer een fez,
strikje, tweed-outfit en TARDIS-speeltje rechtstreeks in de garderobe; deze
items verschijnen nooit in de shop. Een latere beveiligde codeserver kan via
`--dart-define=SPECIAL_CODE_ENDPOINT=https://...` aanvullende eenmalige
campagnecodes leveren.

Betalen is in de debugbuild bewust uitgeschakeld. Omdat de bijdrage digitale
happy points en exclusieve items geeft, moet de winkelversie officiële Google
Play Billing / Apple In-App Purchase gebruiken. De lokale, idempotente
beloningslogica en sprites staan klaar; product-ID's, storeaccounts en veilige
serververificatie van transacties zijn nog nodig om echte betalingen aan te zetten.

## Updates zonder voortgang te verliezen

Ja: een normale store-update behoudt lokale appdata zolang dezelfde Android
`applicationId`/Apple bundle identifier en dezelfde release-signing worden
gebruikt en de gebruiker de app niet verwijdert of de opslag wist. De huidige
JSON-modellen lezen ontbrekende nieuwe velden met veilige standaardwaarden en
bevatten migraties voor oude medicatie-, groei- en geluidsgegevens.

Belangrijk voor alle volgende publicaties:

- verander de definitieve identifier `nl.rickgroot.medicationreminder` niet meer;
- bewaar `.signing/release-key.jks` en de lokale signinggegevens veilig in
  meerdere back-ups; deze map wordt bewust nooit naar Git gestuurd;
- test elke datamigratie met een kopie van gegevens uit de vorige appversie;
- voeg vóór brede uitrol export/import of versleutelde cloudback-up toe voor
  herstel na verwijderen, een nieuw toestel of gewiste appdata.

## Openen in Android Studio

1. Start Android Studio en kies **Open**.
2. Open de map `medication_reminder_app` — niet alleen de map `android`.
3. Controleer via **Settings → Languages & Frameworks → Flutter** dat de Flutter SDK `C:\Users\groot\flutter` is.
4. Installeer zo nodig de Flutter- en Dart-plugin.
5. Open **Tools → Device Manager** en start of maak een Android-emulator.
6. Open `lib/main.dart`, selecteer de emulator en klik op **Run ▶**.

Als de emulator ontbreekt, installeer via **Tools → SDK Manager → SDK Tools**:

- Android SDK Command-line Tools (latest)
- Android Emulator
- Android SDK Platform-Tools

Bij de eerste start vraagt Android toestemming voor notificaties zodra je een actief medicijn opslaat.

## Starten via PowerShell

Flutter staat lokaal in `C:\Users\groot\flutter`. Het pad is ook ingesteld voor de Dart-extensie in `.vscode/settings.json`.

```powershell
cd "C:\Users\groot\python projects\MedicationReminder\medication_reminder_app"
& "C:\Users\groot\flutter\bin\flutter.bat" devices
& "C:\Users\groot\flutter\bin\flutter.bat" run
```

## Controleren en bouwen

```powershell
cd "C:\Users\groot\python projects\MedicationReminder\medication_reminder_app"
& "C:\Users\groot\flutter\bin\flutter.bat" analyze
& "C:\Users\groot\flutter\bin\flutter.bat" test
& "C:\Users\groot\flutter\bin\flutter.bat" build apk --debug
```

Je kunt `app-release.apk` ook naar een draaiende emulator slepen om hem handmatig te installeren.

## Projectstructuur

- `lib/main.dart`: appstart, overzicht en gebruikersacties
- `lib/medication.dart`: medicatie- en innamegegevens
- `lib/medication_repository.dart`: lokale persistente opslag en migratie
- `lib/medication_form_screen.dart`: toevoegen en bewerken
- `lib/log_screen.dart`: innamegeschiedenis
- `lib/adherence_chart_screen.dart`: instelbare innamegrafieken
- `lib/about_screen.dart`, `lib/contact_screen.dart` en `lib/support_service.dart`:
  maker en intern contactformulier met beveiligde relay-aansluiting
- `lib/about_screen.dart` en `lib/special_code_service.dart`: samengevoegde
  informatie, contact, speciale codes en ondersteuning
- `lib/notification_service_native.dart`: rechten, tijdzone en notificatieplanning
- `lib/app_localizations.dart`: Nederlandse en Engelse teksten
- `lib/cat.dart`: huisdierprofiel, soorten, varianten, groei en hongerniveaus
- `lib/pet_audio.dart`: hoorbare, niet direct herhalende geluidsselectie
- `lib/pet_sound_catalog.dart`: gedeelde catalogus voor alle zes geluidssets
- `lib/cat_repository.dart`: veilige beloningen, ontgrendeling en lokale dieropslag
- `lib/cat_avatar.dart`: gecombineerd dier, hongerweergave en attributen
- `lib/cat_home_card.dart`: altijd zichtbaar, geanimeerd huisdier
- `lib/cat_screen.dart`: adoptie en instellingen
- `lib/cat_shop.dart` en `lib/cat_shop_screen.dart`: volwassen-katshop
- `assets/cats/`: transparante groei-sprites voor vijf katten, vijf honden en de
  kip, plus uitgelijnde winkel- en supportersoverlays
- `assets/branding/`: het speelse, professionele klok/poot/capsule-logo; het
  transparante beeldmerk blijft binnen de veilige zone van alle launcher-maskers
- `assets/sounds/`: twintig echte varianten voor miauwen, spinnen, blaffen,
  hijgen, kukeleku en tokken; bronopnamen staan buiten de appbundle
- `tool/normalize_cat_sprites.py`: reproduceerbare uitsnede en centrering van de
  gegenereerde kattenillustraties
- `tool/normalize_cat_shop_assets.py`: reproduceerbare shopuitsneden en plaatsing
- `tool/generate_cat_sounds.py`: reproduceerbare, genormaliseerde kattengeluiden
- `tool/align_supporter_overlays.py`: reproduceerbare plaatsing en transparantie
  van de vier met imagegen gemaakte supportersitems
- `relay/cloudflare-worker/`: beveiligde, rate-limited mailrelay zonder geheimen
  in de app of repository
- `test/`: model-, opslag- en widgettests

## Nog nodig voor publicatie

De openbare APK is bruikbaar, maar voor een Play Store/App Store-release zijn nog keuzes en externe controles nodig:

- Maak definitieve storescreenshots, een privacybeleid en storeteksten.
- Test notificaties op echte Android-toestellen van meerdere fabrikanten, met batterijbesparing, herstart en geweigerde rechten.
- Test en onderteken iOS op een Mac met Xcode en een Apple Developer-account.
- Beslis of herinneringen exact op de minuut moeten komen. De veilige standaard
  gebruikt geen speciale exact-alarmtoestemming. Android kan een basis- of
  vijfminutenmelding bij zware batterijbesparing daarom iets uitstellen.
- `flutter_timezone 5.1.0` geeft met de huidige Flutter-versie een waarschuwing
  over een toekomstige Built-in-Kotlin-migratie. Dit is momenteel de nieuwste
  pluginversie en de Android-build slaagt; blijf de Flutter/pluginupdates volgen.

Deze app helpt met herinneren en registreren, maar geeft geen medisch advies. Verander medicatie of dosering alleen in overleg met een bevoegde zorgverlener.
