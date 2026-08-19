import 'package:flutter_test/flutter_test.dart';
import 'package:medication_reminder_app/special_code_service.dart';

void main() {
  test('DOCTORWHO unlocks the complete built-in wardrobe set', () async {
    final result = await SpecialCodeService.redeem(
      code: '  doctorwho  ',
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

  test('an unknown offline code reports that it has no effect', () async {
    final result = await SpecialCodeService.redeem(
      code: 'NOT-A-CODE',
      languageCode: 'en',
    );

    expect(result.status, SpecialCodeStatus.noEffect);
    expect(result.itemIds, isEmpty);
  });
}
