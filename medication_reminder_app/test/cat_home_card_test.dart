import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medication_reminder_app/app_localizations.dart';
import 'package:medication_reminder_app/cat.dart';
import 'package:medication_reminder_app/cat_home_card.dart';

void main() {
  testWidgets('happy points are visible only for an adult pet', (tester) async {
    final young = CatProfile(
      name: 'Nova',
      variant: PetVariant.dogGolden,
      adoptedAt: DateTime(2026, 1, 1),
      feedCount: 14,
      happyPoints: 100,
    );

    await tester.pumpWidget(_app(young));
    expect(find.textContaining('happy points'), findsNothing);

    await tester.pumpWidget(_app(young.copyWith(feedCount: 60)));
    await tester.pump();
    expect(find.text('100 happy points'), findsOneWidget);
  });
}

Widget _app(CatProfile profile) => MaterialApp(
  locale: const Locale('en'),
  supportedLocales: const <Locale>[Locale('en'), Locale('nl')],
  localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
    AppLocalizationsDelegate(),
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  home: Scaffold(
    body: CatHomeCard(
      profile: profile,
      activity: CatActivity.normal,
      onTap: _noop,
      onSettings: _noop,
    ),
  ),
);

void _noop() {}
