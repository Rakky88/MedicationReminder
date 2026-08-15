import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medication_reminder_app/cat.dart';
import 'package:medication_reminder_app/cat_avatar.dart';
import 'package:medication_reminder_app/cat_shop.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final streakItems = catShopCatalog
      .where((item) => item.isStreakReward)
      .toList(growable: false);

  test('catalog contains every requested streak milestone', () {
    expect(
      streakItems.map((item) => item.requiredMedicationStreak).toList(),
      <int?>[40, 100, 150, 200, 250, 300, 365, 365, 365, 365, 500, 750, 1000],
    );
    expect(streakItems, hasLength(13));
    expect(streakItems.every((item) => item.price == 0), isTrue);
    expect(streakItems.every((item) => item.adaptiveOverlay), isTrue);
    expect(
      streakItems
          .where((item) => item.requiredMedicationStreak == 365)
          .map((item) => item.category)
          .toSet(),
      <CatAccessoryCategory>{
        CatAccessoryCategory.hat,
        CatAccessoryCategory.glasses,
        CatAccessoryCategory.outfit,
        CatAccessoryCategory.toy,
      },
    );
  });

  test('every streak asset remains inside every adult pet canvas', () async {
    for (final item in streakItems) {
      final source = await _alphaBounds(item.assetPath);
      for (final variant in PetVariant.values) {
        final transform = item.adaptiveTransform(variant);
        final bounds = _transformedBounds(source, transform);
        expect(
          bounds.left,
          greaterThanOrEqualTo(-1),
          reason: '${item.id} ${variant.name}',
        );
        expect(
          bounds.top,
          greaterThanOrEqualTo(-1),
          reason: '${item.id} ${variant.name}',
        );
        expect(
          bounds.right,
          lessThanOrEqualTo(513),
          reason: '${item.id} ${variant.name}',
        );
        expect(
          bounds.bottom,
          lessThanOrEqualTo(513),
          reason: '${item.id} ${variant.name}',
        );
        expect(
          bounds.width,
          greaterThan(70),
          reason: '${item.id} ${variant.name}',
        );
        expect(
          bounds.height,
          greaterThan(45),
          reason: '${item.id} ${variant.name}',
        );
      }
    }
  });

  testWidgets('all 143 streak item and adult pet combinations render', (
    tester,
  ) async {
    for (final variant in PetVariant.values) {
      for (final item in streakItems) {
        final profile = CatProfile(
          name: 'Streak test',
          variant: variant,
          adoptedAt: DateTime(2026, 1, 1),
          feedCount: 60,
          ownedAccessoryIds: <String>{item.id},
          equippedAccessories: <String, String>{item.category.name: item.id},
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
        await tester.pump();
        expect(
          find.byKey(ValueKey<String>('adaptive-${variant.name}-${item.id}')),
          findsOneWidget,
          reason: '${item.id} on ${variant.name}',
        );
        expect(
          tester.takeException(),
          isNull,
          reason: '${item.id} on ${variant.name}',
        );
      }
    }
  });
}

ui.Rect _transformedBounds(
  ({ui.Rect bounds, int width, int height}) source,
  CatAccessoryTransform transform,
) {
  final normalized = ui.Rect.fromLTRB(
    source.bounds.left / source.width * 512,
    source.bounds.top / source.height * 512,
    source.bounds.right / source.width * 512,
    source.bounds.bottom / source.height * 512,
  );
  double x(double value) =>
      256 + (value - 256) * transform.scale + transform.dx * 512;
  double y(double value) =>
      256 + (value - 256) * transform.scale + transform.dy * 512;
  return ui.Rect.fromLTRB(
    x(normalized.left),
    y(normalized.top),
    x(normalized.right),
    y(normalized.bottom),
  );
}

Future<({ui.Rect bounds, int width, int height})> _alphaBounds(
  String assetPath,
) async {
  final bytes = await rootBundle.load(assetPath);
  final codec = await ui.instantiateImageCodec(bytes.buffer.asUint8List());
  final frame = await codec.getNextFrame();
  final image = frame.image;
  final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  var left = image.width;
  var top = image.height;
  var right = 0;
  var bottom = 0;
  final pixels = data!.buffer.asUint8List();
  for (var y = 0; y < image.height; y++) {
    for (var x = 0; x < image.width; x++) {
      if (pixels[(y * image.width + x) * 4 + 3] <= 8) continue;
      if (x < left) left = x;
      if (x + 1 > right) right = x + 1;
      if (y < top) top = y;
      if (y + 1 > bottom) bottom = y + 1;
    }
  }
  final result = (
    bounds: ui.Rect.fromLTRB(
      left.toDouble(),
      top.toDouble(),
      right.toDouble(),
      bottom.toDouble(),
    ),
    width: image.width,
    height: image.height,
  );
  image.dispose();
  codec.dispose();
  return result;
}
