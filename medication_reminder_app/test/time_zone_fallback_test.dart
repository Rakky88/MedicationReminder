import 'package:flutter_test/flutter_test.dart';
import 'package:medication_reminder_app/time_zone_fallback.dart';
import 'package:timezone/timezone.dart' as tz;

void main() {
  test('fallback names are valid Android fixed-offset zone identifiers', () {
    expect(fixedOffsetTimeZoneId(Duration.zero), 'UTC');
    expect(fixedOffsetTimeZoneId(const Duration(hours: 2)), 'GMT+02:00');
    expect(
      fixedOffsetTimeZoneId(const Duration(hours: -5, minutes: -30)),
      'GMT-05:30',
    );
  });

  test('fallback preserves the entered local wall-clock time', () {
    final location = fixedOffsetTimeZoneLocation(
      offset: const Duration(hours: 2),
      abbreviation: 'CEST',
    );
    final localAlarm = tz.TZDateTime(location, 2026, 8, 15, 8);

    expect(location.name, 'GMT+02:00');
    expect(localAlarm.hour, 8);
    expect(localAlarm.toUtc(), DateTime.utc(2026, 8, 15, 6));
  });
}
