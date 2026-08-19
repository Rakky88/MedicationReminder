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
    return switch (languageCode) {
      'nl' => _dutchMessage(normalized, safeName, species),
      'de' => _germanMessage(normalized, safeName, species),
      'fr' => _frenchMessage(normalized, safeName, species),
      'es' => _spanishMessage(normalized, safeName, species),
      _ => _englishMessage(normalized, safeName, species),
    };
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

  static String _germanMessage(int index, String name, PetSpecies species) {
    final special = species == PetSpecies.cat
        ? <String>[
            'Donna schaut neidisch. $name sagt: Zeit für die Dosis!',
            'Donna möchte Aufmerksamkeit. $name sagt: Dosis!',
            '$name hilft. Donna schaut neidisch: Zeit für die Dosis!',
            'dimi verjagt $name vielleicht. Erst die Dosis!',
            '$name passt auf. dimi schaut neidisch: Zeit für die Dosis!',
            'dimi brummt $name an. Medikamentenzeit!',
          ]
        : <String>[
            '$name möchte Aufmerksamkeit: Medikamentenzeit!',
            '$name ist bereit: Deine Dosis ist fällig.',
            '$name erinnert dich: Zeit für die Dosis!',
            '$name gibt ein Zeichen: Zeit für die Dosis!',
            '$name wartet. Öffne die App!',
            '$name sagt: Pass gut auf dich auf!',
          ];
    if (index < special.length) return special[index];
    final value = index - special.length;
    final sound = switch (species) {
      PetSpecies.cat => 'miaut',
      PetSpecies.dog => 'bellt',
      PetSpecies.chicken => 'gackert',
    };
    return '$name ${_germanOpenings[value ~/ _germanEndings.length].replaceAll('{sound}', sound)} ${_germanEndings[value % _germanEndings.length]}';
  }

  static String _frenchMessage(int index, String name, PetSpecies species) {
    final special = species == PetSpecies.cat
        ? <String>[
            'Donna est jalouse. $name dit : c’est l’heure de la dose !',
            'Donna veut de l’attention. $name dit : la dose !',
            '$name vous aide. Donna est jalouse : c’est l’heure de la dose !',
            'dimi pourrait chasser $name. La dose d’abord !',
            '$name monte la garde. dimi est jalouse : c’est l’heure de la dose !',
            'dimi grogne contre $name. C’est l’heure du médicament !',
          ]
        : <String>[
            '$name veut votre attention : c’est l’heure du médicament !',
            '$name est prêt : votre dose est prévue.',
            '$name vous rappelle : c’est l’heure de la dose !',
            '$name vous fait signe : c’est l’heure de la dose !',
            '$name attend. Ouvrez l’app !',
            '$name dit : prenez soin de vous !',
          ];
    if (index < special.length) return special[index];
    final value = index - special.length;
    final sound = switch (species) {
      PetSpecies.cat => 'miaule',
      PetSpecies.dog => 'aboie',
      PetSpecies.chicken => 'caquette',
    };
    return '$name ${_frenchOpenings[value ~/ _frenchEndings.length].replaceAll('{sound}', sound)} ${_frenchEndings[value % _frenchEndings.length]}';
  }

  static String _spanishMessage(int index, String name, PetSpecies species) {
    final special = species == PetSpecies.cat
        ? <String>[
            'Donna mira con celos. $name dice: ¡hora de la dosis!',
            'Donna quiere atención. $name dice: ¡la dosis!',
            '$name ayuda. Donna mira con celos: ¡hora de la dosis!',
            'dimi podría echar a $name. ¡Primero la dosis!',
            '$name vigila. dimi mira con celos: ¡hora de la dosis!',
            'dimi gruñe a $name. ¡Hora del medicamento!',
          ]
        : <String>[
            '$name quiere atención: ¡hora del medicamento!',
            '$name está listo: tu dosis está pendiente.',
            '$name te recuerda: ¡hora de la dosis!',
            '$name te hace una señal: ¡hora de la dosis!',
            '$name espera. ¡Abre la app!',
            '$name dice: ¡cuídate mucho!',
          ];
    if (index < special.length) return special[index];
    final value = index - special.length;
    final sound = switch (species) {
      PetSpecies.cat => 'maúlla',
      PetSpecies.dog => 'ladra',
      PetSpecies.chicken => 'cacarea',
    };
    return '$name ${_spanishOpenings[value ~/ _spanishEndings.length].replaceAll('{sound}', sound)} ${_spanishEndings[value % _spanishEndings.length]}';
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

  static const _germanOpenings = <String>[
    'tippt auf die Uhr:',
    'steht bereit:',
    '{sound} sanft:',
    'schaut dich an:',
    'dreht eine schnelle Runde:',
    '{sound} in deiner Nähe:',
    'startet die Erinnerung:',
    'hat Neuigkeiten:',
    'meldet sich:',
    'ist dein Dosis-Coach:',
    'springt auf:',
    'hat ein Update:',
    'steht stolz da:',
    'öffnet den Planer:',
    'unterbricht das Nickerchen:',
    'zeigt auf die Uhr:',
    'testet das Mikrofon:',
    'übernimmt die Erinnerung:',
    'tippt den Alarm an:',
  ];

  static const _germanEndings = <String>[
    'Medikamentenzeit!',
    'deine Dosis wartet.',
    'die Zeit für deine Dosis ist da.',
    'öffne die App.',
    'dein Medikament wartet.',
    'die Uhr sagt: Dosis.',
    'deine Dosis ist bereit.',
    'pass gut auf dich auf.',
    'deine Dosis ist fällig.',
    'ein kleiner hilfreicher Hinweis.',
    'die Dosisrunde beginnt.',
    'schau in die App.',
    'dein Helfer ist da.',
    'Dosiszeit bestätigt.',
    'genau nach Plan.',
    'keine Panik, nur deine Dosis.',
    'Zeit für deine Routine.',
    'deine Erinnerung ist da.',
    'die Medikamentenuhr klingelt.',
    'ein Hinweis für deine Dosis.',
    'nimm dir einen Moment für deine Dosis.',
    'das Team stimmt für die Dosis.',
    'prüfe die heutige Dosis.',
    'das Protokoll sagt: Dosiszeit.',
    'schließe es in der App ab.',
    'deine Dosis sagt Hallo.',
  ];

  static const _frenchOpenings = <String>[
    'tapote la montre :',
    'se tient prêt :',
    '{sound} doucement :',
    'vous regarde :',
    'fait un petit tour :',
    '{sound} tout près :',
    'active le mode rappel :',
    'a une nouvelle :',
    'vient faire son rapport :',
    'est votre coach de dose :',
    'se lève d’un bond :',
    'a une mise à jour :',
    'se tient fièrement :',
    'ouvre le planning :',
    'interrompt la sieste :',
    'montre l’horloge :',
    'teste le microphone :',
    'prend son tour de rappel :',
    'tapote l’alarme :',
  ];

  static const _frenchEndings = <String>[
    'c’est l’heure du médicament !',
    'votre dose vous attend.',
    'l’heure de votre dose est arrivée.',
    'ouvrez l’app.',
    'votre médicament vous attend.',
    'l’horloge dit : la dose.',
    'votre dose est prête.',
    'prenez soin de vous.',
    'votre dose est prévue.',
    'un petit rappel utile.',
    'la tournée des doses commence.',
    'consultez l’app.',
    'votre assistant est là.',
    'heure de la dose confirmée.',
    'pile à l’heure.',
    'pas de panique, juste votre dose.',
    'c’est l’heure de votre routine.',
    'votre rappel est arrivé.',
    'l’horloge du médicament sonne.',
    'un petit rappel pour votre dose.',
    'accordez un moment à votre dose.',
    'l’équipe vote : la dose.',
    'vérifiez la dose du jour.',
    'le protocole dit : heure de la dose.',
    'terminez dans l’app.',
    'votre dose vous dit bonjour.',
  ];

  static const _spanishOpenings = <String>[
    'toca el reloj:',
    'está listo:',
    '{sound} suavemente:',
    'te mira:',
    'da una vuelta rápida:',
    '{sound} cerca:',
    'activa el modo recordatorio:',
    'tiene noticias:',
    'se presenta:',
    'es tu guía de dosis:',
    'se levanta de un salto:',
    'tiene una novedad:',
    'se pone con orgullo:',
    'abre el planificador:',
    'interrumpe la siesta:',
    'señala el reloj:',
    'prueba el micrófono:',
    'se encarga del recordatorio:',
    'toca la alarma:',
  ];

  static const _spanishEndings = <String>[
    '¡hora del medicamento!',
    'tu dosis está esperando.',
    'ha llegado la hora de tu dosis.',
    'abre la app.',
    'tu medicamento espera.',
    'el reloj dice: dosis.',
    'tu dosis está lista.',
    'cuídate mucho.',
    'tu dosis está pendiente.',
    'un pequeño aviso útil.',
    'empieza la ronda de dosis.',
    'consulta la app.',
    'tu ayudante está aquí.',
    'hora de la dosis confirmada.',
    'justo a tiempo.',
    'sin pánico, solo tu dosis.',
    'hora de tu rutina.',
    'tu recordatorio está aquí.',
    'suena el reloj del medicamento.',
    'un aviso para tu dosis.',
    'dedica un momento a tu dosis.',
    'el equipo vota: dosis.',
    'comprueba la dosis de hoy.',
    'el protocolo dice: hora de la dosis.',
    'termínalo en la app.',
    'tu dosis dice hola.',
  ];
}
