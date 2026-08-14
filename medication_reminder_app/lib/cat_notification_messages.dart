import 'cat.dart';

class CatNotificationMessages {
  const CatNotificationMessages._();

  static const int count = 500;

  static String messageAt({
    required int index,
    required String catName,
    required String languageCode,
    PetSpecies species = PetSpecies.cat,
  }) {
    final rawName = catName.trim().isEmpty ? 'Milo' : catName.trim();
    final safeName = rawName.length <= 12
        ? rawName
        : '${rawName.substring(0, 11)}…';
    final normalized = index % count;
    return languageCode == 'nl'
        ? _dutchMessage(normalized, safeName, species)
        : _englishMessage(normalized, safeName, species);
  }

  static String _dutchMessage(int index, String name, PetSpecies species) {
    final special = species == PetSpecies.cat
        ? <String>[
            'Donna kijkt jaloers. $name: medicatietijd!',
            'Donna wil aandacht. $name zegt: dosis!',
            '$name helpt. Donna kijkt jaloers: dosis!',
            'dimi jaagt $name bijna weg. Eerst je dosis!',
            '$name waakt. dimi kijkt jaloers: dosis!',
            'dimi moppert op $name. Medicatietijd!',
          ]
        : <String>[
            '$name vraagt aandacht: medicatietijd!',
            '$name staat klaar: je dosis wacht.',
            '$name helpt: tijd voor je dosis!',
            '$name geeft een seintje: dosis!',
            '$name wacht. Open de app!',
            '$name zegt: zorg goed voor jezelf!',
          ];
    if (index < special.length) return special[index];
    final value = index - special.length;
    final sound = switch (species) {
      PetSpecies.cat => 'miauwt',
      PetSpecies.dog => 'blaft',
      PetSpecies.chicken => 'tokt',
    };
    return '$name ${_dutchOpenings[value ~/ _dutchEndings.length].replaceAll('{sound}', sound)} ${_dutchEndings[value % _dutchEndings.length]}';
  }

  static String _englishMessage(int index, String name, PetSpecies species) {
    final special = species == PetSpecies.cat
        ? <String>[
            'Donna looks jealous. $name says: dose time!',
            'Donna wants attention. $name says: dose!',
            '$name helps. Donna looks jealous: dose time!',
            'dimi may chase $name away. Dose first!',
            '$name guards. dimi looks jealous: dose time!',
            'dimi grumbles at $name. Medication time!',
          ]
        : <String>[
            '$name wants attention: medication time!',
            '$name is ready: your dose is due.',
            '$name reminds you: dose time!',
            '$name gives a signal: dose time!',
            '$name waits. Open the app!',
            '$name says: take care of yourself!',
          ];
    if (index < special.length) return special[index];
    final value = index - special.length;
    final sound = switch (species) {
      PetSpecies.cat => 'meows',
      PetSpecies.dog => 'barks',
      PetSpecies.chicken => 'clucks',
    };
    return '$name ${_englishOpenings[value ~/ _englishEndings.length].replaceAll('{sound}', sound)} ${_englishEndings[value % _englishEndings.length]}';
  }

  static const _dutchOpenings = <String>[
    'tikt op de klok:',
    'staat paraat:',
    '{sound} vriendelijk:',
    'kijkt je aan:',
    'doet een rondje:',
    '{sound} dichtbij:',
    'zet het alarm aan:',
    'heeft nieuws:',
    'komt melden:',
    'is je dosiscoach:',
    'springt op:',
    'heeft een update:',
    'staat trots:',
    'opent de planner:',
    'pauzeert de siësta:',
    'wijst naar de klok:',
    'test de microfoon:',
    'neemt de wacht:',
    'tikt het alarm aan:',
  ];

  static const _dutchEndings = <String>[
    'tijd voor je medicatie!',
    'je dosis wacht.',
    'je medicatiemoment is er.',
    'open de app.',
    'je medicatie wacht.',
    'de klok zegt: dosis.',
    'je dosis staat klaar.',
    'zorg goed voor jezelf.',
    'je dosis is er.',
    'een belangrijk seintje.',
    'de dosisronde begint.',
    'bekijk de app.',
    'je hulpteam is er.',
    'medicatietijd bevestigd.',
    'precies op tijd.',
    'geen paniek, alleen je dosis.',
    'tijd voor je routine.',
    'je herinnering is er.',
    'de medicatieklok gaat.',
    'een dosis-seintje.',
    'geef je dosis een moment.',
    'het team stemt: dosis.',
    'bekijk wat klaarstaat.',
    'het protocol zegt: dosis.',
    'rond dit af in de app.',
    'je dosis zegt hallo.',
  ];

  static const _englishOpenings = <String>[
    'taps the watch:',
    'stands ready:',
    '{sound} gently:',
    'looks at you:',
    'takes a quick lap:',
    '{sound} nearby:',
    'starts reminder mode:',
    'has news:',
    'reports in:',
    'is your dose coach:',
    'jumps up:',
    'has an update:',
    'stands proudly:',
    'opens the planner:',
    'pauses the nap:',
    'points at the clock:',
    'tests the microphone:',
    'takes reminder duty:',
    'taps the alarm:',
  ];

  static const _englishEndings = <String>[
    'medication time!',
    'your dose is waiting.',
    'your dose time is here.',
    'open the app.',
    'your medication waits.',
    'the clock says: dose.',
    'your dose is ready.',
    'take care of yourself.',
    'your dose is due.',
    'a helpful little nudge.',
    'the dose round begins.',
    'check the app.',
    'your helper is here.',
    'dose time confirmed.',
    'right on schedule.',
    'no panic, just your dose.',
    'time for your routine.',
    'your reminder is here.',
    'the medication clock rings.',
    'a nudge for your dose.',
    'give your dose a moment.',
    'the team votes: dose.',
    'check today’s dose.',
    'protocol says: dose time.',
    'finish it in the app.',
    'your dose says hello.',
  ];
}
