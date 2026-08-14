class Medication {
  const Medication({
    required this.id,
    required this.name,
    required this.dosage,
    required this.times,
    required this.weekdays,
    this.enabled = true,
    this.showNameInNotifications = false,
    this.allowBeforeDueTimes = const <String>{},
    this.createdAt,
    this.scheduleStartedAt = const <String, DateTime>{},
  });

  final int id;
  final String name;
  final String dosage;
  final List<String> times;
  final List<int> weekdays;
  final bool enabled;
  final bool showNameInNotifications;
  final Set<String> allowBeforeDueTimes;
  final DateTime? createdAt;
  final Map<String, DateTime> scheduleStartedAt;

  Medication copyWith({
    int? id,
    String? name,
    String? dosage,
    List<String>? times,
    List<int>? weekdays,
    bool? enabled,
    bool? showNameInNotifications,
    Set<String>? allowBeforeDueTimes,
    DateTime? createdAt,
    Map<String, DateTime>? scheduleStartedAt,
  }) {
    return Medication(
      id: id ?? this.id,
      name: name ?? this.name,
      dosage: dosage ?? this.dosage,
      times: times ?? this.times,
      weekdays: weekdays ?? this.weekdays,
      enabled: enabled ?? this.enabled,
      showNameInNotifications:
          showNameInNotifications ?? this.showNameInNotifications,
      allowBeforeDueTimes: allowBeforeDueTimes ?? this.allowBeforeDueTimes,
      createdAt: createdAt ?? this.createdAt,
      scheduleStartedAt: scheduleStartedAt ?? this.scheduleStartedAt,
    );
  }

  Set<String> get scheduleKeys => <String>{
    for (final weekday in weekdays)
      for (final time in times) scheduleKey(weekday, time),
  };

  static String scheduleKey(int weekday, String time) => '$weekday@$time';

  bool isOccurrenceActive(String time, DateTime scheduledAt) {
    final startedAt =
        scheduleStartedAt[scheduleKey(scheduledAt.weekday, time)] ?? createdAt;
    return startedAt == null || !scheduledAt.isBefore(startedAt);
  }

  DateTime? nextOccurrence({DateTime? after}) {
    if (!enabled || times.isEmpty || weekdays.isEmpty) return null;
    final now = after ?? DateTime.now();
    DateTime? next;

    for (var dayOffset = 0; dayOffset <= 7; dayOffset++) {
      final day = DateTime(now.year, now.month, now.day + dayOffset);
      if (!weekdays.contains(day.weekday)) continue;
      for (final value in times) {
        final parts = value.split(':');
        if (parts.length != 2) continue;
        final hour = int.tryParse(parts[0]);
        final minute = int.tryParse(parts[1]);
        if (hour == null || minute == null) continue;
        final candidate = DateTime(day.year, day.month, day.day, hour, minute);
        if (!candidate.isAfter(now)) continue;
        if (!isOccurrenceActive(value, candidate)) continue;
        if (next == null || candidate.isBefore(next)) next = candidate;
      }
    }
    return next;
  }

  MedicationDoseSlot? nextActionableDoseSlot({
    required DateTime now,
    Set<String>? completedKeys,
  }) {
    final actions = actionableDoseSlots(now: now, completedKeys: completedKeys);
    return actions.isEmpty ? null : actions.first.slot;
  }

  List<MedicationDoseAction> actionableDoseSlots({
    required DateTime now,
    Set<String>? completedKeys,
  }) {
    if (!enabled || times.isEmpty || weekdays.isEmpty) {
      return const <MedicationDoseAction>[];
    }
    final completed = completedKeys ?? const <String>{};
    final result = <MedicationDoseAction>[];
    final earliestLimit = now.subtract(const Duration(days: 8));
    final earliest = createdAt != null && createdAt!.isAfter(earliestLimit)
        ? createdAt!
        : earliestLimit;
    final dueSlots = occurrencesBetween(earliest, now)
      ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    for (final slot in dueSlots) {
      if (!completed.contains(slot.key)) {
        result.add(MedicationDoseAction(slot: slot, isEarly: false));
      }
    }

    final today = DateTime(now.year, now.month, now.day);
    if (weekdays.contains(today.weekday)) {
      for (final value in times) {
        if (!allowBeforeDueTimes.contains(value)) continue;
        final scheduled = _dateWithTime(today, value);
        if (scheduled == null || !scheduled.isAfter(now)) continue;
        if (!isOccurrenceActive(value, scheduled)) continue;
        final slot = MedicationDoseSlot(
          key: _doseKey(scheduled, value),
          scheduledAt: scheduled,
        );
        if (!completed.contains(slot.key)) {
          result.add(MedicationDoseAction(slot: slot, isEarly: true));
        }
      }
    }
    result.sort((a, b) => a.slot.scheduledAt.compareTo(b.slot.scheduledAt));
    return result;
  }

  MedicationDoseSlot? nearestDoseSlot(
    DateTime moment, {
    Duration earlyWindow = const Duration(minutes: 90),
    Duration lateWindow = const Duration(hours: 12),
  }) {
    MedicationDoseSlot? closest;
    Duration? closestDistance;
    for (var offset = -1; offset <= 1; offset++) {
      final day = DateTime(moment.year, moment.month, moment.day + offset);
      if (!weekdays.contains(day.weekday)) continue;
      for (final value in times) {
        final scheduled = _dateWithTime(day, value);
        if (scheduled == null) continue;
        if (!isOccurrenceActive(value, scheduled)) continue;
        final difference = moment.difference(scheduled);
        if (difference > lateWindow || difference < -earlyWindow) continue;
        final distance = difference.abs();
        if (closestDistance == null || distance < closestDistance) {
          closestDistance = distance;
          closest = MedicationDoseSlot(
            key: _doseKey(scheduled, value),
            scheduledAt: scheduled,
          );
        }
      }
    }
    return closest;
  }

  List<MedicationDoseSlot> occurrencesBetween(DateTime start, DateTime end) {
    if (end.isBefore(start)) return const <MedicationDoseSlot>[];
    final result = <MedicationDoseSlot>[];
    var day = DateTime(start.year, start.month, start.day);
    final lastDay = DateTime(end.year, end.month, end.day);
    while (!day.isAfter(lastDay)) {
      if (weekdays.contains(day.weekday)) {
        for (final value in times) {
          final scheduled = _dateWithTime(day, value);
          if (scheduled != null &&
              isOccurrenceActive(value, scheduled) &&
              !scheduled.isBefore(start) &&
              !scheduled.isAfter(end)) {
            result.add(
              MedicationDoseSlot(
                key: _doseKey(scheduled, value),
                scheduledAt: scheduled,
              ),
            );
          }
        }
      }
      day = DateTime(day.year, day.month, day.day + 1);
    }
    return result;
  }

  DateTime? _dateWithTime(DateTime day, String value) {
    final parts = value.split(':');
    if (parts.length != 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    return DateTime(day.year, day.month, day.day, hour, minute);
  }

  String _doseKey(DateTime date, String value) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$id:${date.year}-$month-$day:$value';
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'dosage': dosage,
    'times': times,
    'weekdays': weekdays,
    'enabled': enabled,
    'showNameInNotifications': showNameInNotifications,
    'allowBeforeDueTimes': allowBeforeDueTimes.toList()..sort(),
    'createdAt': createdAt?.toUtc().toIso8601String(),
    'scheduleStartedAt': <String, String>{
      for (final entry in scheduleStartedAt.entries)
        entry.key: entry.value.toUtc().toIso8601String(),
    },
  };

  factory Medication.fromJson(Map<String, Object?> json) {
    final times = (json['times'] as List<dynamic>? ?? const <dynamic>[])
        .whereType<String>()
        .toList();
    final storedEarlyTimes = (json['allowBeforeDueTimes'] as List<dynamic>?)
        ?.whereType<String>()
        .where(times.contains)
        .toSet();
    final earlyTimes =
        storedEarlyTimes ??
        (json['allowBeforeDueAction'] == true
            ? Set<String>.from(times)
            : const <String>{});
    return Medication(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? '',
      dosage: json['dosage'] as String? ?? '',
      times: times,
      weekdays: (json['weekdays'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<num>()
          .map((value) => value.toInt())
          .where(
            (value) => value >= DateTime.monday && value <= DateTime.sunday,
          )
          .toList(),
      enabled: json['enabled'] as bool? ?? true,
      showNameInNotifications:
          json['showNameInNotifications'] as bool? ?? false,
      allowBeforeDueTimes: earlyTimes,
      createdAt: DateTime.tryParse(
        json['createdAt'] as String? ?? '',
      )?.toLocal(),
      scheduleStartedAt: _dateTimeMap(json['scheduleStartedAt']),
    );
  }

  static Map<String, DateTime> _dateTimeMap(Object? value) {
    if (value is! Map<dynamic, dynamic>) return const <String, DateTime>{};
    final result = <String, DateTime>{};
    for (final entry in value.entries) {
      if (entry.key is! String || entry.value is! String) continue;
      final parsed = DateTime.tryParse(entry.value as String)?.toLocal();
      if (parsed != null) result[entry.key as String] = parsed;
    }
    return result;
  }
}

enum DoseStatus { taken, skipped }

class DoseLog {
  const DoseLog({
    required this.id,
    required this.medicationId,
    required this.medicationName,
    required this.dosage,
    required this.recordedAt,
    required this.status,
    this.doseKey,
  });

  final String id;
  final int medicationId;
  final String medicationName;
  final String dosage;
  final DateTime recordedAt;
  final DoseStatus status;
  final String? doseKey;

  DateTime get scheduledAt =>
      scheduledAtFromDoseKey(doseKey) ?? recordedAt.toLocal();

  Map<String, Object?> toJson() => {
    'id': id,
    'medicationId': medicationId,
    'medicationName': medicationName,
    'dosage': dosage,
    'recordedAt': recordedAt.toUtc().toIso8601String(),
    'status': status.name,
    'doseKey': doseKey,
  };

  factory DoseLog.fromJson(Map<String, Object?> json) {
    return DoseLog(
      id: json['id'] as String? ?? '',
      medicationId: (json['medicationId'] as num?)?.toInt() ?? 0,
      medicationName: json['medicationName'] as String? ?? 'Medication',
      dosage: json['dosage'] as String? ?? '',
      recordedAt:
          DateTime.tryParse(json['recordedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      status: DoseStatus.values.firstWhere(
        (value) => value.name == json['status'],
        orElse: () => DoseStatus.taken,
      ),
      doseKey: json['doseKey'] as String?,
    );
  }
}

DateTime? scheduledAtFromDoseKey(String? key) {
  if (key == null) return null;
  final parts = key.split(':');
  if (parts.length < 4) return null;
  final date = DateTime.tryParse(parts[1]);
  final hour = int.tryParse(parts[2]);
  final minute = int.tryParse(parts[3]);
  if (date == null || hour == null || minute == null) return null;
  return DateTime(date.year, date.month, date.day, hour, minute);
}

class MedicationDoseSlot {
  const MedicationDoseSlot({required this.key, required this.scheduledAt});

  final String key;
  final DateTime scheduledAt;
}

class MedicationDoseAction {
  const MedicationDoseAction({required this.slot, required this.isEarly});

  final MedicationDoseSlot slot;
  final bool isEarly;
}
