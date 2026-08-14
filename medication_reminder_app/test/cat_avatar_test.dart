import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medication_reminder_app/cat.dart';
import 'package:medication_reminder_app/cat_avatar.dart';
import 'package:medication_reminder_app/cat_shop.dart';

void main() {
  test('every pet stage, chicken item, and logo asset is bundled', () async {
    for (final variant in PetVariant.values) {
      for (final feedCount in <int>[0, 14, 60]) {
        final profile = CatProfile(
          name: 'Asset test',
          variant: variant,
          adoptedAt: DateTime(2026, 1, 1),
          feedCount: feedCount,
        );
        expect(
          (await rootBundle.load(profile.assetPath)).lengthInBytes,
          greaterThan(0),
        );
      }
      for (final fittedItem in catShopCatalog.where(
        (item) => item.category != CatAccessoryCategory.toy,
      )) {
        expect(
          (await rootBundle.load(
            fittedItem.fittedAssetPath(variant),
          )).lengthInBytes,
          greaterThan(0),
          reason: '${variant.name} ${fittedItem.id}',
        );
      }
    }
    for (final path in <String>[
      'assets/branding/app_logo.png',
      'assets/cats/chicken_hat_straw.png',
      'assets/cats/chicken_glasses_egg.png',
      'assets/cats/chicken_outfit_overalls.png',
      'assets/cats/chicken_toy_corn.png',
    ]) {
      expect((await rootBundle.load(path)).lengthInBytes, greaterThan(0));
    }
  });

  testWidgets('equipped adult accessories are layered over the cat', (
    tester,
  ) async {
    final profile = CatProfile(
      name: 'Milo',
      variant: PetVariant.catTuxedo,
      adoptedAt: DateTime(2026, 1, 1),
      feedCount: 60,
      equippedAccessories: const <String, String>{
        'hat': 'hat_crown',
        'glasses': 'glasses_round',
        'outfit': 'outfit_hoodie',
        'toy': 'toy_yarn',
      },
    );

    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 512,
          height: 512,
          child: CatAvatar(profile: profile),
        ),
      ),
    );

    final assetNames = tester
        .widgetList<Image>(find.byType(Image))
        .map((image) => (image.image as AssetImage).assetName)
        .toList();
    expect(
      assetNames,
      containsAll(<String>[
        'assets/cats/fitted/cat_tuxedo_outfit_hoodie.png',
        'assets/cats/fitted_accessories/cat_tuxedo_hat_crown.png',
        'assets/cats/fitted_accessories/cat_tuxedo_glasses_round.png',
        'assets/cats/shop_toy_yarn.png',
      ]),
    );
    expect(assetNames, isNot(contains(profile.assetPath)));
    expect(assetNames, isNot(contains('assets/cats/shop_outfit_hoodie.png')));
    expect(
      equippedCatShopItems(profile).map((item) => item.category),
      <CatAccessoryCategory>[
        CatAccessoryCategory.outfit,
        CatAccessoryCategory.hat,
        CatAccessoryCategory.glasses,
        CatAccessoryCategory.toy,
      ],
    );
  });

  testWidgets('all supporter reward overlays are layered over an adult cat', (
    tester,
  ) async {
    final profile = CatProfile(
      name: 'Milo',
      variant: PetVariant.catTuxedo,
      adoptedAt: DateTime(2026, 1, 1),
      feedCount: 60,
      ownedAccessoryIds: supporterAccessoryIds,
      equippedAccessories: const <String, String>{
        'hat': 'supporter_hat',
        'glasses': 'supporter_glasses',
        'outfit': 'supporter_outfit',
        'toy': 'supporter_toy',
      },
    );

    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 512,
          height: 512,
          child: CatAvatar(profile: profile),
        ),
      ),
    );

    final assetNames = tester
        .widgetList<Image>(find.byType(Image))
        .map((image) => (image.image as AssetImage).assetName)
        .toList();
    expect(
      assetNames,
      containsAll(<String>[
        'assets/cats/fitted/cat_tuxedo_supporter_outfit.png',
        'assets/cats/fitted_accessories/cat_tuxedo_supporter_hat.png',
        'assets/cats/fitted_accessories/cat_tuxedo_supporter_glasses.png',
        'assets/cats/supporter_toy.png',
      ]),
    );
  });
}
