import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:medication_reminder_app/medication.dart';
import 'package:medication_reminder_app/medication_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('persists medications and assigns stable IDs', () async {
    const medication = Medication(
      id: 0,
      name: 'Example',
      dosage: '',
      times: <String>['08:00'],
      weekdays: <int>[DateTime.monday],
    );

    final saved = await MedicationRepository.instance.saveMedication(
      medication,
    );
    final loaded = await MedicationRepository.instance.getMedications();

    expect(saved.id, 1);
    expect(loaded, hasLength(1));
    expect(loaded.single.name, 'Example');
    expect(loaded.single.id, saved.id);
    expect(saved.createdAt, isNotNull);
    expect(loaded.single.createdAt, saved.createdAt);
  });

  test('new medication ID cannot collide with existing stored IDs', () async {
    final existing = Medication(
      id: 7,
      name: 'Existing',
      dosage: '',
      times: const <String>['08:00'],
      weekdays: const <int>[DateTime.monday],
      createdAt: DateTime(2026, 8, 1),
    );
    SharedPreferences.setMockInitialValues(<String, Object>{
      'medications_v1': jsonEncode(<Object?>[existing.toJson()]),
      'next_medication_id': 1,
    });

    final saved = await MedicationRepository.instance.saveMedication(
      const Medication(
        id: 0,
        name: 'New',
        dosage: '',
        times: <String>['09:00'],
        weekdays: <int>[DateTime.monday],
      ),
      at: DateTime(2026, 8, 2),
    );

    expect(saved.id, 8);
    expect(
      (await MedicationRepository.instance.getMedications())
          .map((medication) => medication.id)
          .toSet(),
      <int>{7, 8},
    );
  });

  test('prevents accidental duplicate dose logs', () async {
    const medication = Medication(
      id: 1,
      name: 'Example',
      dosage: '',
      times: <String>['08:00'],
      weekdays: <int>[DateTime.monday],
    );

    final first = await MedicationRepository.instance.recordDose(
      medication,
      DoseStatus.taken,
    );
    final duplicate = await MedicationRepository.instance.recordDose(
      medication,
      DoseStatus.taken,
    );

    expect(first, isNotNull);
    expect(duplicate, isNull);
    expect(await MedicationRepository.instance.getDoseLogs(), hasLength(1));
  });

  test('taken and missed are mutually exclusive for the same alarm', () async {
    final medication = Medication(
      id: 1,
      name: 'Example',
      dosage: '',
      times: const <String>['08:00'],
      weekdays: const <int>[DateTime.monday],
      createdAt: DateTime(2026, 8, 9),
    );
    const key = '1:2026-08-10:08:00';

    final taken = await MedicationRepository.instance.recordDose(
      medication,
      DoseStatus.taken,
      doseKey: key,
      recordedAt: DateTime(2026, 8, 10, 8, 2),
    );
    final missed = await MedicationRepository.instance.recordDose(
      medication,
      DoseStatus.skipped,
      doseKey: key,
      recordedAt: DateTime(2026, 8, 10, 8, 3),
    );

    expect(taken, isNotNull);
    expect(missed, isNull);
    expect(await MedicationRepository.instance.getDoseLogs(), hasLength(1));
  });

  test(
    'an allowed early Taken is stored at alarm time for zero lateness',
    () async {
      final medication = Medication(
        id: 4,
        name: 'Early',
        dosage: '',
        times: const <String>['20:00'],
        weekdays: const <int>[DateTime.monday],
        allowBeforeDueTimes: const <String>{'20:00'},
        createdAt: DateTime(2026, 8, 9),
      );

      final log = await MedicationRepository.instance.recordDose(
        medication,
        DoseStatus.taken,
        doseKey: '4:2026-08-10:20:00',
        recordedAt: DateTime(2026, 8, 10, 18),
      );

      expect(log?.recordedAt, DateTime(2026, 8, 10, 20));
      expect(log?.scheduledAt, DateTime(2026, 8, 10, 20));
    },
  );

  test(
    'an earlier unanswered alarm becomes missed at the next alarm',
    () async {
      final medication = Medication(
        id: 7,
        name: 'Example',
        dosage: '1 tablet',
        times: const <String>['08:00', '13:00'],
        weekdays: const <int>[DateTime.monday],
        createdAt: DateTime(2026, 8, 9),
      );

      final logs = await MedicationRepository.instance.reconcileMissedDoses(
        <Medication>[medication],
        at: DateTime(2026, 8, 10, 13, 1),
      );

      expect(logs, hasLength(1));
      expect(logs.single.doseKey, '7:2026-08-10:08:00');
      expect(logs.single.status, DoseStatus.skipped);
      expect(logs.any((log) => log.doseKey == '7:2026-08-10:13:00'), isFalse);
    },
  );

  test('simultaneous newest alarms both remain unanswered', () async {
    final first = Medication(
      id: 1,
      name: 'First',
      dosage: '',
      times: const <String>['13:00'],
      weekdays: const <int>[DateTime.monday],
      createdAt: DateTime(2026, 8, 9),
    );
    final second = Medication(
      id: 2,
      name: 'Second',
      dosage: '',
      times: const <String>['13:00'],
      weekdays: const <int>[DateTime.monday],
      createdAt: DateTime(2026, 8, 9),
    );

    final logs = await MedicationRepository.instance.reconcileMissedDoses(
      <Medication>[first, second],
      at: DateTime(2026, 8, 10, 13, 1),
    );

    expect(logs, isEmpty);
  });

  test(
    'legacy schedules start at migration time without backfilling',
    () async {
      final legacy = Medication(
        id: 11,
        name: 'Legacy schedule',
        dosage: '',
        times: const <String>['08:00'],
        weekdays: const <int>[
          DateTime.monday,
          DateTime.tuesday,
          DateTime.wednesday,
          DateTime.thursday,
          DateTime.friday,
          DateTime.saturday,
          DateTime.sunday,
        ],
        createdAt: DateTime(2026, 1, 1),
      );
      SharedPreferences.setMockInitialValues(<String, Object>{
        'medications_v1': jsonEncode(<Object?>[legacy.toJson()]),
      });
      final migratedAt = DateTime(2026, 8, 10, 18);

      final medications = await MedicationRepository.instance.getMedications(
        migrationAt: migratedAt,
      );
      final logs = await MedicationRepository.instance.reconcileMissedDoses(
        medications,
        at: migratedAt,
      );

      expect(
        medications.single.scheduleStartedAt.values,
        everyElement(migratedAt),
      );
      expect(logs, isEmpty);
    },
  );

  test('adding an alarm time never creates earlier phantom misses', () async {
    final original = Medication(
      id: 12,
      name: 'Changing schedule',
      dosage: '',
      times: const <String>['08:00'],
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
      },
    );
    SharedPreferences.setMockInitialValues(<String, Object>{
      'medications_v1': jsonEncode(<Object?>[original.toJson()]),
    });
    final editedAt = DateTime(2026, 8, 10, 18);

    final saved = await MedicationRepository.instance.saveMedication(
      original.copyWith(times: const <String>['08:00', '12:00']),
      at: editedAt,
    );
    final logs = await MedicationRepository.instance.reconcileMissedDoses(
      <Medication>[saved],
      at: DateTime(2026, 8, 11, 12, 1),
    );

    expect(saved.scheduleStartedAt['1@12:00'], editedAt);
    expect(saved.scheduleStartedAt['2@12:00'], editedAt);
    expect(
      logs.map((log) => log.doseKey),
      isNot(contains('12:2026-08-10:12:00')),
    );
    expect(logs.map((log) => log.doseKey), contains('12:2026-08-10:08:00'));
  });

  test(
    're-enabling a medication does not fill the disabled interval',
    () async {
      final disabled = Medication(
        id: 13,
        name: 'Paused schedule',
        dosage: '',
        times: const <String>['08:00'],
        weekdays: const <int>[
          DateTime.monday,
          DateTime.tuesday,
          DateTime.wednesday,
          DateTime.thursday,
          DateTime.friday,
          DateTime.saturday,
          DateTime.sunday,
        ],
        enabled: false,
        createdAt: DateTime(2026, 7, 1),
        scheduleStartedAt: <String, DateTime>{
          for (
            var weekday = DateTime.monday;
            weekday <= DateTime.sunday;
            weekday++
          )
            '$weekday@08:00': DateTime(2026, 7, 1),
        },
      );
      SharedPreferences.setMockInitialValues(<String, Object>{
        'medications_v1': jsonEncode(<Object?>[disabled.toJson()]),
      });
      final enabledAt = DateTime(2026, 8, 10, 18);

      final enabled = await MedicationRepository.instance.saveMedication(
        disabled.copyWith(enabled: true),
        at: enabledAt,
      );
      final logs = await MedicationRepository.instance.reconcileMissedDoses(
        <Medication>[enabled],
        at: DateTime(2026, 8, 11, 8, 1),
      );

      expect(enabled.scheduleStartedAt.values, everyElement(enabledAt));
      expect(logs, isEmpty);
    },
  );

  test('missed-dose reconciliation is bounded to recent history', () async {
    final medication = Medication(
      id: 14,
      name: 'Old schedule',
      dosage: '',
      times: const <String>['08:00'],
      weekdays: const <int>[
        DateTime.monday,
        DateTime.tuesday,
        DateTime.wednesday,
        DateTime.thursday,
        DateTime.friday,
        DateTime.saturday,
        DateTime.sunday,
      ],
      createdAt: DateTime(2020, 1, 1),
    );
    final now = DateTime(2026, 8, 10, 8, 1);

    final logs = await MedicationRepository.instance.reconcileMissedDoses(
      <Medication>[medication],
      at: now,
    );

    expect(logs.length, lessThanOrEqualTo(45));
    expect(
      logs.every(
        (log) => !log.scheduledAt.isBefore(
          now.subtract(MedicationRepository.reconciliationLookback),
        ),
      ),
      isTrue,
    );
  });

  test('damaged storage is ignored without throwing', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'medications_v1': '{not a list}',
      'dose_logs_v1': jsonEncode(<Object?>[
        <String, Object?>{'broken': true},
      ]),
    });

    expect(await MedicationRepository.instance.getMedications(), isEmpty);
    expect(await MedicationRepository.instance.getDoseLogs(), isEmpty);
  });

  test('clearing history preserves the canonical dose resolution', () async {
    final medication = Medication(
      id: 1,
      name: 'Example',
      dosage: '',
      times: const <String>['08:00'],
      weekdays: const <int>[DateTime.monday],
      createdAt: DateTime(2026, 8, 9),
    );
    const doseKey = '1:2026-08-10:08:00';
    await MedicationRepository.instance.recordDose(
      medication,
      DoseStatus.taken,
      doseKey: doseKey,
      recordedAt: DateTime(2026, 8, 10, 8, 1),
    );

    await MedicationRepository.instance.clearDoseLogs();

    expect(await MedicationRepository.instance.getDoseLogs(), isEmpty);
    expect(
      await MedicationRepository.instance.getDoseLogs(includeHidden: true),
      hasLength(1),
    );
    expect(
      await MedicationRepository.instance.recordDose(
        medication,
        DoseStatus.skipped,
        doseKey: doseKey,
        recordedAt: DateTime(2026, 8, 10, 8, 2),
      ),
      isNull,
    );
    final reconciled = await MedicationRepository.instance.reconcileMissedDoses(
      <Medication>[medication],
      at: DateTime(2026, 8, 10, 9),
    );
    expect(reconciled, hasLength(1));
    expect(reconciled.single.status, DoseStatus.taken);
  });

  test('swiping a history row hides it without deleting dose state', () async {
    final medication = Medication(
      id: 2,
      name: 'Example',
      dosage: '',
      times: const <String>['10:00'],
      weekdays: const <int>[DateTime.monday],
      createdAt: DateTime(2026, 8, 9),
    );
    final log = await MedicationRepository.instance.recordDose(
      medication,
      DoseStatus.skipped,
      doseKey: '2:2026-08-10:10:00',
      recordedAt: DateTime(2026, 8, 10, 10, 1),
    );

    await MedicationRepository.instance.hideDoseLog(log!.id);

    expect(await MedicationRepository.instance.getDoseLogs(), isEmpty);
    final canonical = await MedicationRepository.instance.getDoseLogs(
      includeHidden: true,
    );
    expect(canonical.single.status, DoseStatus.skipped);
  });
}
