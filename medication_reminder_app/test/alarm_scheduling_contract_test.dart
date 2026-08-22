import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late String notificationSource;
  late String escalationSource;
  late String activitySource;
  late String homeSource;

  setUpAll(() {
    notificationSource = File(
      'lib/notification_service_native.dart',
    ).readAsStringSync();
    escalationSource = File(
      'android/app/src/main/kotlin/com/example/medication_reminder_app/'
      'MedicationEscalation.kt',
    ).readAsStringSync();
    activitySource = File(
      'android/app/src/main/kotlin/com/example/medication_reminder_app/'
      'MainActivity.kt',
    ).readAsStringSync();
    homeSource = File('lib/main.dart').readAsStringSync();
  });

  test('exact alarm access is required instead of silently degrading', () {
    expect(
      notificationSource,
      contains('return await android?.requestExactAlarmsPermission() == true;'),
    );
    expect(
      notificationSource,
      contains('await android?.canScheduleExactNotifications()'),
    );
    expect(
      notificationSource,
      isNot(contains('AndroidScheduleMode.inexactAllowWhileIdle')),
    );
    expect(escalationSource, contains('!exactAllowed -> false'));
    expect(escalationSource, isNot(contains('manager.setAndAllowWhileIdle')));
  });

  test('notification-only mode reaches the Android snooze plan', () {
    expect(
      notificationSource,
      contains(
        "'notificationsOnly': reminder.slot.medication.notificationsOnly",
      ),
    );
    expect(escalationSource, contains('val notificationsOnly: Boolean'));
    expect(
      escalationSource,
      contains('useAlarmAudio = isSnoozeWake && !plan.notificationsOnly'),
    );
  });

  test('every snooze is ten minutes and restores the selected alarm mode', () {
    expect(
      notificationSource,
      contains('useAlarmAudio: !medication.notificationsOnly'),
    );
    expect(escalationSource, contains('plan.snoozeWake = true'));
    expect(
      escalationSource,
      contains(
        'schedule(context, plan, System.currentTimeMillis() + TEN_MINUTES)',
      ),
    );
    expect(escalationSource, contains('AudioAttributes.USAGE_ALARM'));
    expect(escalationSource, contains('AudioAttributes.USAGE_NOTIFICATION'));
    expect(escalationSource, contains('plan.noResponseCount = 0'));
    expect(escalationSource, contains('plan.finished = false'));
    expect(escalationSource, isNot(contains('plan.snoozeCount >= 3')));
  });

  test('an ignored alarm produces three notifications unless persistent', () {
    expect(
      notificationSource,
      contains(
        "'persistentMeowEnabled': mascot?.persistentMeowEnabled ?? false",
      ),
    );
    expect(
      escalationSource,
      contains('json.optBoolean("persistentMeowEnabled", false)'),
    );
    expect(
      escalationSource,
      contains('val reachedLimit = plan.noResponseCount >= 3'),
    );
    expect(
      escalationSource,
      contains('plan.persistentMeowEnabled || !reachedLimit'),
    );
    expect(
      escalationSource,
      contains('System.currentTimeMillis() + FIVE_MINUTES'),
    );
    expect(escalationSource, contains('EscalationStore.finish(context, plan)'));
    expect(escalationSource, contains('filterNot { it.finished }'));
  });

  test('alarm channels are isolated from immutable legacy channels', () {
    expect(notificationSource, contains("medication_alarms_v2"));
    expect(escalationSource, contains('medication_alarms_v2'));
    expect(escalationSource, contains('alarm_voice_'));
    expect(escalationSource, contains('_v2"'));
  });

  test('Taken and Not taken resolve every scheduled part of a dose', () {
    expect(homeSource, contains('await _resolveAlarmSession('));
    expect(notificationSource, contains('_snoozeNotificationId(doseKey)'));
    expect(notificationSource, contains("'resolveDose'"));
    expect(
      escalationSource,
      contains('manager.cancel(alarmIntent(context, plan.token))'),
    );
    expect(
      escalationSource,
      contains('manager.cancel(boundaryIntent(context, plan.token))'),
    );
    expect(
      escalationSource,
      contains('manager.cancel(notificationId(plan.token))'),
    );
    expect(
      escalationSource,
      contains('manager.cancel(plan.baseNotificationId)'),
    );
  });

  test('in-app pet sounds stay on media audio and pet taps respect hunger', () {
    expect(homeSource, contains('_startupPetSoundPlayed = true'));
    expect(homeSource, contains('PetAudio.instance.happy(profile)'));
    expect(homeSource, contains('await PetAudio.instance.interact(cat);'));
    expect(
      File('lib/pet_audio.dart').readAsStringSync(),
      contains('AndroidUsageType.media'),
    );
  });

  test('resume synchronization preserves unresolved current doses', () {
    expect(
      notificationSource,
      contains('await _plugin.cancelAllPendingNotifications();'),
    );
    expect(notificationSource, contains("'resolvedDoseKeys':"));
    expect(activitySource, contains('arguments?.get("resolvedDoseKeys")'));
    expect(activitySource, contains('result.success(everyAlarmScheduled)'));
    expect(escalationSource, contains('val keepCurrent ='));
    expect(escalationSource, contains('existing.token in resolvedDoseKeys'));
    expect(
      escalationSource,
      contains('maxOf(existing.nextAtMillis, now + 10_000L)'),
    );
    expect(escalationSource, contains('!existing.finished'));
  });
}
