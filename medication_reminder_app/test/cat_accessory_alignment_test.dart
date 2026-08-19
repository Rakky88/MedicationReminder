import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medication_reminder_app/cat.dart';
import 'package:medication_reminder_app/cat_shop.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'every fitted hat and pair of glasses follows the pet landmarks',
    () async {
      const eyeLines = <PetVariant, double>{
        PetVariant.catOrange: 140,
        PetVariant.catTuxedo: 140,
        PetVariant.catGray: 140,
        PetVariant.catCalico: 140,
        PetVariant.catBlackBib: 140,
        PetVariant.dogGolden: 88,
        PetVariant.dogBeagle: 98,
        PetVariant.dogBlackLab: 92,
        PetVariant.dogBorderCollie: 108,
        PetVariant.dogDachshund: 96,
        PetVariant.chickenHen: 132,
      };
      const headCenters = <PetVariant, double>{
        PetVariant.catOrange: 248,
        PetVariant.catTuxedo: 249,
        PetVariant.catGray: 247,
        PetVariant.catCalico: 247,
        PetVariant.catBlackBib: 224,
        PetVariant.dogGolden: 257,
        PetVariant.dogBeagle: 260,
        PetVariant.dogBlackLab: 247,
        PetVariant.dogBorderCollie: 253,
        PetVariant.dogDachshund: 235,
        PetVariant.chickenHen: 256,
      };
      final headItems = catShopCatalog.where(
        (item) =>
            !item.adaptiveOverlay &&
            (item.category == CatAccessoryCategory.hat ||
                item.category == CatAccessoryCategory.glasses),
      );

      for (final variant in PetVariant.values) {
        final eyeLine = eyeLines[variant]!;
        for (final item in headItems) {
          final path = item.fittedAssetPath(variant);
          final bounds = await alphaBounds(path);
          expect(bounds.left, greaterThan(0), reason: path);
          expect(bounds.top, greaterThan(0), reason: path);
          expect(bounds.right, lessThan(512), reason: path);
          expect(bounds.bottom, lessThan(512), reason: path);
          expect(
            (bounds.center.dx - headCenters[variant]!).abs(),
            lessThan(item.category == CatAccessoryCategory.glasses ? 15 : 25),
            reason: path,
          );
          expect(
            bounds.width,
            greaterThanOrEqualTo(
              item.category == CatAccessoryCategory.glasses
                  ? 80
                  : item.id == 'doctor_hat_fezz'
                  ? 80
                  : item.id == 'supporter_hat' &&
                        variant == PetVariant.dogDachshund
                  ? 95
                  : (variant == PetVariant.chickenHen ? 95 : 120),
            ),
            reason:
                '$path must span the adult head instead of reading as a '
                'small floating accessory; the low brimless fez and the '
                'narrow dachshund crown use reviewed head-specific minima',
          );
          if (item.category == CatAccessoryCategory.glasses) {
            expect(bounds.top, lessThan(eyeLine), reason: path);
            expect(bounds.bottom, greaterThan(eyeLine), reason: path);
          } else {
            expect(
              bounds.bottom,
              lessThanOrEqualTo(eyeLine + 18),
              reason: path,
            );
          }
        }
      }
    },
  );

  test('classic glasses have no protruding right temple arm', () async {
    const headCenters = <PetVariant, double>{
      PetVariant.catOrange: 248,
      PetVariant.catTuxedo: 249,
      PetVariant.catGray: 247,
      PetVariant.catCalico: 247,
      PetVariant.catBlackBib: 224,
      PetVariant.dogGolden: 257,
      PetVariant.dogBeagle: 260,
      PetVariant.dogBlackLab: 247,
      PetVariant.dogBorderCollie: 253,
      PetVariant.dogDachshund: 235,
      PetVariant.chickenHen: 256,
    };
    final glasses = catShopCatalog.where(
      (item) =>
          item.category == CatAccessoryCategory.glasses && !item.isStreakReward,
    );
    for (final variant in PetVariant.values) {
      for (final item in glasses) {
        final path = item.fittedAssetPath(variant);
        final bounds = await alphaBounds(path);
        expect(
          bounds.right,
          lessThanOrEqualTo(headCenters[variant]! + 84),
          reason: path,
        );
      }
    }
  });

  test('every Doctor bow tie follows the pet neck landmark', () async {
    const neckCenters = <PetVariant, double>{
      PetVariant.catOrange: 245,
      PetVariant.catTuxedo: 246,
      PetVariant.catGray: 245,
      PetVariant.catCalico: 244,
      PetVariant.catBlackBib: 224,
      PetVariant.dogGolden: 257,
      PetVariant.dogBeagle: 260,
      PetVariant.dogBlackLab: 247,
      PetVariant.dogBorderCollie: 253,
      PetVariant.dogDachshund: 235,
      PetVariant.chickenHen: 256,
    };
    for (final variant in PetVariant.values) {
      final item = catShopItemById('doctor_bow_tie')!;
      final path = item.fittedAssetPath(variant);
      final bounds = await alphaBounds(path);
      expect(bounds.left, greaterThan(0), reason: path);
      expect(bounds.right, lessThan(512), reason: path);
      expect(bounds.top, inInclusiveRange(135, 225), reason: path);
      expect(bounds.bottom, inInclusiveRange(180, 255), reason: path);
      expect(
        (bounds.center.dx - neckCenters[variant]!).abs(),
        lessThan(2),
        reason: path,
      );
      expect(bounds.width, greaterThanOrEqualTo(65), reason: path);
    }
  });

  test('V12 review corrections retain their approved fit', () async {
    for (final prefix in <String>['cat_gray', 'cat_orange', 'cat_tuxedo']) {
      final glasses = await alphaBounds(
        'assets/cats/fitted_accessories/${prefix}_glasses_round.png',
      );
      expect(glasses.width, greaterThanOrEqualTo(130), reason: prefix);
    }
    final grayGlasses = await alphaBounds(
      'assets/cats/fitted_accessories/cat_gray_glasses_round.png',
    );
    final tuxedoGlasses = await alphaBounds(
      'assets/cats/fitted_accessories/cat_tuxedo_glasses_round.png',
    );
    expect(grayGlasses.center.dx, lessThanOrEqualTo(245));
    expect(tuxedoGlasses.center.dx, lessThanOrEqualTo(248));

    final eggGlasses = await alphaBounds(
      'assets/cats/fitted_accessories/'
      'cat_tuxedo_chicken_glasses_egg.png',
    );
    expect(eggGlasses.width, greaterThanOrEqualTo(110));
    expect(eggGlasses.center.dx, lessThanOrEqualTo(240));

    for (final item in <String>['glasses_star', 'supporter_glasses']) {
      final glasses = await alphaBounds(
        'assets/cats/fitted_accessories/dog_beagle_$item.png',
      );
      expect(glasses.center.dx, greaterThanOrEqualTo(261), reason: item);
    }

    for (final item in <String>['hat_crown', 'supporter_hat']) {
      final crown = await alphaBounds(
        'assets/cats/fitted_accessories/dog_dachshund_$item.png',
      );
      expect(crown.width, greaterThanOrEqualTo(140), reason: item);
    }

    final beagleCrown = await alphaBounds(
      'assets/cats/fitted_accessories/dog_beagle_supporter_hat.png',
    );
    expect(beagleCrown.bottom, lessThanOrEqualTo(82));

    final chickenLaurel = await alphaBounds(
      'assets/cats/fitted_accessories/'
      'chicken_hen_streak_250_hat_laurel.png',
    );
    expect(chickenLaurel.bottom, greaterThanOrEqualTo(108));
  });

  test('every tailored outfit is a complete fitted adult pet sprite', () async {
    final items = catShopCatalog.where(
      (item) =>
          item.category == CatAccessoryCategory.outfit && !item.adaptiveOverlay,
    );
    for (final item in items) {
      for (final variant in PetVariant.values) {
        final path = item.fittedAssetPath(variant);
        final bounds = await alphaBounds(path);
        expect(bounds.left, greaterThan(0), reason: path);
        expect(bounds.right, lessThan(512), reason: path);
        expect(bounds.bottom, inInclusiveRange(482, 485), reason: path);
        expect(bounds.height, greaterThan(400), reason: path);
      }
    }
  });

  test('every Dragon mode sprite is a complete fitted young pet', () async {
    for (final variant in PetVariant.values) {
      final path =
          'assets/cats/fitted/${variant.assetPrefix}_dragon_mode_young.png';
      final bounds = await alphaBounds(path);
      expect(bounds.left, greaterThan(0), reason: path);
      expect(bounds.right, lessThan(512), reason: path);
      expect(bounds.bottom, inInclusiveRange(482, 485), reason: path);
      expect(bounds.height, greaterThan(395), reason: path);
    }
  });

  test(
    'every pet and both younger stages share the centre and ground line',
    () async {
      for (final variant in PetVariant.values) {
        for (final stage in CatStage.values) {
          final path = 'assets/cats/${variant.assetPrefix}_${stage.name}.png';
          final bounds = await alphaBounds(path);
          expect(
            (bounds.center.dx - 256).abs(),
            lessThanOrEqualTo(1.5),
            reason: path,
          );
          expect(bounds.bottom, inInclusiveRange(482, 485), reason: path);
        }
      }
    },
  );

  test('all three chicken silhouettes are complete and centered', () async {
    const minimumWidths = <CatStage, double>{
      CatStage.kitten: 250,
      CatStage.young: 280,
      CatStage.adult: 295,
    };
    for (final entry in minimumWidths.entries) {
      final path = 'assets/cats/chicken_hen_${entry.key.name}.png';
      final bounds = await alphaBounds(path);
      expect(bounds.width, greaterThanOrEqualTo(entry.value), reason: path);
      expect(
        (bounds.center.dx - 256).abs(),
        lessThanOrEqualTo(1),
        reason: path,
      );
    }
  });
}

