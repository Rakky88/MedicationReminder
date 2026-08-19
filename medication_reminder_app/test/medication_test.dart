import 'package:flutter_test/flutter_test.dart';
import 'package:medication_reminder_app/medication.dart';
import 'package:medication_reminder_app/notification_models.dart';

void main() {
  test('finds the next configured occurrence', () {
    const medication = Medication(
      id: 1,
      name: 'Vitamin D',
      dosage: '1 tablet',
      times: <String>['08:00', '20:00'],
      weekdays: <int>[DateTime.monday, DateTime.wednesday],
    );

    final next = medication.nextOccurrence(
      after: DateTime(2026, 8, 10, 9), // Monday.
    );

    expect(next, DateTime(2026, 8, 10, 20));
  });

  test('round-trips medication JSON', () {
    final medication = Medication(
      id: 7,
      name: 'Example',
      dosage: '5 mg',
      times: <String>['09:30'],
      weekdays: <int>[DateTime.tuesday],
      enabled: false,
      notificationsOnly: true,
      showNameInNotifications: true,
      allowBeforeDueTimes: <String>{'09:30'},
      scheduleStartedAt: <String, DateTime>{
        '2@09:30': DateTime(2026, 8, 11, 8),
      },
    );

    final decoded = Medication.fromJson(medication.toJson());

    expect(decoded.id, medication.id);
    expect(decoded.name, medication.name);
    expect(decoded.times, medication.times);
    expect(decoded.weekdays, medication.weekdays);
    expect(decoded.enabled, isFalse);
    expect(decoded.notificationsOnly, isTrue);
    expect(decoded.showNameInNotifications, isTrue);
    expect(decoded.allowBeforeDueTimes, <String>{'09:30'});
    expect(decoded.scheduleStartedAt, medication.scheduleStartedAt);
  });

  test('a newly activated schedule does not exist retroactively', () {
    final medication = Medication(
      id: 17,
      name: 'Changed schedule',
      dosage: '',
      times: const <String>['08:00', '12:00'],
      weekdays: const <int>[
        DateTime.monday,
        DateTime.tuesday,
        DateTime.wednesday,
        DateTime.thursday,
        DateTime.friday,
        DateTime.saturday,
        DateTime.sunday,
      ],
      createdAt: DateTime(2026, 8, 1),
      scheduleStartedAt: <String, DateTime>{
        for (
          var weekday = DateTime.monday;
          weekday <= DateTime.sunday;
          weekday++
        )
          '$weekday@08:00': DateTime(2026, 8, 1),
        for (
          var weekday = DateTime.monday;
          weekday <= DateTime.sunday;
          weekday++
        )
          '$weekday@12:00': DateTime(2026, 8, 10, 18),
      },
    );

    final occurrences = medication.occurrencesBetween(
      DateTime(2026, 8, 10),
      DateTime(2026, 8, 11, 12, 1),
    );

    expect(
      occurrences.map((slot) => slot.key),
      containsAll(<String>[
        '17:2026-08-10:08:00',
        '17:2026-08-11:08:00',
        '17:2026-08-11:12:00',
      ]),
    );
    expect(
      occurrences.map((slot) => slot.key),
      isNot(contains('17:2026-08-10:12:00')),
    );
  });

  test('old medication data keeps private names and alarm audio defaults', () {
    final decoded = Medication.fromJson(<String, Object?>{
      'id': 8,
      'name': 'Private medicine',
      'times': <String>['08:00'],
      'weekdays': <int>[DateTime.monday],
    });

    expect(decoded.showNameInNotifications, isFalse);
    expect(decoded.notificationsOnly, isFalse);
  });

  test('notification name is added only when that medication allows it', () {
    const privateMedication = Medication(
      id: 9,
      name: 'Sensitive name',
      dosage: '',
      times: <String>['08:00'],
      weekdays: <int>[DateTime.monday],
    );
    final visibleMedication = privateMedication.copyWith(
      showNameInNotifications: true,
    );

    expect(
      medicationNotificationBody(
        body: 'Time for medication.',
        medication: privateMedication,
        languageCode: 'en',
      ),
      'Time for medication.',
    );
    expect(
      medicationNotificationBody(
        body: 'Tijd voor medicatie.',
        medication: visibleMedication,
        languageCode: 'nl',
      ),
      'Tijd voor medicatie. Medicijn: Sensitive name.',
    );
    expect(
      notificationMedicationSuffix(
        medication: visibleMedication,
        languageCode: 'de',
      ),
      'Medikament: Sensitive name.',
    );
    expect(
      notificationMedicationSuffix(
        medication: visibleMedication,
        languageCode: 'fr',
      ),
      'Médicament: Sensitive name.',
    );
    expect(
      notificationMedicationSuffix(
        medication: visibleMedication,
        languageCode: 'es',
      ),
      'Medicamento: Sensitive name.',
    );
  });

  test('a visible medication name is shortened for readable reminders', () {
    const medication = Medication(
      id: 10,
      name: 'A very long medication name that would crowd the notification',
      dosage: '',
      times: <String>['08:00'],
      weekdays: <int>[DateTime.monday],
      showNameInNotifications: true,
    );

    final body = medicationNotificationBody(
      body: 'Dose time.',
      medication: medication,
      languageCode: 'en',
    );

    expect(body, 'Dose time. Medication: A very long med….');
    expect(body.length, lessThanOrEqualTo(maxNotificationBodyLength));
  });

  test('maps a dose to one safe scheduled slot', () {
    const medication = Medication(
      id: 12,
      name: 'Example',
      dosage: '',
      times: <String>['08:00', '20:00'],
      weekdays: <int>[DateTime.monday],
    );

    final slot = medication.nearestDoseSlot(DateTime(2026, 8, 10, 8, 30));

    expect(slot?.key, '12:2026-08-10:08:00');
    expect(medication.nearestDoseSlot(DateTime(2026, 8, 11, 15)), isNull);
  });

  test('does not show a pre-alarm task unless that timer allows it', () {
    final medication = Medication(
      id: 13,
      name: 'Early task test',
      dosage: '',
      times: <String>['08:00'],
      weekdays: <int>[DateTime.monday],
      createdAt: DateTime(2026, 8, 10, 0, 0),
    );

    final slot = medication.nextActionableDoseSlot(
      now: DateTime(2026, 8, 10, 7, 30),
      completedKeys: const <String>{},
    );

    expect(slot, isNull);
  });

  test(
    'allows an early task completion when the timer explicitly permits it',
    () {
      final medication = Medication(
        id: 14,
        name: 'Early task allowed',
        dosage: '',
        times: <String>['08:00'],
        weekdays: <int>[DateTime.monday],
        allowBeforeDueTimes: const <String>{'08:00'},
        createdAt: DateTime(2026, 8, 10, 0, 0),
      );

      final slot = medication.nextActionableDoseSlot(
        now: DateTime(2026, 8, 10, 7, 30),
        completedKeys: const <String>{},
      );

      expect(slot, isNotNull);
      expect(slot!.scheduledAt, DateTime(2026, 8, 10, 8, 0));
      expect(slot.key, '14:2026-08-10:08:00');
    },
  );

  test('an early-completed dose is excluded from notification scheduling', () {
    const earlyDoseKey = '14:2026-08-10:08:00';

    expect(
      shouldScheduleDoseNotification(
        doseKey: earlyDoseKey,
        resolvedDoseKeys: const <String>{earlyDoseKey},
      ),
      isFalse,
    );
    expect(
      shouldScheduleDoseNotification(
        doseKey: '14:2026-08-17:08:00',
        resolvedDoseKeys: const <String>{earlyDoseKey},
      ),
      isTrue,
    );
  });

  test('early permission applies only to the selected alarm', () {
    final medication = Medication(
      id: 15,
      name: 'Two alarms',
      dosage: '',
      times: const <String>['08:00', '20:00'],
      weekdays: const <int>[DateTime.monday],
      allowBeforeDueTimes: const <String>{'20:00'},
      createdAt: DateTime(2026, 8, 10),
    );

    final actions = medication.actionableDoseSlots(
      now: DateTime(2026, 8, 10, 7, 30),
    );

    expect(actions, hasLength(1));
    expect(actions.single.isEarly, isTrue);
    expect(actions.single.slot.key, '15:2026-08-10:20:00');
  });

  test('legacy early setting migrates to every stored alarm', () {
    final medication = Medication.fromJson(<String, Object?>{
      'id': 16,
      'name': 'Legacy',
      'times': <String>['08:00', '20:00'],
      'weekdays': <int>[DateTime.monday],
      'allowBeforeDueAction': true,
    });

    expect(medication.allowBeforeDueTimes, <String>{'08:00', '20:00'});
  });
}
