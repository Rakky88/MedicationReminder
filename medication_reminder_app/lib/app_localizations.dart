import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const Map<String, Map<String, String>> _values = {
    'en': {
      'title': 'Medication Reminder',
      'addMedication': 'Add medication',
      'editMedication': 'Edit medication',
      'emptyTitle': 'No medication scheduled',
      'emptyBody':
          'Add your first medication and choose when you want a reminder.',
      'addFirst': 'Add my first medication',
      'name': 'Medication name',
      'dosage': 'Dosage or instructions (optional)',
      'times': 'Reminder times',
      'days': 'Days',
      'notificationsOnly': 'Notifications only',
      'showMedicationName': 'Show medication name in notifications',
      'allowEarlyDose': 'Allow Taken before this alarm',
      'doseDueAt': 'Dose due at {time}',
      'earlyDoseAt': 'Early dose for {time}',
      'save': 'Save',
      'cancel': 'Cancel',
      'delete': 'Delete',
      'edit': 'Edit',
      'taken': 'Taken',
      'skipped': 'Dose missed',
      'snooze': 'Snooze',
      'snoozed': 'Reminder snoozed for 10 minutes.',
      'recorded': 'Dose marked as taken.',
      'skippedRecorded': 'Dose marked as missed.',
      'missedConfirmTitle': 'Mark this dose as missed?',
      'missedConfirmBody':
          'Choose this only when you did not take this scheduled dose. The alarm stops and the missed dose is added to your history.',
      'missedConfirmAction': 'Yes, dose missed',
      'duplicate': 'This dose was just recorded already.',
      'undo': 'Undo',
      'history': 'History',
      'historyGraph': 'View adherence graph',
      'periodWeek': 'Week',
      'periodMonth': 'Month',
      'periodYear': 'Year',
      'periodAll': 'All',
      'previousPeriod': 'Previous period',
      'nextPeriod': 'Next period',
      'selectPeriod': 'Select period',
      'takenCount': '{count} taken',
      'missedCount': '{count} missed',
      'adherence': '{percentage}% taken',
      'noGraphData': 'No intake data in this period',
      'scheduledAt': 'Scheduled at {time}',
      'noEntries': 'No history yet',
      'clearHistory': 'Clear history',
      'clearTitle': 'Clear all history?',
      'clearBody': 'This cannot be undone.',
      'clear': 'Clear',
      'nextDose': 'Next reminder',
      'noUpcoming': 'No upcoming reminders',
      'notificationDenied':
          'Notifications are disabled. The medication was saved with reminders off.',
      'notificationError':
          'The medication was saved, but reminders could not be scheduled.',
      'testNotification': 'Test notification',
      'notificationSent': 'Test notification sent.',
      'unsupportedNotifications':
          'Notifications are not available on this platform.',
      'deleteTitle': 'Delete this medication?',
      'deleteBody': 'Its future reminders will also be removed.',
      'nameRequired': 'Enter a medication name.',
      'timeRequired': 'Add at least one reminder time.',
      'dayRequired': 'Select at least one day.',
      'addTime': 'Add time',
      'language': 'Language',
      'active': 'Active',
      'inactive': 'Paused',
      'reminderBody': 'It is time to take your medication.',
      'notificationTaken': 'Taken',
      'notificationOpen': 'Open app',
      'notificationSnooze': 'Snooze 10 min',
      'reminderFollowUpBody':
          'No response yet. Open the app or snooze this reminder.',
      'reminderEscalatedBody':
          'Your cat keeps meowing. Open the app or snooze the reminder.',
      'reminderEscalatedNoCatBody':
          'This reminder keeps repeating. Open the app or snooze it.',
      'loadError': 'Something went wrong while loading your data.',
      'retry': 'Try again',
      'genericMedication': 'Medication',
      'allDays': 'Every day',
      'adoptCat': 'Adopt a pet',
      'adoptCatBody':
          'Optional: care for a unique pet by recording scheduled doses.',
      'meetCat': 'Meet another cat',
      'meetPet': 'Meet another',
      'petCat': 'Cat',
      'petDog': 'Dog',
      'petChicken': 'Chicken',
      'catName': 'Pet name',
      'adopt': 'Adopt',
      'catSettings': 'Pet settings',
      'catSound': 'Purring and meowing',
      'catPurrSound': 'Purring sound',
      'catMeowSound': 'Meowing sound',
      'dogPantSound': 'Panting sound',
      'dogBarkSound': 'Barking sound',
      'chickenCluckSound': 'Clucking sound',
      'chickenCrowSound': 'Crowing sound',
      'catPersistentMeow': 'Keep repeating reminders until I respond',
      'petPersistentReminder': 'Keep repeating reminders until I respond',
      'catSafety':
          'Only one valid scheduled dose feeds your pet. Never take extra medication for the game.',
      'catKitten': 'Kitten',
      'catYoung': 'Young cat',
      'catAdult': 'Adult cat',
      'dogPuppy': 'Puppy',
      'dogYoung': 'Young dog',
      'dogAdult': 'Adult dog',
      'chickenEgg': 'Egg',
      'chickenChick': 'Chick',
      'chickenAdult': 'Adult chicken',
      'petFull': 'is content and playing',
      'petPeckish': 'is getting peckish',
      'petHungry': 'is hungry',
      'petVeryHungry': 'is very hungry and waiting',
      'petCelebrating': 'is very happy',
      'petDoseDue': 'asks for your attention: medication time!',
      'catGrowing': 'Growth',
      'catFed': '{cat} has eaten and is purring!',
      'petFed': '{pet} has eaten and is happy!',
      'catFull': 'is content and playing',
      'catPeckish': 'is getting peckish',
      'catHungry': 'is hungry and meowing',
      'catVeryHungry': 'is very hungry and waiting for the next dose',
      'catPurring': 'is purring happily',
      'catDoseDue': 'is meowing: medication time!',
      'catMissedHint':
          'Missed doses make the bowl emptier. Each next valid dose helps one step.',
      'catRemove': 'Find a new home',
      'catRemoveTitle': 'Find a new home for your pet?',
      'catRemoveBody':
          'The pet and its growth progress will be removed. Your items remain yours for a future adult pet.',
      'catNotificationBody': '{cat} is meowing: medication time!',
      'catHappyPoints': '{points} happy points',
      'happyPointsEarned': '+{points} happy points',
      'catShop': 'Pet shop',
      'shopShort': 'Shop',
      'catShopBody': 'Use happy points to buy hats, glasses, outfits and toys.',
      'catInventory': 'My pet wardrobe',
      'wardrobeShort': 'Wardrobe',
      'catInventoryBody':
          'Choose what your pet wears. You can use one item per category or remove it again.',
      'catInventoryKittenBody':
          'Your items are safely stored. You can use them when your pet is an adult.',
      'inventoryOwnedCount': '{count} items collected',
      'inventoryOwnedOne': '1 item collected',
      'inventoryEmpty':
          'Your wardrobe is still empty. Purchased and special items will appear here.',
      'inventoryAdultOnly': 'Available as adult',
      'shopBalance': 'Balance: {points} happy points',
      'shopBuy': 'Buy',
      'shopEquip': 'Use',
      'shopEquipped': 'In use',
      'shopUnequip': 'Remove',
      'shopOwned': 'Owned',
      'shopNotEnough': 'Not enough happy points yet.',
      'shopPurchased': '{item} purchased! You can find it in your wardrobe.',
      'shopHats': 'Hats and caps',
      'shopGlasses': 'Glasses',
      'shopNeckwear': 'Ties',
      'shopOutfits': 'Outfits',
      'shopToys': 'Toys',
      'medicationStreak': 'Streak: {days}',
      'medicationStreakBest': 'Best: {days}',
      'shopRegularItems': 'Regular items',
      'shopStreakItems': 'Streak items',
      'shopStreakSummary': 'Current streak: {current} days · Best: {best}',
      'shopStreakRequirement': '{days}-day streak',
      'shopStreakLocked': 'Reach {days} days',
      'shopStreakClaim': 'Claim free',
      'catWantsToPlay': 'Your pet wants to play!',
      'catPlayTooltip': 'Play with {cat}',
      'catPlayedTitle': 'Playtime!',
      'catPlayedBody':
          'You played with {cat}. Your pet loved it, and you earned 10 happy points!',
      'settings': 'Settings',
      'specialCodes': 'Special item codes',
      'specialCodesBody':
          'Enter a valid campaign code to unlock a special pet item. Unlocked items appear directly in your wardrobe.',
      'specialCodeLabel': 'Special code',
      'specialCodeRedeem': 'Redeem code',
      'specialCodeRequired': 'Enter a code first.',
      'specialCodeNeedsCat': 'Adopt a pet before redeeming an item code.',
      'specialCodeInvalid': 'This code is not valid.',
      'specialCodeAlreadyUsed': 'This code has already been used.',
      'specialCodeFailed': 'The code could not be checked. Try again later.',
      'specialCodeRedeemed':
          'Special item unlocked! It is now in your wardrobe.',
      'aboutApp': 'About this app',
      'madeBy': 'Made by Rick Groot · 2026',
      'appVersion': 'Version {version}',
      'shareApp': 'Share or update the app',
      'shareAppBody':
          'Copy one permanent Android download link for someone else, or open it to install the latest version over this app.',
      'copyDownloadLink': 'Copy Android download link',
      'downloadOrUpdate': 'Download or update',
      'appLinkCopied': 'The Android download link has been copied.',
      'appLinkOpenFailed':
          'The browser could not be opened. The download link has been copied instead.',
      'contact': 'Contact',
      'contactBody': 'Send feedback or ask a question without leaving the app.',
      'contactAction': 'Open contact form',
      'contactSubject': 'Medication Reminder contact',
      'contactReplyEmail': 'Your email address',
      'contactEmailInvalid': 'Enter a valid email address so we can reply.',
      'contactSubjectLabel': 'Subject',
      'contactSubjectRequired': 'Enter a subject.',
      'contactMessage': 'Message',
      'contactMessageRequired': 'Write at least 10 characters.',
      'contactSend': 'Send securely',
      'contactSent': 'Thank you! Your message has been sent.',
      'contactSendFailed': 'Your message could not be sent. Try again later.',
      'contactRelayUnavailable':
          'Secure sending is not connected in this test build yet.',
      'contactPrivacyBody':
          'You type everything here. The app never opens another mail app and does not store your message on this device.',
      'contactTestBuildNotice':
          'The secure server relay still needs to be connected before publishing.',
      'buyMeCoffee': 'Buy me a coffee',
      'buyMeCoffeeBody':
          'Enjoying the app? You can support its development through Ko-fi.',
      'paypalPayment': 'Payment via PayPal',
      'buyMeCoffeeAction': 'Open tip form',
      'buyMeCoffeeOpenFailed':
          'Ko-fi could not be opened. The link has been copied instead.',
    },
    'nl': {
      'title': 'Medicatieherinnering',
      'addMedication': 'Medicijn toevoegen',
      'editMedication': 'Medicijn bewerken',
      'emptyTitle': 'Nog geen medicatie gepland',
      'emptyBody':
          'Voeg je eerste medicijn toe en kies wanneer je een herinnering wilt.',
      'addFirst': 'Mijn eerste medicijn toevoegen',
      'name': 'Naam van medicijn',
      'dosage': 'Dosering of instructie (optioneel)',
      'times': 'Herinneringstijden',
      'days': 'Dagen',
      'notificationsOnly': 'Alleen notificaties',
      'showMedicationName': 'Medicijnnaam tonen in meldingen',
      'allowEarlyDose': 'Ingenomen vóór dit alarm toestaan',
      'doseDueAt': 'Inname van {time}',
      'earlyDoseAt': 'Vroege inname voor {time}',
      'save': 'Opslaan',
      'cancel': 'Annuleren',
      'delete': 'Verwijderen',
      'edit': 'Bewerken',
      'taken': 'Ingenomen',
      'skipped': 'Inname gemist',
      'snooze': 'Uitstellen',
      'snoozed': 'Herinnering 10 minuten uitgesteld.',
      'recorded': 'Inname is geregistreerd.',
      'skippedRecorded': 'Inname is als gemist geregistreerd.',
      'missedConfirmTitle': 'Deze inname als gemist markeren?',
      'missedConfirmBody':
          'Kies dit alleen als je deze geplande dosis niet hebt ingenomen. Het alarm stopt en de gemiste inname komt in je geschiedenis.',
      'missedConfirmAction': 'Ja, inname gemist',
      'duplicate': 'Deze dosis is zojuist al geregistreerd.',
      'undo': 'Ongedaan maken',
      'history': 'Geschiedenis',
      'historyGraph': 'Innamegrafiek bekijken',
      'periodWeek': 'Week',
      'periodMonth': 'Maand',
      'periodYear': 'Jaar',
      'periodAll': 'Altijd',
      'previousPeriod': 'Vorige periode',
      'nextPeriod': 'Volgende periode',
      'selectPeriod': 'Periode kiezen',
      'takenCount': '{count} ingenomen',
      'missedCount': '{count} gemist',
      'adherence': '{percentage}% ingenomen',
      'noGraphData': 'Geen innamegegevens in deze periode',
      'scheduledAt': 'Gepland om {time}',
      'noEntries': 'Nog geen geschiedenis',
      'clearHistory': 'Geschiedenis wissen',
      'clearTitle': 'Alle geschiedenis wissen?',
      'clearBody': 'Dit kan niet ongedaan worden gemaakt.',
      'clear': 'Wissen',
      'nextDose': 'Volgende herinnering',
      'noUpcoming': 'Geen komende herinneringen',
      'notificationDenied':
          'Notificaties staan uit. Het medicijn is opgeslagen met herinneringen uitgeschakeld.',
      'notificationError':
          'Het medicijn is opgeslagen, maar herinneringen konden niet worden gepland.',
      'testNotification': 'Testnotificatie',
      'notificationSent': 'Testnotificatie verstuurd.',
      'unsupportedNotifications':
          'Notificaties zijn niet beschikbaar op dit platform.',
      'deleteTitle': 'Dit medicijn verwijderen?',
      'deleteBody': 'De toekomstige herinneringen worden ook verwijderd.',
      'nameRequired': 'Vul een naam voor het medicijn in.',
      'timeRequired': 'Voeg minimaal één herinneringstijd toe.',
      'dayRequired': 'Selecteer minimaal één dag.',
      'addTime': 'Tijd toevoegen',
      'language': 'Taal',
      'active': 'Actief',
      'inactive': 'Gepauzeerd',
      'reminderBody': 'Het is tijd om je medicatie in te nemen.',
      'notificationTaken': 'Ingenomen',
      'notificationOpen': 'App openen',
      'notificationSnooze': '10 min uitstellen',
      'reminderFollowUpBody':
          'Nog geen reactie. Open de app of stel deze melding uit.',
      'reminderEscalatedBody':
          'Je kat blijft miauwen. Open de app of stel de melding uit.',
      'reminderEscalatedNoCatBody':
          'Deze melding blijft terugkomen. Open de app of stel haar uit.',
      'loadError': 'Er ging iets mis bij het laden van je gegevens.',
      'retry': 'Opnieuw proberen',
      'genericMedication': 'Medicatie',
      'allDays': 'Elke dag',
      'adoptCat': 'Een huisdier adopteren',
      'adoptCatBody':
          'Optioneel: verzorg een uniek huisdier door geplande innames te registreren.',
      'meetCat': 'Andere kat ontmoeten',
      'meetPet': 'Andere ontmoeten',
      'petCat': 'Kat',
      'petDog': 'Hond',
      'petChicken': 'Kip',
      'catName': 'Naam van je huisdier',
      'adopt': 'Adopteren',
      'catSettings': 'Huisdierinstellingen',
      'catSound': 'Spinnen en miauwen',
      'catPurrSound': 'Spingeluid',
      'catMeowSound': 'Miauwgeluid',
      'dogPantSound': 'Hijggeluid',
      'dogBarkSound': 'Blafgeluid',
      'chickenCluckSound': 'Tokgeluid',
      'chickenCrowSound': 'Kukelekuugeluid',
      'catPersistentMeow': 'Meldingen herhalen tot ik reageer',
      'petPersistentReminder': 'Meldingen herhalen tot ik reageer',
      'catSafety':
          'Alleen één geldige geplande dosis voert je huisdier. Neem nooit extra medicatie voor het spel.',
      'catKitten': 'Kitten',
      'catYoung': 'Jonge kat',
      'catAdult': 'Volwassen kat',
      'dogPuppy': 'Pup',
      'dogYoung': 'Jonge hond',
      'dogAdult': 'Volwassen hond',
      'chickenEgg': 'Ei',
      'chickenChick': 'Kuiken',
      'chickenAdult': 'Volwassen kip',
      'petFull': 'is tevreden en aan het spelen',
      'petPeckish': 'begint trek te krijgen',
      'petHungry': 'heeft honger',
      'petVeryHungry': 'heeft veel honger en wacht',
      'petCelebrating': 'is heel blij',
      'petDoseDue': 'vraagt je aandacht: medicatietijd!',
      'catGrowing': 'Groei',
      'catFed': '{cat} heeft gegeten en spint!',
      'petFed': '{pet} heeft gegeten en is blij!',
      'catFull': 'is tevreden en aan het spelen',
      'catPeckish': 'begint trek te krijgen',
      'catHungry': 'heeft honger en miauwt',
      'catVeryHungry': 'heeft veel honger en wacht op de volgende dosis',
      'catPurring': 'spint heel tevreden',
      'catDoseDue': 'miauwt: medicatietijd!',
      'catMissedHint':
          'Door gemiste innames raakt het bakje leger. Elke volgende geldige dosis helpt één stap.',
      'catRemove': 'Een nieuw thuis zoeken',
      'catRemoveTitle': 'Een nieuw thuis voor je huisdier zoeken?',
      'catRemoveBody':
          'Het huisdier en alle groeivoortgang worden verwijderd. Verkregen spullen blijven van jou voor een volgend volwassen huisdier.',
      'catNotificationBody': '{cat} miauwt: tijd voor je medicatie!',
      'catHappyPoints': '{points} happy points',
      'happyPointsEarned': '+{points} happy points',
      'catShop': 'Dierenwinkel',
      'shopShort': 'Shop',
      'catShopBody':
          'Gebruik happy points om hoeden, brillen, outfits en speeltjes te kopen.',
      'catInventory': 'Mijn dierengarderobe',
      'wardrobeShort': 'Garderobe',
      'catInventoryBody':
          'Kies wat je huisdier draagt. Je kunt per soort één item gebruiken of het weer afdoen.',
      'catInventoryKittenBody':
          'Je spullen worden veilig bewaard. Je kunt ze gebruiken zodra je huisdier volwassen is.',
      'inventoryOwnedCount': '{count} spullen verzameld',
      'inventoryOwnedOne': '1 item verzameld',
      'inventoryEmpty':
          'Je garderobe is nog leeg. Gekochte en speciale spullen verschijnen hier.',
      'inventoryAdultOnly': 'Vanaf volwassen',
      'shopBalance': 'Saldo: {points} happy points',
      'shopBuy': 'Kopen',
      'shopEquip': 'Gebruiken',
      'shopEquipped': 'In gebruik',
      'shopUnequip': 'Afdoen',
      'shopOwned': 'Gekocht',
      'shopNotEnough': 'Je hebt nog niet genoeg happy points.',
      'shopPurchased': '{item} gekocht! Je vindt het in je garderobe.',
      'shopHats': 'Hoeden en petten',
      'shopGlasses': 'Brillen',
      'shopNeckwear': 'Dassen',
      'shopOutfits': 'Outfits',
      'shopToys': 'Speeltjes',
      'medicationStreak': 'Streak: {days}',
      'medicationStreakBest': 'Beste: {days}',
      'shopRegularItems': 'Gewone items',
      'shopStreakItems': 'Streak-items',
      'shopStreakSummary': 'Huidige streak: {current} dagen · Beste: {best}',
      'shopStreakRequirement': 'Streak van {days} dagen',
      'shopStreakLocked': 'Behaal {days} dagen',
      'shopStreakClaim': 'Gratis ophalen',
      'catWantsToPlay': 'Je huisdier wil spelen!',
      'catPlayTooltip': 'Spelen met {cat}',
      'catPlayedTitle': 'Speeltijd!',
      'catPlayedBody':
          'Je hebt met {cat} gespeeld. Je huisdier vond het geweldig en je hebt 10 happy points verdiend!',
      'settings': 'Instellingen',
      'specialCodes': 'Codes voor speciale items',
      'specialCodesBody':
          'Vul een geldige actiecode in om een speciaal huisdieritem te ontgrendelen. Het item verschijnt direct in je garderobe.',
      'specialCodeLabel': 'Speciale code',
      'specialCodeRedeem': 'Code gebruiken',
      'specialCodeRequired': 'Vul eerst een code in.',
      'specialCodeNeedsCat':
          'Adopteer eerst een kat om een itemcode te gebruiken.',
      'specialCodeInvalid': 'Deze code is niet geldig.',
      'specialCodeAlreadyUsed': 'Deze code is al gebruikt.',
      'specialCodeFailed':
          'De code kon niet worden gecontroleerd. Probeer het later opnieuw.',
      'specialCodeRedeemed':
          'Speciaal item ontgrendeld! Het staat nu in je garderobe.',
      'aboutApp': 'Over deze app',
      'madeBy': 'Gemaakt door Rick Groot · 2026',
      'appVersion': 'Versie {version}',
      'shareApp': 'App delen of updaten',
      'shareAppBody':
          'Kopieer één vaste Android-downloadlink voor iemand anders, of open hem om de nieuwste versie over deze app te installeren.',
      'copyDownloadLink': 'Android-downloadlink kopiëren',
      'downloadOrUpdate': 'Downloaden of updaten',
      'appLinkCopied': 'De Android-downloadlink is gekopieerd.',
      'appLinkOpenFailed':
          'De browser kon niet worden geopend. De downloadlink is daarom gekopieerd.',
      'contact': 'Contact',
      'contactBody':
          'Stuur feedback of stel een vraag zonder de app te verlaten.',
      'contactAction': 'Contactformulier openen',
      'contactSubject': 'Contact over Medicatieherinnering',
      'contactReplyEmail': 'Jouw e-mailadres',
      'contactEmailInvalid':
          'Vul een geldig e-mailadres in zodat we kunnen antwoorden.',
      'contactSubjectLabel': 'Onderwerp',
      'contactSubjectRequired': 'Vul een onderwerp in.',
      'contactMessage': 'Bericht',
      'contactMessageRequired': 'Schrijf minimaal 10 tekens.',
      'contactSend': 'Veilig versturen',
      'contactSent': 'Bedankt! Je bericht is verstuurd.',
      'contactSendFailed':
          'Je bericht kon niet worden verstuurd. Probeer het later opnieuw.',
      'contactRelayUnavailable':
          'Veilig versturen is in deze testversie nog niet gekoppeld.',
      'contactPrivacyBody':
          'Je typt alles hier. De app opent nooit een andere mailapp en bewaart je bericht niet op dit apparaat.',
      'contactTestBuildNotice':
          'De beveiligde serverrelay moet vóór publicatie nog worden gekoppeld.',
      'buyMeCoffee': 'Trakteer me op koffie',
      'buyMeCoffeeBody':
          'Blij met de app? Via Ko-fi kun je de verdere ontwikkeling steunen.',
      'paypalPayment': 'Betaling via PayPal',
      'buyMeCoffeeAction': 'Fooiformulier openen',
      'buyMeCoffeeOpenFailed':
          'Ko-fi kon niet worden geopend. De link is daarom gekopieerd.',
    },
  };

  String _get(String key) =>
      _values[locale.languageCode]?[key] ?? _values['en']![key] ?? key;

  String get title => _get('title');
  String get addMedication => _get('addMedication');
  String get editMedication => _get('editMedication');
  String get emptyTitle => _get('emptyTitle');
  String get emptyBody => _get('emptyBody');
  String get addFirst => _get('addFirst');
  String get name => _get('name');
  String get dosage => _get('dosage');
  String get times => _get('times');
  String get days => _get('days');
  String get notificationsOnly => _get('notificationsOnly');
  String get showMedicationName => _get('showMedicationName');
  String get allowEarlyDose => _get('allowEarlyDose');
  String doseDueAt(String time) => _get('doseDueAt').replaceAll('{time}', time);
  String earlyDoseAt(String time) =>
      _get('earlyDoseAt').replaceAll('{time}', time);
  String get save => _get('save');
  String get cancel => _get('cancel');
  String get delete => _get('delete');
  String get edit => _get('edit');
  String get taken => _get('taken');
  String get skipped => _get('skipped');
  String get snooze => _get('snooze');
  String get snoozed => _get('snoozed');
  String get recorded => _get('recorded');
  String get skippedRecorded => _get('skippedRecorded');
  String get missedConfirmTitle => _get('missedConfirmTitle');
  String get missedConfirmBody => _get('missedConfirmBody');
  String get missedConfirmAction => _get('missedConfirmAction');
  String get duplicate => _get('duplicate');
  String get undo => _get('undo');
  String get history => _get('history');
  String get historyGraph => _get('historyGraph');
  String get periodWeek => _get('periodWeek');
  String get periodMonth => _get('periodMonth');
  String get periodYear => _get('periodYear');
  String get periodAll => _get('periodAll');
  String get previousPeriod => _get('previousPeriod');
  String get nextPeriod => _get('nextPeriod');
  String get selectPeriod => _get('selectPeriod');
  String takenCount(int count) =>
      _get('takenCount').replaceAll('{count}', count.toString());
  String missedCount(int count) =>
      _get('missedCount').replaceAll('{count}', count.toString());
  String adherence(String percentage) =>
      _get('adherence').replaceAll('{percentage}', percentage);
  String get noGraphData => _get('noGraphData');
  String scheduledAt(String time) =>
      _get('scheduledAt').replaceAll('{time}', time);
  String get noEntries => _get('noEntries');
  String get clearHistory => _get('clearHistory');
  String get clearTitle => _get('clearTitle');
  String get clearBody => _get('clearBody');
  String get clear => _get('clear');
  String get nextDose => _get('nextDose');
  String get noUpcoming => _get('noUpcoming');
  String get notificationDenied => _get('notificationDenied');
  String get notificationError => _get('notificationError');
  String get testNotification => _get('testNotification');
  String get notificationSent => _get('notificationSent');
  String get unsupportedNotifications => _get('unsupportedNotifications');
  String get deleteTitle => _get('deleteTitle');
  String get deleteBody => _get('deleteBody');
  String get nameRequired => _get('nameRequired');
  String get timeRequired => _get('timeRequired');
  String get dayRequired => _get('dayRequired');
  String get addTime => _get('addTime');
  String get language => _get('language');
  String get active => _get('active');
  String get inactive => _get('inactive');
  String get reminderBody => _get('reminderBody');
  String get notificationTaken => _get('notificationTaken');
  String get notificationOpen => _get('notificationOpen');
  String get notificationSnooze => _get('notificationSnooze');
  String get reminderFollowUpBody => _get('reminderFollowUpBody');
  String get reminderEscalatedBody => _get('reminderEscalatedBody');
  String get reminderEscalatedNoCatBody => _get('reminderEscalatedNoCatBody');
  String get loadError => _get('loadError');
  String get retry => _get('retry');
  String get genericMedication => _get('genericMedication');
  String get allDays => _get('allDays');
  String get adoptCat => _get('adoptCat');
  String get adoptCatBody => _get('adoptCatBody');
  String get meetCat => _get('meetCat');
  String get meetPet => _get('meetPet');
  String get petCat => _get('petCat');
  String get petDog => _get('petDog');
  String get petChicken => _get('petChicken');
  String get catName => _get('catName');
  String get adopt => _get('adopt');
  String get catSettings => _get('catSettings');
  String get catSound => _get('catSound');
  String get catPurrSound => _get('catPurrSound');
  String get catMeowSound => _get('catMeowSound');
  String get dogPantSound => _get('dogPantSound');
  String get dogBarkSound => _get('dogBarkSound');
  String get chickenCluckSound => _get('chickenCluckSound');
  String get chickenCrowSound => _get('chickenCrowSound');
  String get catPersistentMeow => _get('catPersistentMeow');
  String get petPersistentReminder => _get('petPersistentReminder');
  String get catSafety => _get('catSafety');
  String get catKitten => _get('catKitten');
  String get catYoung => _get('catYoung');
  String get catAdult => _get('catAdult');
  String get dogPuppy => _get('dogPuppy');
  String get dogYoung => _get('dogYoung');
  String get dogAdult => _get('dogAdult');
  String get chickenEgg => _get('chickenEgg');
  String get chickenChick => _get('chickenChick');
  String get chickenAdult => _get('chickenAdult');
  String get petFull => _get('petFull');
  String get petPeckish => _get('petPeckish');
  String get petHungry => _get('petHungry');
  String get petVeryHungry => _get('petVeryHungry');
  String get petCelebrating => _get('petCelebrating');
  String get petDoseDue => _get('petDoseDue');
  String get catGrowing => _get('catGrowing');
  String catFed(String name) => _get('catFed').replaceAll('{cat}', name);
  String petFed(String name) => _get('petFed').replaceAll('{pet}', name);
  String get catFull => _get('catFull');
  String get catPeckish => _get('catPeckish');
  String get catHungry => _get('catHungry');
  String get catVeryHungry => _get('catVeryHungry');
  String get catPurring => _get('catPurring');
  String get catDoseDue => _get('catDoseDue');
  String get catMissedHint => _get('catMissedHint');
  String get catRemove => _get('catRemove');
  String get catRemoveTitle => _get('catRemoveTitle');
  String get catRemoveBody => _get('catRemoveBody');
  String catNotificationBody(String name) =>
      _get('catNotificationBody').replaceAll('{cat}', name);
  String catHappyPoints(String points) =>
      _get('catHappyPoints').replaceAll('{points}', points);
  String happyPointsEarned(String points) =>
      _get('happyPointsEarned').replaceAll('{points}', points);
  String get catShop => _get('catShop');
  String get shopShort => _get('shopShort');
  String get catShopBody => _get('catShopBody');
  String get catInventory => _get('catInventory');
  String get wardrobeShort => _get('wardrobeShort');
  String get catInventoryBody => _get('catInventoryBody');
  String get catInventoryKittenBody => _get('catInventoryKittenBody');
  String inventoryOwnedCount(int count) => count == 1
      ? _get('inventoryOwnedOne')
      : _get('inventoryOwnedCount').replaceAll('{count}', count.toString());
  String get inventoryEmpty => _get('inventoryEmpty');
  String get inventoryAdultOnly => _get('inventoryAdultOnly');
  String shopBalance(String points) =>
      _get('shopBalance').replaceAll('{points}', points);
  String get shopBuy => _get('shopBuy');
  String get shopEquip => _get('shopEquip');
  String get shopEquipped => _get('shopEquipped');
  String get shopUnequip => _get('shopUnequip');
  String get shopOwned => _get('shopOwned');
  String get shopNotEnough => _get('shopNotEnough');
  String shopPurchased(String item) =>
      _get('shopPurchased').replaceAll('{item}', item);
  String get shopHats => _get('shopHats');
  String get shopGlasses => _get('shopGlasses');
  String get shopNeckwear => _get('shopNeckwear');
  String get shopOutfits => _get('shopOutfits');
  String get shopToys => _get('shopToys');
  String medicationStreak(int days) =>
      _get('medicationStreak').replaceAll('{days}', days.toString());
  String medicationStreakBest(int days) =>
      _get('medicationStreakBest').replaceAll('{days}', days.toString());
  String get shopRegularItems => _get('shopRegularItems');
  String get shopStreakItems => _get('shopStreakItems');
  String shopStreakSummary(int current, int best) => _get('shopStreakSummary')
      .replaceAll('{current}', current.toString())
      .replaceAll('{best}', best.toString());
  String shopStreakRequirement(int days) =>
      _get('shopStreakRequirement').replaceAll('{days}', days.toString());
  String shopStreakLocked(int days) =>
      _get('shopStreakLocked').replaceAll('{days}', days.toString());
  String get shopStreakClaim => _get('shopStreakClaim');
  String get catWantsToPlay => _get('catWantsToPlay');
  String catPlayTooltip(String name) =>
      _get('catPlayTooltip').replaceAll('{cat}', name);
  String get catPlayedTitle => _get('catPlayedTitle');
  String catPlayedBody(String name) =>
      _get('catPlayedBody').replaceAll('{cat}', name);
  String get settings => _get('settings');
  String get specialCodes => _get('specialCodes');
  String get specialCodesBody => _get('specialCodesBody');
  String get specialCodeLabel => _get('specialCodeLabel');
  String get specialCodeRedeem => _get('specialCodeRedeem');
  String get specialCodeRequired => _get('specialCodeRequired');
  String get specialCodeNeedsCat => _get('specialCodeNeedsCat');
  String get specialCodeInvalid => _get('specialCodeInvalid');
  String get specialCodeAlreadyUsed => _get('specialCodeAlreadyUsed');
  String get specialCodeFailed => _get('specialCodeFailed');
  String get specialCodeRedeemed => _get('specialCodeRedeemed');
  String get aboutApp => _get('aboutApp');
  String get madeBy => _get('madeBy');
  String appVersion(String version) =>
      _get('appVersion').replaceAll('{version}', version);
  String get shareApp => _get('shareApp');
  String get shareAppBody => _get('shareAppBody');
  String get copyDownloadLink => _get('copyDownloadLink');
  String get downloadOrUpdate => _get('downloadOrUpdate');
  String get appLinkCopied => _get('appLinkCopied');
  String get appLinkOpenFailed => _get('appLinkOpenFailed');
  String get contact => _get('contact');
  String get contactBody => _get('contactBody');
  String get contactAction => _get('contactAction');
  String get contactSubject => _get('contactSubject');
  String get contactReplyEmail => _get('contactReplyEmail');
  String get contactEmailInvalid => _get('contactEmailInvalid');
  String get contactSubjectLabel => _get('contactSubjectLabel');
  String get contactSubjectRequired => _get('contactSubjectRequired');
  String get contactMessage => _get('contactMessage');
  String get contactMessageRequired => _get('contactMessageRequired');
  String get contactSend => _get('contactSend');
  String get contactSent => _get('contactSent');
  String get contactSendFailed => _get('contactSendFailed');
  String get contactRelayUnavailable => _get('contactRelayUnavailable');
  String get contactPrivacyBody => _get('contactPrivacyBody');
  String get contactTestBuildNotice => _get('contactTestBuildNotice');
  String get buyMeCoffee => _get('buyMeCoffee');
  String get buyMeCoffeeBody => _get('buyMeCoffeeBody');
  String get paypalPayment => _get('paypalPayment');
  String get buyMeCoffeeAction => _get('buyMeCoffeeAction');
  String get buyMeCoffeeOpenFailed => _get('buyMeCoffeeOpenFailed');

  String weekdayShort(int weekday) {
    const en = <String>['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const nl = <String>['Ma', 'Di', 'Wo', 'Do', 'Vr', 'Za', 'Zo'];
    final values = locale.languageCode == 'nl' ? nl : en;
    return values[(weekday - 1).clamp(0, 6)];
  }
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      const <String>['en', 'nl'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) =>
      SynchronousFuture<AppLocalizations>(AppLocalizations(locale));

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) =>
      false;
}
