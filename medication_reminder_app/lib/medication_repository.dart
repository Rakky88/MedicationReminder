import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'medication.dart';

class MedicationRepository {
  MedicationRepository._();

  static final MedicationRepository instance = MedicationRepository._();

  static const _medicationsKey = 'medications_v1';
  static const _doseLogsKey = 'dose_logs_v1';
  static const _hiddenDoseLogIdsKey = 'hidden_dose_log_ids_v1';
  static const _nextIdKey = 'next_medication_id';
  static const _localeKey = 'preferred_locale';
  static const _legacyLogKey = 'med_log_entries';
  static const reconciliationLookback = Duration(days: 45);

  Future<List<Medication>> getMedications({DateTime? migrationAt}) async {
    final prefs = await SharedPreferences.getInstance();
    final medications = _decodeList(
      prefs.getString(_medicationsKey),
      Medication.fromJson,
    ).where(_isValidMedication).toList();
    final migratedAt = (migrationAt ?? DateTime.now()).toLocal();
    var changed = false;
    for (var index = 0; index < medications.length; index++) {
      final medication = medications[index];
      final createdAt = medication.createdAt ?? migratedAt;
      final scheduleStartedAt = <String, DateTime>{
        for (final key in medication.scheduleKeys)
          key: medication.scheduleStartedAt[key] ?? migratedAt,
      };
      if (medication.createdAt == null ||
          !_dateTimeMapsEqual(
            medication.scheduleStartedAt,
            scheduleStartedAt,
          )) {
        medications[index] = medication.copyWith(
          createdAt: createdAt,
          scheduleStartedAt: scheduleStartedAt,
        );
        changed = true;
      }
    }
    if (changed) {
      await _saveMedications(prefs, medications);
    }
    medications.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );
    return medications;
  }

  Future<Medication> saveMedication(
    Medication medication, {
    DateTime? at,
  }) async {
    final now = (at ?? DateTime.now()).toLocal();
    final prefs = await SharedPreferences.getInstance();
    final medications = await getMedications(migrationAt: now);
    var saved = medication.createdAt == null
        ? medication.copyWith(createdAt: now)
        : medication;
    final existingIndex = medication.id == 0
        ? -1
        : medications.indexWhere((item) => item.id == medication.id);
    final existing = existingIndex == -1 ? null : medications[existingIndex];
    final reenabled = existing != null && !existing.enabled && saved.enabled;
    final scheduleStartedAt = <String, DateTime>{
      for (final key in saved.scheduleKeys)
        key: reenabled
            ? now
            : existing?.scheduleStartedAt[key] ??
                  (existing != null && existing.scheduleKeys.contains(key)
                      ? existing.createdAt ?? now
                      : now),
    };
    saved = saved.copyWith(scheduleStartedAt: scheduleStartedAt);

    if (medication.id == 0) {
      var nextId = prefs.getInt(_nextIdKey) ?? 1;
      for (final existingMedication in medications) {
        if (existingMedication.id >= nextId) {
          nextId = existingMedication.id + 1;
        }
      }
      saved = saved.copyWith(id: nextId);
      await prefs.setInt(_nextIdKey, nextId + 1);
      medications.add(saved);
    } else {
      if (existingIndex == -1) {
        medications.add(saved);
      } else {
        medications[existingIndex] = saved;
      }
    }
    await _saveMedications(prefs, medications);
    return saved;
  }

  Future<void> deleteMedication(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final medications = await getMedications();
    medications.removeWhere((item) => item.id == id);
    await _saveMedications(prefs, medications);
  }

  Future<List<DoseLog>> getDoseLogs({bool includeHidden = false}) async {
    final prefs = await SharedPreferences.getInstance();
    var logs = _decodeList(
      prefs.getString(_doseLogsKey),
      DoseLog.fromJson,
    ).where(_isValidDoseLog).toList();
    if (logs.isEmpty) {
      logs = await _migrateLegacyLogs(prefs);
    }
    if (!includeHidden) {
      final hiddenIds = prefs.getStringList(_hiddenDoseLogIdsKey)?.toSet();
      if (hiddenIds != null && hiddenIds.isNotEmpty) {
        logs.removeWhere((log) => hiddenIds.contains(log.id));
      }
    }
    logs.sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
    return logs;
  }

  Future<DoseLog?> recordDose(
    Medication medication,
    DoseStatus status, {
    String? doseKey,
    DateTime? recordedAt,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final logs = await getDoseLogs(includeHidden: true);
    final now = recordedAt ?? DateTime.now();
    final resolvedDoseKey = doseKey ?? medication.nearestDoseSlot(now)?.key;
    final scheduledAt = resolvedDoseKey == null
        ? now
        : scheduledAtFromDoseKey(resolvedDoseKey) ?? now;
    final effectiveRecordedAt = scheduledAt.isAfter(now) ? scheduledAt : now;

    final duplicate = logs.any(
      (log) =>
          log.medicationId == medication.id &&
          (resolvedDoseKey != null
              ? log.doseKey == resolvedDoseKey
              : now.difference(log.recordedAt.toLocal()).abs() <
                    const Duration(minutes: 2)),
    );
    if (duplicate) return null;

    final log = DoseLog(
      id: now.microsecondsSinceEpoch.toString(),
      medicationId: medication.id,
      medicationName: medication.name,
      dosage: medication.dosage,
      recordedAt: effectiveRecordedAt,
      status: status,
      doseKey: resolvedDoseKey,
    );
    logs.insert(0, log);
    if (logs.length > 1000) logs.removeRange(1000, logs.length);
    await _saveLogs(prefs, logs);
    return log;
  }

  Future<List<DoseLog>> reconcileMissedDoses(
    List<Medication> medications, {
    DateTime? at,
  }) async {
    final now = (at ?? DateTime.now()).toLocal();
    final prefs = await SharedPreferences.getInstance();
    final logs = await getDoseLogs(includeHidden: true);
    final loggedKeys = logs
        .map((log) => log.doseKey)
        .whereType<String>()
        .toSet();
    final occurrences = <({Medication medication, MedicationDoseSlot slot})>[];

    for (final medication in medications.where((item) => item.enabled)) {
      final createdAt = medication.createdAt?.toLocal() ?? now;
      final lookbackStart = now.subtract(reconciliationLookback);
      final start = createdAt.isAfter(lookbackStart)
          ? createdAt
          : lookbackStart;
      if (start.isAfter(now)) continue;
      for (final slot in medication.occurrencesBetween(start, now)) {
        occurrences.add((medication: medication, slot: slot));
      }
    }
    if (occurrences.isEmpty) return logs;
    occurrences.sort(
      (left, right) => left.slot.scheduledAt.compareTo(right.slot.scheduledAt),
    );
    final newestAlarmTime = occurrences.last.slot.scheduledAt;
    var changed = false;
    for (final occurrence in occurrences) {
      if (!occurrence.slot.scheduledAt.isBefore(newestAlarmTime) ||
          loggedKeys.contains(occurrence.slot.key)) {
        continue;
      }
      logs.add(
        DoseLog(
          id: 'auto-missed-${occurrence.slot.key}',
          medicationId: occurrence.medication.id,
          medicationName: occurrence.medication.name,
          dosage: occurrence.medication.dosage,
          recordedAt: occurrence.slot.scheduledAt,
          status: DoseStatus.skipped,
          doseKey: occurrence.slot.key,
        ),
      );
      loggedKeys.add(occurrence.slot.key);
      changed = true;
    }
    if (changed) {
      logs.sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));
      if (logs.length > 1000) logs.removeRange(1000, logs.length);
      await _saveLogs(prefs, logs);
    }
    return logs;
  }

  Future<void> deleteDoseLog(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final logs = await getDoseLogs(includeHidden: true);
    logs.removeWhere((log) => log.id == id);
    await _saveLogs(prefs, logs);
  }

  /// Hides a history row without deleting the canonical dose resolution.
  ///
  /// Reconciliation and pet health continue to see the dose, preventing a
  /// cleared/swiped history entry from returning as a newly missed dose.
  Future<void> hideDoseLog(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final logs = await getDoseLogs(includeHidden: true);
    if (!logs.any((log) => log.id == id)) return;
    final hiddenIds =
        prefs.getStringList(_hiddenDoseLogIdsKey)?.toSet() ?? <String>{};
    hiddenIds.add(id);
    await prefs.setStringList(_hiddenDoseLogIdsKey, hiddenIds.toList()..sort());
  }

  Future<void> clearDoseLogs() async {
    final prefs = await SharedPreferences.getInstance();
    final logs = await getDoseLogs(includeHidden: true);
    await prefs.setStringList(
      _hiddenDoseLogIdsKey,
      logs.map((log) => log.id).toSet().toList()..sort(),
    );
    await prefs.remove(_legacyLogKey);
  }

  Future<String?> getPreferredLocale() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_localeKey);
  }

  Future<void> setPreferredLocale(String languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, languageCode);
  }

  Future<void> _saveMedications(
    SharedPreferences prefs,
    List<Medication> medications,
  ) async {
    await prefs.setString(
      _medicationsKey,
      jsonEncode(medications.map((item) => item.toJson()).toList()),
    );
  }

  Future<void> _saveLogs(SharedPreferences prefs, List<DoseLog> logs) async {
    await prefs.setString(
      _doseLogsKey,
      jsonEncode(logs.map((item) => item.toJson()).toList()),
    );
    final storedHiddenIds = prefs.getStringList(_hiddenDoseLogIdsKey);
    if (storedHiddenIds == null || storedHiddenIds.isEmpty) return;
    final validIds = logs.map((log) => log.id).toSet();
    final retainedHiddenIds =
        storedHiddenIds.where(validIds.contains).toSet().toList()..sort();
    if (retainedHiddenIds.isEmpty) {
      await prefs.remove(_hiddenDoseLogIdsKey);
    } else {
      await prefs.setStringList(_hiddenDoseLogIdsKey, retainedHiddenIds);
    }
  }

  List<T> _decodeList<T>(
    String? source,
    T Function(Map<String, Object?>) decode,
  ) {
    if (source == null || source.isEmpty) return <T>[];
    try {
      final decoded = jsonDecode(source);
      if (decoded is! List<dynamic>) return <T>[];
      final values = <T>[];
      for (final value in decoded.whereType<Map<dynamic, dynamic>>()) {
        try {
          values.add(decode(Map<String, Object?>.from(value)));
        } on Object {
          // Keep valid records usable when one stored record is damaged.
        }
      }
      return values;
    } on Object {
      return <T>[];
    }
  }

  bool _isValidMedication(Medication medication) =>
      medication.id > 0 &&
      medication.name.trim().isNotEmpty &&
      medication.times.isNotEmpty &&
      medication.weekdays.isNotEmpty;

  bool _isValidDoseLog(DoseLog log) =>
      log.id.trim().isNotEmpty && log.recordedAt.millisecondsSinceEpoch > 0;

  bool _dateTimeMapsEqual(
    Map<String, DateTime> left,
    Map<String, DateTime> right,
  ) {
    if (left.length != right.length) return false;
    for (final entry in left.entries) {
      if (right[entry.key] != entry.value) return false;
    }
    return true;
  }

  Future<List<DoseLog>> _migrateLegacyLogs(SharedPreferences prefs) async {
    final oldEntries = prefs.getStringList(_legacyLogKey) ?? const <String>[];
    if (oldEntries.isEmpty) return <DoseLog>[];
    final logs = oldEntries
        .map(DateTime.tryParse)
        .whereType<DateTime>()
        .map(
          (date) => DoseLog(
            id: 'legacy-${date.microsecondsSinceEpoch}',
            medicationId: 0,
            medicationName: 'Medication',
            dosage: '',
            recordedAt: date,
            status: DoseStatus.taken,
          ),
        )
        .toList();
    await _saveLogs(prefs, logs);
    await prefs.remove(_legacyLogKey);
    return logs;
  }
}
