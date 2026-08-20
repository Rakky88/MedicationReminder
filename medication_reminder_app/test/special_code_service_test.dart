import 'package:flutter_test/flutter_test.dart';
import 'package:medication_reminder_app/special_code_service.dart';

void main() {
  test('the built-in code unlocks the complete wardrobe set', () async {
    final result = await SpecialCodeService.redeem(
      code: '  bowtiesarefly  ',
      languageCode: 'nl',
    );

    expect(result.status, SpecialCodeStatus.redeemed);
    expect(result.redemptionId, 'built-in:doctor-who:v1');
    expect(result.itemIds, <String>{
      'doctor_hat_fezz',
      'doctor_bow_tie',
      'doctor_outfit',
      'doctor_tardis_toy',
    });
  });

  test('the retired built-in code no longer has an effect', () async {
    final result = await SpecialCodeService.redeem(
      code: 'DOCTORWHO',
      languageCode: 'en',
    );

    expect(result.status, SpecialCodeStatus.noEffect);
    expect(result.itemIds, isEmpty);
  });

  test('an unknown offline code reports that it has no effect', () async {
    final result = await SpecialCodeService.redeem(
      code: 'NOT-A-CODE',
      languageCode: 'en',
    );

    expect(result.status, SpecialCodeStatus.noEffect);
    expect(result.itemIds, isEmpty);
  });
}
