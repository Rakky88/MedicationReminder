import 'package:timezone/timezone.dart' as tz;

/// Returns the first weekly occurrence strictly after [now].
///
/// Constructing the result in [location] keeps medication times tied to the
/// phone's wall clock, including calendar-day changes around daylight saving
/// transitions.
tz.TZDateTime nextWeeklyReminder({
  required tz.Location location,
  required tz.TZDateTime now,
  required int weekday,
  required int hour,
  required int minute,
}) {
  var candidate = tz.TZDateTime(
    location,
    now.year,
    now.month,
    now.day,
    hour,
    minute,
  );
  while (candidate.weekday != weekday || !candidate.isAfter(now)) {
    candidate = tz.TZDateTime(
      location,
      candidate.year,
      candidate.month,
      candidate.day + 1,
      hour,
      minute,
    );
  }
  return candidate;
}

tz.TZDateTime addReminderCalendarDays(tz.TZDateTime value, int days) =>
    tz.TZDateTime(
      value.location,
      value.year,
      value.month,
      value.day + days,
      value.hour,
      value.minute,
    );
