import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medication_reminder_app/cat.dart';
import 'package:medication_reminder_app/cat_shop.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'all wearable overlays are centered and remain inside the canvas',
    () async {
      const zones = <String, (int, int)>{
        'shop_hat_cap.png': (0, 140),
        'shop_hat_wizard.png': (0, 140),
        'shop_hat_crown.png': (0, 140),
        'shop_glasses_round.png': (110, 215),
        'shop_glasses_sun.png': (110, 215),
        'shop_glasses_star.png': (110, 215),
        'shop_outfit_hoodie.png': (230, 500),
        'shop_outfit_cape.png': (230, 500),
        'shop_outfit_sweater.png': (230, 500),
        'supporter_hat.png': (0, 140),
        'supporter_glasses.png': (110, 215),
        'supporter_outfit.png': (230, 500),
        'doctor_hat_fezz.png': (0, 140),
        'doctor_bow_tie.png': (140, 250),
      };

      for (final entry in zones.entries) {
        final bounds = await alphaBounds('assets/cats/${entry.key}');
        expect(bounds.left, greaterThan(0), reason: entry.key);
        expect(bounds.top, greaterThan(0), reason: entry.key);
        expect(bounds.right, lessThan(512), reason: entry.key);
        expect(bounds.bottom, lessThan(512), reason: entry.key);
        expect(
          bounds.top,
          greaterThanOrEqualTo(entry.value.$1),
          reason: entry.key,
        );
        expect(
          bounds.bottom,
          lessThanOrEqualTo(entry.value.$2),
          reason: entry.key,
        );
        expect((bounds.center.dx - 256).abs(), lessThan(4), reason: entry.key);
      }
    },
  );

  test('outfits are large enough to cover an adult cat torso', () async {
    for (final name in <String>[
      'shop_outfit_hoodie.png',
      'shop_outfit_cape.png',
      'shop_outfit_sweater.png',
      'supporter_outfit.png',
    ]) {
      final bounds = await alphaBounds('assets/cats/$name');
      expect(bounds.width, greaterThanOrEqualTo(250), reason: name);
      expect(bounds.height, greaterThanOrEqualTo(230), reason: name);
    }
  });

  test('wizard hat material is opaque instead of see-through', () async {
    final bytes = await rootBundle.load('assets/cats/shop_hat_wizard.png');
    final codec = await ui.instantiateImageCodec(bytes.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    final image = frame.image;
    final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    final pixels = data!.buffer.asUint8List();
    var visible = 0;
    var translucent = 0;
    for (var offset = 3; offset < pixels.length; offset += 4) {
      final alpha = pixels[offset];
      if (alpha <= 8) continue;
      visible++;
      if (alpha < 245) translucent++;
    }
    image.dispose();
    codec.dispose();

    expect(visible, greaterThan(10000));
    expect(translucent / visible, lessThan(.03));
  });

  test(
    'every fitted hat and pair of glasses follows the pet landmarks',
    () async {
      const eyeLines = <PetVariant, double>{
        PetVariant.catOrange: 130,
        PetVariant.catTuxedo: 130,
        PetVariant.catGray: 128,
        PetVariant.catCalico: 130,
        PetVariant.catBlackBib: 130,
        PetVariant.dogGolden: 88,
        PetVariant.dogBeagle: 94,
        PetVariant.dogBlackLab: 84,
        PetVariant.dogBorderCollie: 108,
        PetVariant.dogDachshund: 92,
        PetVariant.chickenHen: 132,
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
          expect((bounds.center.dx - 256).abs(), lessThan(30), reason: path);
          expect(
            bounds.width,
            greaterThanOrEqualTo(130),
            reason:
                '$path must span the adult head instead of reading as a '
                'small floating accessory',
          );
          if (item.category == CatAccessoryCategory.glasses) {
            expect(bounds.top, lessThan(eyeLine), reason: path);
            expect(bounds.bottom, greaterThan(eyeLine), reason: path);
          } else {
            expect(bounds.bottom, lessThanOrEqualTo(eyeLine + 5), reason: path);
          }
        }
      }
    },
  );

  test('every Doctor bow tie follows the pet neck landmark', () async {
    for (final variant in PetVariant.values) {
      final item = catShopItemById('doctor_bow_tie')!;
      final path = item.fittedAssetPath(variant);
      final bounds = await alphaBounds(path);
      expect(bounds.left, greaterThan(0), reason: path);
      expect(bounds.right, lessThan(512), reason: path);
      expect(bounds.top, inInclusiveRange(135, 225), reason: path);
      expect(bounds.bottom, inInclusiveRange(180, 255), reason: path);
      expect((bounds.center.dx - 256).abs(), lessThan(5), reason: path);
      expect(bounds.width, greaterThanOrEqualTo(80), reason: path);
    }
  });

  test('every Doctor outfit is a complete fitted adult pet sprite', () async {
    final item = catShopItemById('doctor_outfit')!;
    for (final variant in PetVariant.values) {
      final path = item.fittedAssetPath(variant);
      final bounds = await alphaBounds(path);
      expect(bounds.left, greaterThan(0), reason: path);
      expect(bounds.right, lessThan(512), reason: path);
      expect(bounds.bottom, inInclusiveRange(482, 485), reason: path);
      expect(bounds.height, greaterThan(400), reason: path);
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