Future<ui.Rect> alphaBounds(String assetPath) async {
  final bytes = await rootBundle.load(assetPath);
  final codec = await ui.instantiateImageCodec(bytes.buffer.asUint8List());
  final frame = await codec.getNextFrame();
  final image = frame.image;
  expect(image.width, 512, reason: assetPath);
  expect(image.height, 512, reason: assetPath);
  final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  expect(data, isNotNull, reason: assetPath);
  var left = image.width;
  var top = image.height;
  var right = 0;
  var bottom = 0;
  final pixels = data!.buffer.asUint8List();
  for (var y = 0; y < image.height; y++) {
    for (var x = 0; x < image.width; x++) {
      final alpha = pixels[(y * image.width + x) * 4 + 3];
      if (alpha <= 8) continue;
      if (x < left) left = x;
      if (x + 1 > right) right = x + 1;
      if (y < top) top = y;
      if (y + 1 > bottom) bottom = y + 1;
    }
  }
  image.dispose();
  codec.dispose();
  expect(right, greaterThan(left), reason: assetPath);
  expect(bottom, greaterThan(top), reason: assetPath);
  return ui.Rect.fromLTRB(
    left.toDouble(),
    top.toDouble(),
    right.toDouble(),
    bottom.toDouble(),
  );
}
