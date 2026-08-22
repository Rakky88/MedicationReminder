import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medication_reminder_app/about_screen.dart';
import 'package:medication_reminder_app/app_branding.dart';
import 'package:medication_reminder_app/app_localizations.dart';
import 'package:medication_reminder_app/cat.dart';
import 'package:medication_reminder_app/cat_avatar.dart';
import 'package:medication_reminder_app/cat_inventory_screen.dart';
import 'package:medication_reminder_app/cat_repository.dart';
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

  testWidgets('about screen identifies the maker and links to Ko-fi', (
    tester,
  ) async {
    await tester.pumpWidget(localized(const AboutScreen()));

    expect(
      find.byKey(const ValueKey<String>('about-brand-hero')),
      findsOneWidget,
    );
    final logo = tester.widget<Image>(
      find.byKey(const ValueKey<String>('about-brand-logo')),
    );
    expect((logo.image as AssetImage).assetName, appLogoMarkAsset);
    expect(
      find.byKey(const ValueKey<String>('about-brand-title')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('about-version-badge')),
      findsOneWidget,
    );
    expect(find.text('Made by Rick Groot · 2026'), findsOneWidget);
    expect(find.text('Version V0.02.08'), findsOneWidget);
    expect(find.text('Share or update the app'), findsOneWidget);
    expect(find.text('Copy Android download link'), findsOneWidget);
    expect(find.text('Open contact form'), findsNothing);
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
    expect(find.text('Buy me a coffee'), findsOneWidget);
    expect(find.text('Payment via PayPal'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('paypal-payment-logo')),
      findsOneWidget,
    );
    expect(find.text('Open tip form'), findsOneWidget);
    expect(find.text('Support the app'), findsNothing);
  });

  testWidgets('about brand hero stays intact on a compact screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(localized(const AboutScreen()));

    final hero = find.byKey(const ValueKey<String>('about-brand-hero'));
    expect(hero, findsOneWidget);
    expect(tester.getSize(hero).width, lessThanOrEqualTo(280));
    expect(
      find.byKey(const ValueKey<String>('about-brand-logo')),
      findsOneWidget,
    );
    final heroCenter = tester.getCenter(hero).dx;
    for (final key in <String>[
      'about-brand-logo',
      'about-brand-title',
      'about-maker-badge',
      'about-version-badge',
    ]) {
      expect(
        tester.getCenter(find.byKey(ValueKey<String>(key))).dx,
        closeTo(heroCenter, 0.5),
        reason: '$key should be horizontally centered in the brand block',
      );
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('an offline code shows the neutral no-effect response', (
    tester,
  ) async {
    await CatRepository.instance.adopt(
      name: 'Milo',
      variant: PetVariant.catTuxedo,
    );
    await tester.pumpWidget(localized(const AboutScreen()));
    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'ANY-CODE');
    await tester.tap(find.text('Redeem code'));
    await tester.pumpAndSettle();

    expect(find.text('This code has no effect right now.'), findsOneWidget);
    expect(
      find.text('The code could not be checked. Try again later.'),
      findsNothing,
    );
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
    expect(find.textContaining('purr after a recorded dose'), findsNothing);
    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(find.text('Meowing sound'), findsOneWidget);
    expect(find.textContaining('meow in reminders'), findsNothing);
    expect(
      find.text('Keep repeating reminders until I respond'),
      findsOneWidget,
    );
    expect(find.textContaining('After 3 ignored reminders'), findsNothing);
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
    expect(find.text('Dragon mode'), findsOneWidget);
  });

  testWidgets('dragon mode setting is hidden for youngest and adult pets', (
    tester,
  ) async {
    for (final feedCount in <int>[0, 13, 60]) {
      final profile = CatProfile(
        name: 'Nova',
        variant: PetVariant.catOrange,
        adoptedAt: DateTime(2026, 1, 1),
        feedCount: feedCount,
      );
      await tester.pumpWidget(localized(CatScreen(profile: profile)));
      expect(
        find.text('Dragon mode'),
        findsNothing,
        reason: '$feedCount feeds',
      );
    }
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
    expect(find.text('Supporter crown'), findsOneWidget);
    expect(find.text('850 ♥'), findsOneWidget);
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
