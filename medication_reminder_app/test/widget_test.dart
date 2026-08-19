import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medication_reminder_app/cat.dart';
import 'package:medication_reminder_app/cat_repository.dart';
import 'package:medication_reminder_app/main.dart';
import 'package:medication_reminder_app/medication.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('shows onboarding when there are no medications', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MedicationReminderApp(initialLocale: Locale('en')),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('home-brand-logo')), findsOneWidget);
    expect(find.text('Medication Reminder'), findsOneWidget);
    expect(find.text('No medication scheduled'), findsOneWidget);
    expect(find.text('Add my first medication'), findsOneWidget);
  });

  testWidgets('compact app bar keeps the complete brand visible', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MedicationReminderApp(initialLocale: Locale('en')),
    );
    await tester.pumpAndSettle();

    final appBarRect = tester.getRect(find.byType(AppBar));
    final titleRect = tester.getRect(find.byKey(const Key('home-brand-title')));
    expect(find.byKey(const Key('home-brand-logo')), findsOneWidget);
    expect(titleRect.left, greaterThanOrEqualTo(appBarRect.left));
    expect(titleRect.right, lessThanOrEqualTo(appBarRect.right));
    expect(tester.takeException(), isNull);
  });

  testWidgets('adds and displays a medication', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MedicationReminderApp(initialLocale: Locale('en')),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add my first medication'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Medication name'),
      'Vitamin D',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Dosage or instructions (optional)'),
      '1 tablet',
    );
    expect(find.textContaining('Off by default for every alarm'), findsNothing);
    expect(
      find.textContaining('Off keeps this medication private'),
      findsNothing,
    );
    await tester.tap(find.text('Save').last);
    await tester.pumpAndSettle();

    expect(find.text('Vitamin D'), findsOneWidget);
    expect(find.text('1 tablet'), findsOneWidget);
    expect(find.textContaining('Medication names stay hidden'), findsNothing);
  });

  testWidgets('hides all dose actions after the current alarm was taken', (
    WidgetTester tester,
  ) async {
    final scheduled = DateTime.now().subtract(const Duration(minutes: 1));
    final time =
        '${scheduled.hour.toString().padLeft(2, '0')}:'
        '${scheduled.minute.toString().padLeft(2, '0')}';
    final date =
        '${scheduled.year}-'
        '${scheduled.month.toString().padLeft(2, '0')}-'
        '${scheduled.day.toString().padLeft(2, '0')}';
    final medication = Medication(
      id: 1,
      name: 'Completed medicine',
      dosage: '',
      times: <String>[time],
      weekdays: <int>[scheduled.weekday],
      createdAt: scheduled.subtract(const Duration(days: 1)),
      scheduleStartedAt: <String, DateTime>{
        Medication.scheduleKey(scheduled.weekday, time): scheduled.subtract(
          const Duration(days: 1),
        ),
      },
    );
    final log = DoseLog(
      id: 'taken-now',
      medicationId: 1,
      medicationName: medication.name,
      dosage: '',
      recordedAt: DateTime.now(),
      status: DoseStatus.taken,
      doseKey: '1:$date:$time',
    );
    SharedPreferences.setMockInitialValues(<String, Object>{
      'medications_v1': jsonEncode(<Object?>[medication.toJson()]),
      'dose_logs_v1': jsonEncode(<Object?>[log.toJson()]),
    });

    await tester.pumpWidget(
      const MedicationReminderApp(initialLocale: Locale('en')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Completed medicine'), findsWidgets);
    expect(find.text('Taken'), findsNothing);
    expect(find.text('Dose missed'), findsNothing);
    expect(find.byIcon(Icons.snooze), findsNothing);
  });

  testWidgets('shows exactly one action block for one alarm that has fired', (
    WidgetTester tester,
  ) async {
    final scheduled = DateTime.now().subtract(const Duration(minutes: 1));
    final time =
        '${scheduled.hour.toString().padLeft(2, '0')}:'
        '${scheduled.minute.toString().padLeft(2, '0')}';
    final medication = Medication(
      id: 21,
      name: 'One due alarm',
      dosage: '',
      times: <String>[time],
      weekdays: <int>[scheduled.weekday],
      createdAt: scheduled.subtract(const Duration(minutes: 2)),
      scheduleStartedAt: <String, DateTime>{
        Medication.scheduleKey(scheduled.weekday, time): scheduled.subtract(
          const Duration(minutes: 2),
        ),
      },
    );
    SharedPreferences.setMockInitialValues(<String, Object>{
      'medications_v1': jsonEncode(<Object?>[medication.toJson()]),
    });

    await tester.pumpWidget(
      const MedicationReminderApp(initialLocale: Locale('en')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Taken'), findsOneWidget);
    expect(find.text('Dose missed'), findsOneWidget);
    expect(find.byIcon(Icons.snooze), findsOneWidget);
  });

  testWidgets('an early-enabled alarm shows only its Taken action', (
    WidgetTester tester,
  ) async {
    final now = DateTime.now();
    final scheduled = now.add(const Duration(minutes: 2));
    if (scheduled.day != now.day) return;
    final time =
        '${scheduled.hour.toString().padLeft(2, '0')}:'
        '${scheduled.minute.toString().padLeft(2, '0')}';
    final medication = Medication(
      id: 22,
      name: 'Early alarm',
      dosage: '',
      times: <String>[time],
      weekdays: <int>[now.weekday],
      allowBeforeDueTimes: <String>{time},
      createdAt: now.subtract(const Duration(minutes: 1)),
      scheduleStartedAt: <String, DateTime>{
        Medication.scheduleKey(now.weekday, time): now.subtract(
          const Duration(minutes: 1),
        ),
      },
    );
    SharedPreferences.setMockInitialValues(<String, Object>{
      'medications_v1': jsonEncode(<Object?>[medication.toJson()]),
    });

    await tester.pumpWidget(
      const MedicationReminderApp(initialLocale: Locale('en')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Taken'), findsOneWidget);
    expect(find.text('Dose missed'), findsNothing);
    expect(find.byIcon(Icons.snooze), findsNothing);
    await tester.tap(find.text('Taken'));
    await tester.pumpAndSettle();
    expect(find.text('Taken'), findsNothing);
  });

  testWidgets('hides all dose actions after the current alarm was missed', (
    WidgetTester tester,
  ) async {
    final scheduled = DateTime.now().subtract(const Duration(minutes: 1));
    final time =
        '${scheduled.hour.toString().padLeft(2, '0')}:'
        '${scheduled.minute.toString().padLeft(2, '0')}';
    final medication = Medication(
      id: 2,
      name: 'Missed medicine',
      dosage: '',
      times: <String>[time],
      weekdays: <int>[scheduled.weekday],
      createdAt: scheduled.subtract(const Duration(minutes: 2)),
      scheduleStartedAt: <String, DateTime>{
        Medication.scheduleKey(scheduled.weekday, time): scheduled.subtract(
          const Duration(minutes: 2),
        ),
      },
    );
    SharedPreferences.setMockInitialValues(<String, Object>{
      'medications_v1': jsonEncode(<Object?>[medication.toJson()]),
    });

    await tester.pumpWidget(
      const MedicationReminderApp(initialLocale: Locale('en')),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Dose missed').first);
    await tester.pumpAndSettle();
    expect(find.text('Mark this dose as missed?'), findsOneWidget);
    await tester.tap(find.text('Yes, dose missed'));
    await tester.pumpAndSettle();

    expect(find.text('Taken'), findsNothing);
    expect(find.text('Dose missed'), findsNothing);
    expect(find.byIcon(Icons.snooze), findsNothing);
  });

  testWidgets('adult play moment is clear and awards ten points once', (
    WidgetTester tester,
  ) async {
    final now = DateTime.now();
    final day =
        '${now.year}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
    final minute = now.hour * 60 + now.minute;
    final secondMoment = minute < 24 * 60 - 60 ? minute + 60 : minute - 60;
    final adult = CatProfile(
      name: 'Milo',
      variant: PetVariant.catTuxedo,
      adoptedAt: now.subtract(const Duration(days: 100)),
      feedCount: 60,
      purrEnabled: false,
      playScheduleDay: day,
      playMomentMinutes: <int>[minute, secondMoment],
    );
    SharedPreferences.setMockInitialValues(<String, Object>{
      'adopted_cat_v1': jsonEncode(adult.toJson()),
    });

    await tester.pumpWidget(
      const MedicationReminderApp(initialLocale: Locale('en')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Your pet wants to play!'), findsOneWidget);
    expect(find.byIcon(Icons.sports_esports), findsOneWidget);
    await tester.tap(find.byIcon(Icons.sports_esports));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Playtime!'), findsOneWidget);
    expect(
      find.text(
        'You played with Milo. Your pet loved it, and you earned 10 happy points!',
      ),
      findsOneWidget,
    );
    expect((await CatRepository.instance.getProfile())?.happyPoints, 10);
  });
}
