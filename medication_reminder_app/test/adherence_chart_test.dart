import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:medication_reminder_app/adherence_chart_screen.dart';
import 'package:medication_reminder_app/medication.dart';

void main() {
  setUpAll(() => initializeDateFormatting('en'));

  DoseLog log(String id, String key, DoseStatus status) => DoseLog(
    id: id,
    medicationId: 1,
    medicationName: 'Example',
    dosage: '',
    recordedAt: scheduledAtFromDoseKey(key)!,
    status: status,
    doseKey: key,
  );

  test('week graph separates taken and missed doses by day', () {
    final buckets = buildAdherenceBuckets(
      <DoseLog>[
        log('a', '1:2026-08-10:08:00', DoseStatus.taken),
        log('b', '1:2026-08-10:20:00', DoseStatus.skipped),
        log('c', '1:2026-08-12:08:00', DoseStatus.taken),
      ],
      AdherencePeriod.week,
      DateTime(2026, 8, 12),
      locale: 'en',
    );

    expect(buckets, hasLength(7));
    expect(buckets[0].taken, 1);
    expect(buckets[0].missed, 1);
    expect(buckets[2].taken, 1);
    expect(buckets[2].missed, 0);
  });

  test('year graph groups dose history into twelve months', () {
    final buckets = buildAdherenceBuckets(
      <DoseLog>[
        log('a', '1:2026-01-10:08:00', DoseStatus.skipped),
        log('b', '1:2026-08-10:08:00', DoseStatus.taken),
      ],
      AdherencePeriod.year,
      DateTime(2026, 8, 12),
      locale: 'en',
    );

    expect(buckets, hasLength(12));
    expect(buckets.first.missed, 1);
    expect(buckets[7].taken, 1);
  });

  test('month graph keeps every calendar day across daylight saving', () {
    final buckets = buildAdherenceBuckets(
      <DoseLog>[
        log('a', '1:2026-03-30:08:00', DoseStatus.taken),
        log('b', '1:2026-03-31:08:00', DoseStatus.skipped),
      ],
      AdherencePeriod.month,
      DateTime(2026, 3, 15),
      locale: 'en',
    );

    expect(buckets, hasLength(31));
    expect(buckets[29].taken, 1);
    expect(buckets[30].missed, 1);
  });

  test('all graph creates one bucket for every represented year', () {
    final buckets = buildAdherenceBuckets(
      <DoseLog>[
        log('a', '1:2024-01-10:08:00', DoseStatus.taken),
        log('b', '1:2026-08-10:08:00', DoseStatus.skipped),
      ],
      AdherencePeriod.all,
      DateTime(2026, 8, 12),
      locale: 'en',
    );

    expect(buckets.map((item) => item.label), <String>['2024', '2025', '2026']);
    expect(buckets.first.taken, 1);
    expect(buckets.last.missed, 1);
  });
}
