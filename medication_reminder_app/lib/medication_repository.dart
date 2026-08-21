import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'async_operation_queue.dart';
import 'medication.dart';

class MedicationRepository {
  MedicationRepository._();

  static final MedicationRepository instance = MedicationRepository._();
  final AsyncOperationQueue _operations = AsyncOperationQueue();

  static const _medicationsKey = 'medications_v1';
  static const _doseLogsKey = 'dose_logs_v1';
  static const _hiddenDoseLogIdsKey = 'hidden_dose_log_ids_v1';
  static const _nextIdKey = 'next_medication_id';
  static const _localeKey = 'preferred_locale';
  static const _legacyLogKey = 'med_log_entries';
  static const reconciliationLookback = Duration(days: 45);

  Future<List<Medication>> getMedications({DateTime? migrationAt}) =>
      _operations.run(() => _getMedications(migrationAt: migrationAt));

  Future<List<Medication>> _getMedications({DateTime? migrationAt}) async {
    final prefs = await SharedPreferences.getInstance();
    final decodedMedications = _decodeList(
      prefs.getString(_medicationsKey),
      Medication.fromJson,
    );
    final medications = decodedMedications.where(_isValidMedication).toList();
    if (decodedMedications.length != medications.length) {
      throw const FormatException('Invalid medication data was found.');
    }
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

  Future<Medication> saveMedication(Medication medication, {DateTime? at}) =>
      _operations.run(() => _saveMedication(medication, at: at));

  Future<Medication> _saveMedication(
    Medication medication, {
    DateTime? at,
  }) async {
    final now = (at ?? DateTime.now()).toLocal();
    final prefs = await SharedPreferences.getInstance();
    final medications = await _getMedications(migrationAt: now);
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
      await _requireStored(prefs.setInt(_nextIdKey, nextId + 1), _nextIdKey);
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

  Future<void> deleteMedication(int id) =>
      _operations.run(() => _deleteMedication(id));

  Future<void> _deleteMedication(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final medications = await _getMedications();
    medications.removeWhere((item) => item.id == id);
    await _saveMedications(prefs, medications);
  }

  Future<List<DoseLog>> getDoseLogs({bool includeHidden = false}) =>
      _operations.run(() => _getDoseLogs(includeHidden: includeHidden));

  Future<List<DoseLog>> _getDoseLogs({bool includeHidden = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final decodedLogs = _decodeList(
      prefs.getString(_doseLogsKey),
      DoseLog.fromJson,
    );
    var logs = decodedLogs.where(_isValidDoseLog).toList();
    if (decodedLogs.length != logs.length) {
      throw const FormatException('Invalid dose history was found.');
    }
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
  }) => _operations.run(
    () => _recordDose(
      medication,
      status,
      doseKey: doseKey,
      recordedAt: recordedAt,
    ),
  );

  Future<DoseLog?> _recordDose(
    Medication medication,
    DoseStatus status, {
    String? doseKey,
    DateTime? recordedAt,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final logs = await _getDoseLogs(includeHidden: true);
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

    var id = now.microsecondsSinceEpoch.toString();
    for (var suffix = 1; logs.any((log) => log.id == id); suffix++) {
      id = '${now.microsecondsSinceEpoch}-$suffix';
    }
    final log = DoseLog(
      id: id,
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
  }) => _operations.run(() => _reconcileMissedDoses(medications, at: at));

  Future<List<DoseLog>> _reconcileMissedDoses(
    List<Medication> medications, {
    DateTime? at,
  }) async {
    final now = (at ?? DateTime.now()).toLocal();
    final prefs = await SharedPreferences.getInstance();
    final logs = await _getDoseLogs(includeHidden: true);
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
    final newestByAlarm = <String, DateTime>{};
    for (final occurrence in occurrences) {
      final alarm = _alarmSeriesKey(occurrence.medication, occurrence.slot);
      final newest = newestByAlarm[alarm];
      if (newest == null || occurrence.slot.scheduledAt.isAfter(newest)) {
        newestByAlarm[alarm] = occurrence.slot.scheduledAt;
      }
    }
    final occurrenceKeys = occurrences.map((item) => item.slot.key).toSet();
    final expiredKeys = <String>{
      for (final occurrence in occurrences)
        if (occurrence.slot.scheduledAt.isBefore(
          newestByAlarm[_alarmSeriesKey(
            occurrence.medication,
            occurrence.slot,
          )]!,
        ))
          occurrence.slot.key,
    };
    var changed = false;
    // V0.02.05 could prematurely create an automatic miss when a different
    // alarm rang later that day. Repair those derived rows while the original
    // dose is still actionable; explicit user-entered misses are untouched.
    final staleAutomaticKeys = <String>{
      for (final log in logs)
        if (log.doseKey != null &&
            log.id == 'auto-missed-${log.doseKey}' &&
            occurrenceKeys.contains(log.doseKey) &&
            !expiredKeys.contains(log.doseKey))
          log.doseKey!,
    };
    if (staleAutomaticKeys.isNotEmpty) {
      logs.removeWhere(
        (log) =>
            log.doseKey != null &&
            log.id == 'auto-missed-${log.doseKey}' &&
            staleAutomaticKeys.contains(log.doseKey),
      );
      changed = true;
    }
    final loggedKeys = logs
        .map((log) => log.doseKey)
        .whereType<String>()
        .toSet();
    for (final occurrence in occurrences) {
      if (!expiredKeys.contains(occurrence.slot.key) ||
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

  String _alarmSeriesKey(Medication medication, MedicationDoseSlot slot) {
    final hour = slot.scheduledAt.hour.toString().padLeft(2, '0');
    final minute = slot.scheduledAt.minute.toString().padLeft(2, '0');
    return '${medication.id}:$hour:$minute';
  }

  Future<void> deleteDoseLog(String id) =>
      _operations.run(() => _deleteDoseLog(id));

  Future<void> _deleteDoseLog(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final logs = await _getDoseLogs(includeHidden: true);
    logs.removeWhere((log) => log.id == id);
    await _saveLogs(prefs, logs);
  }

  /// Hides a history row without deleting the canonical dose resolution.
  ///
  /// Reconciliation and pet health continue to see the dose, preventing a
  /// cleared/swiped history entry from returning as a newly missed dose.
  Future<void> hideDoseLog(String id) =>
      _operations.run(() => _hideDoseLog(id));

  Future<void> _hideDoseLog(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final logs = await _getDoseLogs(includeHidden: true);
    if (!logs.any((log) => log.id == id)) return;
    final hiddenIds =
        prefs.getStringList(_hiddenDoseLogIdsKey)?.toSet() ?? <String>{};
    hiddenIds.add(id);
    await _requireStored(
      prefs.setStringList(_hiddenDoseLogIdsKey, hiddenIds.toList()..sort()),
      _hiddenDoseLogIdsKey,
    );
  }

  Future<void> clearDoseLogs() => _operations.run(_clearDoseLogs);

  Future<void> _clearDoseLogs() async {
    final prefs = await SharedPreferences.getInstance();
    final logs = await _getDoseLogs(includeHidden: true);
    await _requireStored(
      prefs.setStringList(
        _hiddenDoseLogIdsKey,
        logs.map((log) => log.id).toSet().toList()..sort(),
      ),
      _hiddenDoseLogIdsKey,
    );
    await prefs.remove(_legacyLogKey);
  }

  Future<String?> getPreferredLocale() => _operations.run(_getPreferredLocale);

  Future<String?> _getPreferredLocale() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_localeKey);
  }

  Future<void> setPreferredLocale(String languageCode) =>
      _operations.run(() => _setPreferredLocale(languageCode));

  Future<void> _setPreferredLocale(String languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    await _requireStored(prefs.setString(_localeKey, languageCode), _localeKey);
  }

  Future<void> _saveMedications(
    SharedPreferences prefs,
    List<Medication> medications,
  ) async {
    await _requireStored(
      prefs.setString(
        _medicationsKey,
        jsonEncode(medications.map((item) => item.toJson()).toList()),
      ),
      _medicationsKey,
    );
  }

  Future<void> _saveLogs(SharedPreferences prefs, List<DoseLog> logs) async {
    await _requireStored(
      prefs.setString(
        _doseLogsKey,
        jsonEncode(logs.map((item) => item.toJson()).toList()),
      ),
      _doseLogsKey,
    );
    final storedHiddenIds = prefs.getStringList(_hiddenDoseLogIdsKey);
    if (storedHiddenIds == null || storedHiddenIds.isEmpty) return;
    final validIds = logs.map((log) => log.id).toSet();
    final retainedHiddenIds =
        storedHiddenIds.where(validIds.contains).toSet().toList()..sort();
    if (retainedHiddenIds.isEmpty) {
      await prefs.remove(_hiddenDoseLogIdsKey);
    } else {
      await _requireStored(
        prefs.setStringList(_hiddenDoseLogIdsKey, retainedHiddenIds),
        _hiddenDoseLogIdsKey,
      );
    }
  }

  List<T> _decodeList<T>(
    String? source,
    T Function(Map<String, Object?>) decode,
  ) {
    if (source == null || source.isEmpty) return <T>[];
    try {
      final decoded = jsonDecode(source);
      if (decoded is! List<dynamic>) {
        throw const FormatException('Stored data is not a list.');
      }
      final values = <T>[];
      var damagedRecords = 0;
      for (final value in decoded) {
        if (value is! Map<dynamic, dynamic>) {
          damagedRecords++;
          continue;
        }
        try {
          values.add(decode(Map<String, Object?>.from(value)));
        } on Object {
          damagedRecords++;
        }
      }
      if (damagedRecords > 0) {
        throw const FormatException('Damaged stored records were found.');
      }
      return values;
    } on FormatException {
      rethrow;
    } on Object catch (error) {
      throw FormatException('Stored data could not be decoded.', error);
    }
  }

  bool _isValidMedication(Medication medication) =>
      medication.id > 0 &&
      medication.name.trim().isNotEmpty &&
      medication.times.isNotEmpty &&
      medication.times.every(isValidMedicationTime) &&
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

  Future<void> _requireStored(Future<bool> result, String key) async {
    if (!await result) {
      throw StateError('Could not persist local data for $key.');
    }
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
    if (logs.length != oldEntries.length) {
      throw const FormatException('Legacy dose history is damaged.');
    }
    await _saveLogs(prefs, logs);
    await prefs.remove(_legacyLogKey);
    return logs;
  }
}
