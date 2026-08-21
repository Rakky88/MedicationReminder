import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'async_operation_queue.dart';
import 'medication.dart';
import 'medication_streak.dart';

class MedicationStreakRepository {
  MedicationStreakRepository._();

  static final MedicationStreakRepository instance =
      MedicationStreakRepository._();
  static const preferencesKey = 'medication_streak_v1';

  final AsyncOperationQueue _operations = AsyncOperationQueue();

  Future<MedicationStreakState> getState() => _operations.run(_getState);

  Future<MedicationStreakState> _getState() async {
    final prefs = await SharedPreferences.getInstance();
    final source = prefs.getString(preferencesKey);
    if (source == null || source.isEmpty) return MedicationStreakState.empty;
    try {
      return MedicationStreakState.fromJson(
        Map<String, Object?>.from(jsonDecode(source) as Map<dynamic, dynamic>),
      );
    } on FormatException {
      rethrow;
    } on Object catch (error) {
      throw FormatException(
        'Stored medication streak could not be decoded.',
        error,
      );
    }
  }

  Future<MedicationStreakState> synchronize({
    required List<Medication> medications,
    required List<DoseLog> logs,
    DateTime? at,
    Set<String> invalidatedDays = const <String>{},
  }) => _operations.run(
    () => _synchronize(
      medications: medications,
      logs: logs,
      at: at,
      invalidatedDays: invalidatedDays,
    ),
  );

  Future<MedicationStreakState> _synchronize({
    required List<Medication> medications,
    required List<DoseLog> logs,
    DateTime? at,
    required Set<String> invalidatedDays,
  }) async {
    final now = (at ?? DateTime.now()).toLocal();
    final today = DateTime(now.year, now.month, now.day);
    final todayKey = medicationStreakDayKey(today);
    final existing = await _getState();
    final results = <String, MedicationStreakDayResult>{...existing.dayResults};
    final repairStart = DateTime(today.year, today.month, today.day - 8);

    // Today's schedule may still change. Explicit invalidation is used by Undo.
    results.remove(todayKey);
    for (final day in invalidatedDays) {
      results.remove(day);
    }

    final candidates = <String>{todayKey, ...invalidatedDays};
    candidates.addAll(
      results.keys.where((key) {
        final day = parseMedicationStreakDay(key);
        return day != null &&
            !day.isBefore(repairStart) &&
            results[key] == MedicationStreakDayResult.failed;
      }),
    );
    for (final log in logs) {
      if (log.doseKey == null) continue;
      candidates.add(medicationStreakDayKey(log.scheduledAt));
    }

    DateTime? scanStart;
    if (results.isNotEmpty) {
      final latest = results.keys
          .map(parseMedicationStreakDay)
          .whereType<DateTime>()
          .reduce((left, right) => left.isAfter(right) ? left : right);
      scanStart = latest;
    } else {
      final starts = <DateTime>[
        for (final medication in medications)
          if (medication.createdAt != null) medication.createdAt!.toLocal(),
        for (final log in logs)
          if (log.doseKey != null) log.scheduledAt.toLocal(),
      ];
      if (starts.isNotEmpty) {
        scanStart = starts.reduce(
          (left, right) => left.isBefore(right) ? left : right,
        );
      }
    }
    if (scanStart != null) {
      var day = DateTime(scanStart.year, scanStart.month, scanStart.day);
      while (!day.isAfter(today)) {
        candidates.add(medicationStreakDayKey(day));
        day = DateTime(day.year, day.month, day.day + 1);
      }
    }

    final orderedCandidates =
        candidates
            .map(parseMedicationStreakDay)
            .whereType<DateTime>()
            .where((day) => !day.isAfter(today))
            .toList()
          ..sort();
    for (final day in orderedCandidates) {
      final key = medicationStreakDayKey(day);
      final mustRecalculate =
          key == todayKey ||
          invalidatedDays.contains(key) ||
          (!day.isBefore(repairStart) &&
              results[key] == MedicationStreakDayResult.failed);
      if (results.containsKey(key) && !mustRecalculate) continue;
      final outcome = _outcomeForDay(
        day: day,
        now: now,
        medications: medications,
        logs: logs,
      );
      if (outcome == null) {
        results.remove(key);
      } else {
        results[key] = outcome;
      }
    }

    final updated = MedicationStreakState(dayResults: results);
    final prefs = await SharedPreferences.getInstance();
    final stored = await prefs.setString(
      preferencesKey,
      jsonEncode(updated.toJson()),
    );
    if (!stored) {
      throw StateError('Could not persist local medication streak data.');
    }
    return updated;
  }

  MedicationStreakDayResult? _outcomeForDay({
    required DateTime day,
    required DateTime now,
    required List<Medication> medications,
    required List<DoseLog> logs,
  }) {
    final nextDay = DateTime(day.year, day.month, day.day + 1);
    final end = nextDay.subtract(const Duration(microseconds: 1));
    final dayLogs = logs.where((log) {
      return log.doseKey != null &&
          medicationStreakDayKey(log.scheduledAt) ==
              medicationStreakDayKey(day);
    }).toList();
    final expectedSlots =
        <String, ({Medication medication, MedicationDoseSlot slot})>{
          for (final medication in medications.where((item) => item.enabled))
            for (final slot in medication.occurrencesBetween(day, end))
              slot.key: (medication: medication, slot: slot),
        };
    final expectedKeys = <String>{
      ...expectedSlots.keys,
      for (final log in dayLogs) log.doseKey!,
    };
    if (expectedKeys.isEmpty) return null;

    final skippedKeys = dayLogs
        .where((log) => log.status == DoseStatus.skipped)
        .map((log) => log.doseKey!)
        .toSet();
    if (skippedKeys.isNotEmpty) return MedicationStreakDayResult.failed;

    final takenKeys = dayLogs
        .where((log) => log.status == DoseStatus.taken)
        .map((log) => log.doseKey!)
        .toSet();
    if (expectedKeys.every(takenKeys.contains)) {
      return MedicationStreakDayResult.success;
    }
    for (final entry in expectedSlots.entries) {
      if (takenKeys.contains(entry.key)) continue;
      final nextSameAlarm = _nextSameAlarm(
        medication: entry.value.medication,
        slot: entry.value.slot,
      );
      if (nextSameAlarm != null && !now.isBefore(nextSameAlarm)) {
        return MedicationStreakDayResult.failed;
      }
    }
    return null;
  }

  DateTime? _nextSameAlarm({
    required Medication medication,
    required MedicationDoseSlot slot,
  }) {
    final time =
        '${slot.scheduledAt.hour.toString().padLeft(2, '0')}:'
        '${slot.scheduledAt.minute.toString().padLeft(2, '0')}';
    if (!medication.times.contains(time)) return null;
    final searchStart = slot.scheduledAt.add(const Duration(minutes: 1));
    final searchEnd = slot.scheduledAt.add(const Duration(days: 8));
    for (final candidate in medication.occurrencesBetween(
      searchStart,
      searchEnd,
    )) {
      if (candidate.scheduledAt.hour == slot.scheduledAt.hour &&
          candidate.scheduledAt.minute == slot.scheduledAt.minute) {
        return candidate.scheduledAt;
      }
    }
    return null;
  }
}
