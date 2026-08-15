enum MedicationStreakDayResult { success, failed }

class MedicationStreakState {
  const MedicationStreakState({
    this.dayResults = const <String, MedicationStreakDayResult>{},
  });

  static const empty = MedicationStreakState();

  final Map<String, MedicationStreakDayResult> dayResults;

  int get current {
    var value = 0;
    for (final entry in _orderedEntries) {
      value = entry.value == MedicationStreakDayResult.success ? value + 1 : 0;
    }
    return value;
  }

  int get best {
    var value = 0;
    var maximum = 0;
    for (final entry in _orderedEntries) {
      value = entry.value == MedicationStreakDayResult.success ? value + 1 : 0;
      if (value > maximum) maximum = value;
    }
    return maximum;
  }

  List<MapEntry<String, MedicationStreakDayResult>> get _orderedEntries =>
      dayResults.entries.toList()
        ..sort((left, right) => left.key.compareTo(right.key));

  Map<String, Object?> toJson() => <String, Object?>{
    'dayResults': <String, String>{
      for (final entry in dayResults.entries) entry.key: entry.value.name,
    },
  };

  factory MedicationStreakState.fromJson(Map<String, Object?> json) {
    final source = json['dayResults'];
    if (source == null) return empty;
    if (source is! Map<dynamic, dynamic>) {
      throw const FormatException('Invalid medication streak data.');
    }
    final results = <String, MedicationStreakDayResult>{};
    for (final entry in source.entries) {
      if (entry.key is! String || entry.value is! String) {
        throw const FormatException('Invalid medication streak day.');
      }
      final day = parseMedicationStreakDay(entry.key as String);
      final result = MedicationStreakDayResult.values
          .where((candidate) => candidate.name == entry.value)
          .firstOrNull;
      if (day == null ||
          medicationStreakDayKey(day) != entry.key ||
          result == null) {
        throw const FormatException('Invalid medication streak day.');
      }
      results[entry.key as String] = result;
    }
    return MedicationStreakState(dayResults: results);
  }
}

String medicationStreakDayKey(DateTime value) {
  final local = value.toLocal();
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  return '${local.year}-$month-$day';
}

DateTime? parseMedicationStreakDay(String value) {
  final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(value);
  if (match == null) return null;
  final year = int.parse(match.group(1)!);
  final month = int.parse(match.group(2)!);
  final day = int.parse(match.group(3)!);
  final parsed = DateTime(year, month, day);
  return parsed.year == year && parsed.month == month && parsed.day == day
      ? parsed
      : null;
}
