import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:medication_reminder_app/medication.dart';
import 'package:medication_reminder_app/medication_streak.dart';
import 'package:medication_reminder_app/medication_streak_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('a day counts only after every scheduled dose was taken', () async {
    final day = DateTime(2026, 8, 15);
    final medications = <Medication>[
      _medication(1, day, '08:00'),
      _medication(2, day, '12:00'),
      _medication(3, day, '20:00'),
    ];

    final partial = await MedicationStreakRepository.instance.synchronize(
      medications: medications,
      logs: <DoseLog>[
        _log(1, day, '08:00', DoseStatus.taken),
        _log(2, day, '12:00', DoseStatus.taken),
      ],
      at: DateTime(2026, 8, 15, 12, 1),
    );
    expect(partial.current, 0);
    expect(partial.dayResults, isEmpty);

    final complete = await MedicationStreakRepository.instance.synchronize(
      medications: medications,
      logs: <DoseLog>[
        _log(1, day, '08:00', DoseStatus.taken),
        _log(2, day, '12:00', DoseStatus.taken),
        _log(3, day, '20:00', DoseStatus.taken),
      ],
      at: DateTime(2026, 8, 15, 19),
    );
    expect(complete.current, 1);
    expect(complete.best, 1);
  });

  test(
    'one missed dose resets the streak and best remains available',
    () async {
      final monday = DateTime(2026, 8, 10);
      final medication = _medication(
        1,
        monday,
        '08:00',
        weekdays: const <int>[
          DateTime.monday,
          DateTime.tuesday,
          DateTime.wednesday,
        ],
      );
      final logs = <DoseLog>[
        _log(1, monday, '08:00', DoseStatus.taken),
        _log(1, DateTime(2026, 8, 11), '08:00', DoseStatus.taken),
        _log(1, DateTime(2026, 8, 12), '08:00', DoseStatus.skipped),
      ];

      final state = await MedicationStreakRepository.instance.synchronize(
        medications: <Medication>[medication],
        logs: logs,
        at: DateTime(2026, 8, 12, 9),
      );

      expect(state.current, 0);
      expect(state.best, 2);
      expect(state.dayResults['2026-08-12'], MedicationStreakDayResult.failed);
    },
  );

  test('days without medication do not add or break a streak', () async {
    final monday = DateTime(2026, 8, 10);
    final medication = _medication(
      1,
      monday,
      '08:00',
      weekdays: const <int>[DateTime.monday, DateTime.wednesday],
    );
    final state = await MedicationStreakRepository.instance.synchronize(
      medications: <Medication>[medication],
      logs: <DoseLog>[
        _log(1, monday, '08:00', DoseStatus.taken),
        _log(1, DateTime(2026, 8, 12), '08:00', DoseStatus.taken),
      ],
      at: DateTime(2026, 8, 12, 9),
    );

    expect(state.current, 2);
    expect(state.dayResults, isNot(contains('2026-08-11')));
  });

  test('an unresolved dose becomes failed after its calendar day', () async {
    final day = DateTime(2026, 8, 15);
    final state = await MedicationStreakRepository.instance.synchronize(
      medications: <Medication>[_medication(1, day, '08:00')],
      logs: const <DoseLog>[],
      at: DateTime(2026, 8, 16, 1),
    );

    expect(state.current, 0);
    expect(state.dayResults['2026-08-15'], MedicationStreakDayResult.failed);
  });

  test('invalidating a successful day makes undo recalculate it', () async {
    final day = DateTime(2026, 8, 15);
    final medication = _medication(1, day, '08:00');
    final initial = await MedicationStreakRepository.instance.synchronize(
      medications: <Medication>[medication],
      logs: <DoseLog>[_log(1, day, '08:00', DoseStatus.taken)],
      at: DateTime(2026, 8, 15, 9),
    );
    expect(initial.current, 1);

    final undone = await MedicationStreakRepository.instance.synchronize(
      medications: <Medication>[medication],
      logs: const <DoseLog>[],
      at: DateTime(2026, 8, 15, 9),
      invalidatedDays: const <String>{'2026-08-15'},
    );
    expect(undone.current, 0);
    expect(undone.best, 0);
  });

  test('corrupt streak data is reported without being overwritten', () async {
    const corrupt = '{broken';
    SharedPreferences.setMockInitialValues(<String, Object>{
      MedicationStreakRepository.preferencesKey: corrupt,
    });

    await expectLater(
      MedicationStreakRepository.instance.getState(),
      throwsA(isA<FormatException>()),
    );
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(MedicationStreakRepository.preferencesKey), corrupt);
  });

  test('state JSON supports a streak longer than every reward threshold', () {
    final days = <String, MedicationStreakDayResult>{};
    final start = DateTime(2023, 1, 1);
    for (var index = 0; index < 1000; index++) {
      final day = start.add(Duration(days: index));
      days[medicationStreakDayKey(day)] = MedicationStreakDayResult.success;
    }
    final restored = MedicationStreakState.fromJson(
      jsonDecode(jsonEncode(MedicationStreakState(dayResults: days).toJson()))
          as Map<String, Object?>,
    );
    expect(restored.current, 1000);
    expect(restored.best, 1000);
  });
}

Medication _medication(
  int id,
  DateTime createdAt,
  String time, {
  List<int>? weekdays,
}) => Medication(
  id: id,
  name: 'Medication $id',
  dosage: '1',
  times: <String>[time],
  weekdays: weekdays ?? <int>[createdAt.weekday],
  createdAt: createdAt,
  scheduleStartedAt: <String, DateTime>{
    Medication.scheduleKey(createdAt.weekday, time): createdAt,
  },
);

DoseLog _log(int medicationId, DateTime day, String time, DoseStatus status) {
  final dayKey = medicationStreakDayKey(day);
  return DoseLog(
    id: '$medicationId-$dayKey-$time-${status.name}',
    medicationId: medicationId,
    medicationName: 'Medication $medicationId',
    dosage: '1',
    recordedAt: DateTime(day.year, day.month, day.day, 9),
    status: status,
    doseKey: '$medicationId:$dayKey:$time',
  );
}
