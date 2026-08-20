# Visuele assetreview

Dit is de vaste werkwijze voor iedere nieuwe of gewijzigde pet, outfit, hoed,
bril, stropdas/strik of toy. Een asset is pas klaar nadat alle toepasselijke
diervarianten in de echte Flutter-renderer zijn bekeken en de gebruiker de
overgebleven afwijkingen expliciet heeft geselecteerd.

## Definitie van klaar

- Controleer alle vijf volwassen katten, vijf volwassen honden en de volwassen
  kip; bij fasegebonden kleding wordt juist die levensfase gebruikt.
- Controleer hoofditems op schedel, oren en ooglijn. Een fez blijft laag,
  relatief dun, brimloos en niet breder dan de kop.
- Controleer brillen op beide ogen en laat geen los rechter brilsteeltje buiten
  het montuur uitsteken.
- Controleer kleding anatomisch: natuurlijke poten of vleugels beginnen in de
  opening, liggen vóór de achterrand en blijven zichtbaar tot en met poot/voet.
- Controleer volledige sprites op transparantie, centrering, grondlijn en
  afsnijding. Bekijk accessoires ook op een aangeklede volwassen variant en in
  de notificatieweergave wanneer ze daar worden gebruikt.
- Een correctie wordt per item én per dier in
  `tool/normalize_pet_assets.py` opgeslagen. Een al goedgekeurde combinatie mag
  niet door een globale noodcorrectie verslechteren.

## 1. Bron en normalisatie

Bewaar de oorspronkelijke afbeelding onder `design_assets/`. Bewaar bij een
gegenereerde rasterasset ook de gebruikte prompt naast de bron. Een grid heeft
een effen chroma-achtergrond en duidelijke lege scheidingsstroken; verwijder de
achtergrond daarna met de chroma-helper en bewaar zowel de chroma- als de
transparante versie.

Regenereren gebeurt reproduceerbaar vanuit de projectmap:

```powershell
python tool/normalize_pet_assets.py
```

De app gebruikt alleen de genormaliseerde bestanden onder `assets/cats/`,
`assets/cats/fitted/` en `assets/cats/fitted_accessories/`.

## 2. Interactieve controle op Android

1. `lib/emulator_accessory_audit_main.dart` maakt automatisch alle combinaties
   van iedere volwassen-petoutfit met iedere bril, hoed en strik. Een pagina
   toont dezelfde combinatie op alle elf huisdieren. Gebruik de twee keuzelijsten
   om rechtstreeks naar een bepaalde outfit of accessoire te springen.
2. Verhoog voor een nieuwe, lege ronde zowel `_preferencesKey` als
   `_exportFileName` van bijvoorbeeld `v8` naar `v9`. Zo blijven oude vinkjes
   nooit stil in een nieuwe ronde staan.
3. Bouw en installeer de reviewapp met dezelfde package-ID. `install -r`
   vervangt alleen de app en behoudt de lokale medicatie-, historie- en petdata.

```powershell
& "C:\Users\groot\flutter\bin\flutter.bat" build apk --debug --no-pub `
  --target lib\emulator_accessory_audit_main.dart
& "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" install -r `
  build\app\outputs\flutter-apk\app-debug.apk
```

4. Ga samen pagina voor pagina langs. Tik alleen op een dier wanneer de
   combinatie van outfit en accessoire niet goed is; rood betekent geselecteerd.
   De exportregel bevat altijd `outfit|accessoire|huisdier`. Gebruik op de
   laatste pagina **Kopieer lijst**.
5. Dezelfde lijst wordt automatisch geëxporteerd naar:

```text
/storage/emulated/0/Android/data/nl.rickgroot.medicationreminder/files/
accessory_visual_audit_vN_fitted_review.txt
```

## 3. Selecties reproduceren en oplossen

Trek het exportbestand met `adb pull` naar `tmp/fitted_review/`. Maak daarna
desktop-controlesheets van exact de aangevinkte combinaties:

```powershell
python tool/render_visual_review.py `
  tmp\fitted_review\accessory_visual_audit_vN_fitted_review.txt `
  --output tmp\fitted_review\vN_fixed.png
```

Los de combinaties bronlokaal op in `tool/normalize_pet_assets.py`, regenereer
de assets en maak de sheet opnieuw. Controleer dat de geselecteerde fout weg is
en vergelijk steekproefsgewijs eerder goedgekeurde varianten.

## 4. Regressie en vrijgave

Voer vóór een normale update minimaal uit:

```powershell
& "C:\Users\groot\flutter\bin\flutter.bat" analyze --no-pub
& "C:\Users\groot\flutter\bin\flutter.bat" test --no-pub
& "C:\Users\groot\flutter\bin\flutter.bat" build apk --release --no-pub
```

Installeer tot slot de gewone `lib/main.dart`-release met `adb install -r` en
controleer versie, pet, garderobe en één notificatiepreview. Publiceer pas daarna
dezelfde ondertekende APK als nieuwste GitHub-release. Door dezelfde package-ID
en releasekey te behouden blijft een update over de bestaande app heen mogelijk.
