import 'dart:io';

import 'package:medication_reminder_app/cat.dart';
import 'package:medication_reminder_app/cat_shop.dart';
import 'package:medication_reminder_app/pet_costumes.dart';

void main() {
  final expected = <String>{};

  for (final variant in PetVariant.values) {
    for (final stage in CatStage.values) {
      expected.add('assets/cats/${variant.assetPrefix}_${stage.name}.png');
    }
    expected.add(dragonModeFittedAssetPath(variant));
  }

  for (final item in catShopCatalog) {
    if (item.category == CatAccessoryCategory.toy || item.adaptiveOverlay) {
      expected.add(item.assetPath);
      continue;
    }
    for (final variant in PetVariant.values) {
      expected.add(item.fittedAssetPath(variant));
    }
  }

  final actual = Directory('assets/cats')
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.toLowerCase().endsWith('.png'))
      .map((file) => file.path.replaceAll('\\', '/'))
      .toSet();
  final missing = expected.difference(actual).toList()..sort();
  final unused = actual.difference(expected).toList()..sort();

  stdout.writeln('Expected runtime sprites: ${expected.length}');
  stdout.writeln('Present sprites: ${actual.length}');
  stdout.writeln('Missing runtime sprites: ${missing.length}');
  for (final path in missing) {
    stdout.writeln('MISSING $path');
  }
  stdout.writeln('Unused packaged sprites: ${unused.length}');
  for (final path in unused) {
    stdout.writeln('UNUSED $path');
  }

  if (missing.isNotEmpty) exitCode = 1;
  if (unused.isNotEmpty) exitCode = 2;
}
