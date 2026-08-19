import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medication_reminder_app/app_localizations.dart';
import 'package:medication_reminder_app/log_screen.dart';
import 'package:medication_reminder_app/medication.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    final logs = <DoseLog>[
      DoseLog(
        id: 'taken',
        medicationId: 1,
        medicationName: 'Vitamin D',
        dosage: '1 tablet',
        recordedAt: DateTime(2026, 8, 10, 8, 2),
        status: DoseStatus.taken,
        doseKey: '1:2026-08-10:08:00',
      ),
      DoseLog(
        id: 'missed',
        medicationId: 2,
        medicationName: 'Medicine B',
        dosage: '',
        recordedAt: DateTime(2026, 8, 10, 20),
        status: DoseStatus.skipped,
        doseKey: '2:2026-08-10:20:00',
      ),
    ];
    SharedPreferences.setMockInitialValues(<String, Object>{
      'dose_logs_v1': jsonEncode(logs.map((log) => log.toJson()).toList()),
    });
  });

  testWidgets('history groups a day and opens its adherence graph', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('en'),
        supportedLocales: <Locale>[Locale('en'), Locale('nl')],
        localizationsDelegates: <LocalizationsDelegate<dynamic>>[
          AppLocalizationsDelegate(),
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: LogScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('1 taken'), findsOneWidget);
    expect(find.text('1 missed'), findsOneWidget);
    expect(find.text('Vitamin D'), findsOneWidget);
    expect(find.text('Medicine B'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.bar_chart_outlined));
    await tester.pumpAndSettle();

    expect(find.text('View adherence graph'), findsOneWidget);
    expect(find.text('Week'), findsOneWidget);
    expect(find.text('All'), findsOneWidget);

    await tester.tap(find.text('All'));
    await tester.pumpAndSettle();

    final takenSegment = find.byWidgetPredicate(
      (widget) => widget is ColoredBox && widget.color == Colors.green.shade700,
    );
    final missedSegment = find.byWidgetPredicate(
      (widget) => widget is ColoredBox && widget.color == Colors.red.shade700,
    );
    expect(takenSegment, findsOneWidget);
    expect(missedSegment, findsOneWidget);
    expect(tester.getSize(takenSegment).width, greaterThan(0));
    expect(tester.getSize(missedSegment).width, greaterThan(0));
  });
}
