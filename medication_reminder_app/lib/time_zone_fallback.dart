import 'package:timezone/timezone.dart' as tz;

/// Returns a Java/Android-compatible fixed-offset zone identifier.
///
/// `flutter_local_notifications` passes [tz.Location.name] to Android's
/// `ZoneId.of`. A descriptive placeholder such as `device-local-fallback`
/// therefore cannot be used as the location name.
String fixedOffsetTimeZoneId(Duration offset) {
  final totalMinutes = offset.inMinutes;
  if (totalMinutes == 0) return 'UTC';
  final absoluteMinutes = totalMinutes.abs();
  final hours = (absoluteMinutes ~/ 60).toString().padLeft(2, '0');
  final minutes = (absoluteMinutes % 60).toString().padLeft(2, '0');
  final sign = totalMinutes.isNegative ? '-' : '+';
  return 'GMT$sign$hours:$minutes';
}

tz.Location fixedOffsetTimeZoneLocation({
  required Duration offset,
  required String abbreviation,
}) {
  return tz.Location(
    fixedOffsetTimeZoneId(offset),
    const <int>[tz.minTime],
    const <int>[0],
    <tz.TimeZone>[
      tz.TimeZone(offset, isDst: false, abbreviation: abbreviation),
    ],
  );
}
