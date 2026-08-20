import 'dart:async';

import 'medication.dart';
import 'notification_models.dart';

class NotificationService {
  NotificationService._internal();

  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() => _instance;

  static const openAction = 'open_app';
  static const snoozeAction = 'snooze';

  bool get isSupported => false;
  Stream<NotificationActionEvent> get actions => const Stream.empty();

  Future<void> init() async {}

  Future<void> refreshTimeZone() async {}

  Future<bool> requestPermissions() async => false;

  Future<bool> hasRequiredPermissions() async => true;

  Future<void> syncReminders(
    List<Medication> medications,
    NotificationCopy copy, {
    NotificationMascot? mascot,
    Set<String> resolvedDoseKeys = const <String>{},
  }) async {}

  Future<void> clearReminders() async {}

  Future<void> snoozeMedication(
    Medication medication,
    NotificationCopy copy, {
    Duration delay = const Duration(minutes: 10),
    NotificationMascot? mascot,
    String? doseKey,
  }) async {}

  Future<void> showNotificationNow({
    required NotificationCopy copy,
    NotificationMascot? mascot,
    bool previewSoundInApp = false,
  }) async {}

  Future<int> snoozeEscalation(String doseKey) async => -1;

  Future<void> resolveMedication(int medicationId) async {}

  Future<void> resolveDose(String doseKey) async {}

  NotificationActionEvent? takeInitialAction() => null;
}
