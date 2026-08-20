import 'package:flutter_test/flutter_test.dart';
import 'package:medication_reminder_app/reminder_clock.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'package:medication_reminder_app/time_zone_aliases.dart';

void main() {
  tz_data.initializeTimeZones();

  test('all phone time-zone aliases resolve inside the compact database', () {
    expect(timeZoneAliases['Europe/Amsterdam'], 'Europe/Brussels');
    expect(timeZoneAliases, hasLength(257));
    for (final canonical in timeZoneAliases.values) {
      expect(
        () => tz.getLocation(canonical),
        returnsNormally,
        reason: canonical,
      );
    }
  });

  test('uses the configured phone-local wall-clock minute', () {
    final location = tz.getLocation(timeZoneAliases['Europe/Amsterdam']!);
    final now = tz.TZDateTime(location, 2026, 8, 20, 14, 23, 41);
    final result = nextWeeklyReminder(
      location: location,
      now: now,
      weekday: DateTime.thursday,
      hour: 14,
      minute: 24,
    );

    expect(result, tz.TZDateTime(location, 2026, 8, 20, 14, 24));
    expect(result.second, 0);
  });

  test('a minute that already started moves to the next selected week', () {
    final location = tz.getLocation(timeZoneAliases['Europe/Amsterdam']!);
    final now = tz.TZDateTime(location, 2026, 8, 20, 14, 24, 1);
    final result = nextWeeklyReminder(
      location: location,
      now: now,
      weekday: DateTime.thursday,
      hour: 14,
      minute: 24,
    );

    expect(result, tz.TZDateTime(location, 2026, 8, 27, 14, 24));
  });

  test('calendar additions preserve local clock time across DST', () {
    final location = tz.getLocation(timeZoneAliases['Europe/Amsterdam']!);
    final beforeDst = tz.TZDateTime(location, 2026, 3, 22, 8, 15);
    final afterDst = addReminderCalendarDays(beforeDst, 7);

    expect(afterDst, tz.TZDateTime(location, 2026, 3, 29, 8, 15));
    expect(afterDst.timeZoneOffset, isNot(beforeDst.timeZoneOffset));
  });
}
