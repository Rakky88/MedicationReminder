import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medication_reminder_app/about_screen.dart';
import 'package:medication_reminder_app/app_localizations.dart';
import 'package:medication_reminder_app/cat.dart';
import 'package:medication_reminder_app/cat_avatar.dart';
import 'package:medication_reminder_app/cat_inventory_screen.dart';
import 'package:medication_reminder_app/cat_screen.dart';
import 'package:medication_reminder_app/cat_shop_screen.dart';
import 'package:medication_reminder_app/medication_streak.dart';
import 'package:medication_reminder_app/medication_streak_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget localized(Widget home) => MaterialApp(
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
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('about screen identifies the maker and safe store status', (
    tester,
  ) async {
    await tester.pumpWidget(localized(const AboutScreen()));

    expect(find.text('Made by Rick Groot · 2026'), findsOneWidget);
    expect(find.text('Version V0.00.04'), findsOneWidget);
    expect(find.text('Share or update the app'), findsOneWidget);
    expect(find.text('Copy Android download link'), findsOneWidget);
    expect(find.text('Open contact form'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -450));
    await tester.pumpAndSettle();
    expect(find.text('Special item codes'), findsOneWidget);
    expect(
      find.textContaining('appear directly in your wardrobe'),
      findsOneWidget,
    );
    expect(
      find.text('There are currently no active special codes.'),
      findsNothing,
    );
    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(find.textContaining('official store billing'), findsOneWidget);

    await tester.drag(find.byType(ListView), const Offset(0, 500));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open contact form'));
    await tester.pumpAndSettle();
    expect(find.text('Your email address'), findsOneWidget);
    expect(find.text('Message'), findsOneWidget);
    expect(find.text('Send securely'), findsOneWidget);
  });

  testWidgets('cat settings separate purring and meowing controls', (
    tester,
  ) async {
    final adult = CatProfile(
      name: 'Milo',
      variant: PetVariant.catTuxedo,
      adoptedAt: DateTime(2026, 1, 1),
      feedCount: 60,
    );
    await tester.pumpWidget(localized(CatScreen(profile: adult)));

    expect(find.text('Shop'), findsOneWidget);
    expect(find.text('Wardrobe'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -450));
    await tester.pumpAndSettle();
    expect(find.text('Purring sound'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(find.text('Meowing sound'), findsOneWidget);
    expect(
      find.text('Keep repeating reminders until I respond'),
      findsOneWidget,
    );
    expect(find.text('Temporary sound test'), findsNothing);
  });

  testWidgets('dog settings expose separate panting and barking controls', (
    tester,
  ) async {
    final adult = CatProfile(
      name: 'Dimi',
      variant: PetVariant.dogGolden,
      adoptedAt: DateTime(2026, 1, 1),
      feedCount: 60,
    );
    await tester.pumpWidget(localized(CatScreen(profile: adult)));

    await tester.drag(find.byType(ListView), const Offset(0, -450));
    await tester.pumpAndSettle();
    expect(find.text('Panting sound'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(find.text('Barking sound'), findsOneWidget);
  });

  testWidgets(
    'chicken settings expose separate clucking and crowing controls',
    (tester) async {
      final adult = CatProfile(
        name: 'Donna',
        variant: PetVariant.chickenHen,
        adoptedAt: DateTime(2026, 1, 1),
        feedCount: 60,
      );
      await tester.pumpWidget(localized(CatScreen(profile: adult)));

      await tester.drag(find.byType(ListView), const Offset(0, -450));
      await tester.pumpAndSettle();
      expect(find.text('Clucking sound'), findsOneWidget);
      await tester.drag(find.byType(ListView), const Offset(0, -500));
      await tester.pumpAndSettle();
      expect(find.text('Crowing sound'), findsOneWidget);
    },
  );

  testWidgets('young pets do not show shop or wardrobe', (tester) async {
    final young = CatProfile(
      name: 'Nova',
      variant: PetVariant.dogGolden,
      adoptedAt: DateTime(2026, 1, 1),
      feedCount: 14,
      happyPoints: 100,
    );
    await tester.pumpWidget(localized(CatScreen(profile: young)));

    expect(find.text('Shop'), findsNothing);
    expect(find.text('Wardrobe'), findsNothing);
    expect(find.textContaining('happy points'), findsNothing);
  });

  testWidgets('purchased shop item has a clear owned status', (tester) async {
    final adult = CatProfile(
      name: 'Milo',
      variant: PetVariant.catTuxedo,
      adoptedAt: DateTime(2026, 1, 1),
      feedCount: 60,
      happyPoints: 500,
      ownedAccessoryIds: const <String>{'hat_cap'},
      equippedAccessories: const <String, String>{'hat': 'hat_cap'},
    );
    await tester.pumpWidget(localized(CatShopScreen(profile: adult)));

    expect(find.text('Owned'), findsOneWidget);
    expect(find.text('Remove'), findsNothing);
    expect(find.text('Use'), findsNothing);
    expect(find.text('Supporter crown'), findsNothing);
  });

  testWidgets('shop has a streak tab with visible locked and free rewards', (
    tester,
  ) async {
    final adult = CatProfile(
      name: 'Milo',
      variant: PetVariant.catOrange,
      adoptedAt: DateTime(2026, 1, 1),
      feedCount: 60,
      happyPoints: 10,
    );
    final results = <String, MedicationStreakDayResult>{
      for (var day = 1; day <= 40; day++)
        medicationStreakDayKey(DateTime(2026, 1, day)):
            MedicationStreakDayResult.success,
    };
    SharedPreferences.setMockInitialValues(<String, Object>{
      MedicationStreakRepository.preferencesKey: jsonEncode(
        MedicationStreakState(dayResults: results).toJson(),
      ),
    });

    await tester.pumpWidget(localized(CatShopScreen(profile: adult)));
    await tester.pumpAndSettle();
    expect(find.text('Regular items'), findsOneWidget);
    expect(find.text('Streak items'), findsOneWidget);

    await tester.tap(find.text('Streak items'));
    await tester.pumpAndSettle();

    expect(find.text('Consistency cap'), findsOneWidget);
    expect(find.text('40-day streak'), findsOneWidget);
    expect(find.text('Claim free'), findsOneWidget);
    await tester.drag(find.byType(ListView).first, const Offset(0, -330));
    await tester.pumpAndSettle();
    expect(find.text('Reach 100 days'), findsOneWidget);
  });

  testWidgets('wardrobe equips and removes owned items outside the shop', (
    tester,
  ) async {
    final adult = CatProfile(
      name: 'Milo',
      variant: PetVariant.catTuxedo,
      adoptedAt: DateTime(2026, 1, 1),
      feedCount: 60,
      ownedAccessoryIds: const <String>{'hat_cap'},
    );
    await tester.pumpWidget(localized(CatInventoryScreen(profile: adult)));

    expect(find.text('1 item collected'), findsOneWidget);
    expect(find.text('Red cap'), findsOneWidget);
    expect(find.text('Use'), findsOneWidget);

    await tester.drag(find.byType(ListView).last, const Offset(0, -400));
    await tester.pumpAndSettle();
    expect(find.text('Milo'), findsOneWidget);
  });

  testWidgets('adoption offers five-dog family and keeps chicken locked', (
    tester,
  ) async {
    await tester.pumpWidget(localized(const CatScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Cat'), findsOneWidget);
    expect(find.text('Dog'), findsOneWidget);
    expect(find.text('Chicken'), findsNothing);
    await tester.tap(find.text('Dog'));
    await tester.pump();
    final avatar = tester.widget<CatAvatar>(find.byType(CatAvatar).first);
    expect(avatar.profile.species, PetSpecies.dog);
    expect(petVariantsForSpecies(PetSpecies.dog), hasLength(5));
  });

  testWidgets('chicken adoption appears after raising an adult cat', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'cat_entitlements_v1': jsonEncode(<String, Object>{
        'adultCatEverRaised': true,
      }),
    });
    await tester.pumpWidget(localized(const CatScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Chicken'), findsOneWidget);
    await tester.tap(find.text('Chicken'));
    await tester.pump();
    final avatar = tester.widget<CatAvatar>(find.byType(CatAvatar).first);
    expect(avatar.profile.variant, PetVariant.chickenHen);
    expect(avatar.profile.assetPath, endsWith('chicken_hen_kitten.png'));
  });
}
