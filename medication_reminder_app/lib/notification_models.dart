import 'cat.dart';
import 'medication.dart';

class NotificationCopy {
  const NotificationCopy({
    required this.title,
    required this.body,
    required this.languageCode,
    required this.openAction,
    required this.snoozeAction,
    required this.catBody,
    required this.followUpBody,
    required this.escalatedBody,
  });

  final String title;
  final String body;
  final String languageCode;
  final String openAction;
  final String snoozeAction;
  final String catBody;
  final String followUpBody;
  final String escalatedBody;
}

class NotificationMascot {
  const NotificationMascot({
    required this.name,
    required this.assetPath,
    required this.soundEnabled,
    required this.persistentMeowEnabled,
    this.species = PetSpecies.cat,
    this.hungerPoints = 0,
    this.accessoryAssetPaths = const <String>[],
    this.accessories = const <NotificationMascotAccessory>[],
  });

  final String name;
  final String assetPath;
  final bool soundEnabled;
  final bool persistentMeowEnabled;
  final PetSpecies species;
  final int hungerPoints;
  final List<String> accessoryAssetPaths;
  final List<NotificationMascotAccessory> accessories;

  List<NotificationMascotAccessory> get resolvedAccessories =>
      accessories.isNotEmpty
      ? accessories
      : accessoryAssetPaths
            .map(
              (path) => NotificationMascotAccessory(
                path: path,
                isToy: path.contains('shop_toy_'),
              ),
            )
            .toList(growable: false);
}

class NotificationMascotAccessory {
  const NotificationMascotAccessory({
    required this.path,
    this.scale = 1,
    this.scaleX = 1,
    this.scaleY = 1,
    this.dx = 0,
    this.dy = 0,
    this.isToy = false,
    this.clipRightFraction = 1,
  });

  final String path;
  final double scale;
  final double scaleX;
  final double scaleY;
  final double dx;
  final double dy;
  final bool isToy;
  final double clipRightFraction;
}

class NotificationActionEvent {
  const NotificationActionEvent({
    required this.medicationId,
    required this.actionId,
    this.doseKey,
  });

  final int medicationId;
  final String actionId;
  final String? doseKey;
}

const maxNotificationBodyLength = 82;

bool shouldScheduleDoseNotification({
  required String doseKey,
  required Set<String> resolvedDoseKeys,
}) => !resolvedDoseKeys.contains(doseKey);

String fitNotificationText(
  String value, {
  int maxCharacters = maxNotificationBodyLength,
}) {
  final normalized = value.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (normalized.length <= maxCharacters) return normalized;
  if (maxCharacters <= 1) return '…'.substring(0, maxCharacters);
  final candidate = normalized.substring(0, maxCharacters - 1);
  final lastSpace = candidate.lastIndexOf(' ');
  final cut = lastSpace >= (maxCharacters * .65).floor()
      ? candidate.substring(0, lastSpace)
      : candidate;
  return '${cut.trimRight()}…';
}

String? notificationMedicationSuffix({
  required Medication medication,
  required String languageCode,
}) {
  if (!medication.showNameInNotifications) return null;
  final label = languageCode == 'nl' ? 'Medicijn' : 'Medication';
  final rawName = medication.name.trim();
  final visibleName = rawName.length <= 16
      ? rawName
      : '${rawName.substring(0, 15)}…';
  return '$label: $visibleName.';
}

String medicationNotificationBody({
  required String body,
  required Medication medication,
  required String languageCode,
}) {
  final suffix = notificationMedicationSuffix(
    medication: medication,
    languageCode: languageCode,
  );
  if (suffix == null) return fitNotificationText(body);
  final fittedBody = fitNotificationText(
    body,
    maxCharacters: maxNotificationBodyLength - suffix.length - 1,
  );
  return '$fittedBody $suffix';
}
