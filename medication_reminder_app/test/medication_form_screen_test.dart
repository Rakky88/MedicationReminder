import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medication_reminder_app/app_localizations.dart';
import 'package:medication_reminder_app/medication_form_screen.dart';

Widget _localized(Widget home) => MaterialApp(
  locale: const Locale('en'),
  supportedLocales: const <Locale>[Locale('en'), Locale('nl')],
  localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
    AppLocalizationsDelegate(),
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  home: home,
);

void main() {
  testWidgets('default reminder time can be edited in place', (tester) async {
    await tester.pumpWidget(_localized(const MedicationFormScreen()));

    final editButton = find.byKey(const ValueKey<String>('edit-time-08:00'));
    expect(editButton, findsOneWidget);
    expect(find.byTooltip('Edit'), findsOneWidget);

    final allowEarlySwitch = find.byType(Switch).first;
    await tester.tap(allowEarlySwitch);
    await tester.pump();
    expect(tester.widget<Switch>(allowEarlySwitch).value, isTrue);

    await tester.tap(editButton);
    await tester.pumpAndSettle();

    final dialogFinder = find.byType(TimePickerDialog);
    expect(dialogFinder, findsOneWidget);
    final dialog = tester.widget<TimePickerDialog>(dialogFinder);
    expect(dialog.initialTime, const TimeOfDay(hour: 8, minute: 0));

    Navigator.of(
      tester.element(dialogFinder),
    ).pop(const TimeOfDay(hour: 9, minute: 30));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('edit-time-09:30')),
      findsOneWidget,
    );
    expect(find.text('9:30 AM'), findsOneWidget);
    expect(tester.widget<Switch>(find.byType(Switch).first).value, isTrue);
  });
}
