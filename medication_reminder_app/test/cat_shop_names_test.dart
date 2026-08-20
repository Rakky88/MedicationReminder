import 'package:flutter_test/flutter_test.dart';
import 'package:medication_reminder_app/cat_shop.dart';

void main() {
  test('the hidden set uses its neutral display names', () {
    const expectedEnglishNames = <String, String>{
      'doctor_hat_fezz': 'Fezz',
      'doctor_bow_tie': 'Red bowtie',
      'doctor_outfit': 'Tweed outfit',
      'doctor_tardis_toy': 'Blue box',
    };

    for (final entry in expectedEnglishNames.entries) {
      expect(
        catShopItemById(entry.key)?.localizedName('en'),
        entry.value,
        reason: entry.key,
      );
    }
  });

  test('the hidden set has a deliberate name in every app language', () {
    const languages = <String>{'en', 'nl', 'de', 'fr', 'es'};
    for (final id in <String>{
      'doctor_hat_fezz',
      'doctor_bow_tie',
      'doctor_outfit',
      'doctor_tardis_toy',
    }) {
      final item = catShopItemById(id)!;
      for (final language in languages) {
        expect(
          item.localizedName(language).trim(),
          isNotEmpty,
          reason: '$id/$language',
        );
        expect(
          item.localizedName(language).toLowerCase(),
          isNot(contains('doctor')),
          reason: '$id/$language',
        );
      }
    }
  });
}
