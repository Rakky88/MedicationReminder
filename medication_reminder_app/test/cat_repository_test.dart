import 'dart:convert';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:medication_reminder_app/cat.dart';
import 'package:medication_reminder_app/cat_repository.dart';
import 'package:medication_reminder_app/cat_shop.dart';
import 'package:medication_reminder_app/medication.dart';
import 'package:medication_reminder_app/medication_streak.dart';
import 'package:medication_reminder_app/medication_streak_repository.dart';
import 'package:medication_reminder_app/special_code_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const medication = Medication(
    id: 3,
    name: 'Test',
    dosage: '',
    times: <String>['08:00'],
    weekdays: <int>[DateTime.monday],
  );

  setUp(() {
    final profile = CatProfile(
      name: 'Milo',
      variant: PetVariant.catCalico,
      adoptedAt: DateTime(2026, 8, 1),
    );
    SharedPreferences.setMockInitialValues(<String, Object>{
      'adopted_cat_v1': jsonEncode(profile.toJson()),
    });
  });

  test('default adoption name has one equal-probability branch per name', () {
    expect(CatRepository.randomDefaultPetName(_FixedBoolRandom(true)), 'Dimi');
    expect(
      CatRepository.randomDefaultPetName(_FixedBoolRandom(false)),
      'Donna',
    );
  });

  test('damaged pet data is reported and cannot be overwritten', () async {
    const damaged = '{not a pet}';
    SharedPreferences.setMockInitialValues(<String, Object>{
      'adopted_cat_v1': damaged,
    });

    await expectLater(
      CatRepository.instance.getProfile(),
      throwsFormatException,
    );
    await expectLater(
      CatRepository.instance.adopt(
        name: 'Replacement',
        variant: PetVariant.catOrange,
      ),
      throwsFormatException,
    );
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getString('adopted_cat_v1'), damaged);
  });

  test('DOCTORWHO grants four hidden items exactly once', () async {
    final redemption = await SpecialCodeService.redeem(
      code: 'DOCTORWHO',
      languageCode: 'en',
    );
    final first = await CatRepository.instance.registerCodeReward(
      redemptionId: redemption.redemptionId!,
      itemIds: redemption.itemIds,
    );
    final second = await CatRepository.instance.registerCodeReward(
      redemptionId: redemption.redemptionId!,
      itemIds: redemption.itemIds,
    );

    expect(first?.grantedItemIds, redemption.itemIds);
    expect(first?.profile.ownedAccessoryIds, containsAll(redemption.itemIds));
    expect(second?.duplicate, isTrue);
    final visibleIds = visibleCatShopCatalog(
      first!.profile,
    ).map((item) => item.id).toSet();
    expect(visibleIds.intersection(redemption.itemIds), isEmpty);
  });

  test('one scheduled slot can feed the cat only once', () async {
    final log = DoseLog(
      id: 'first',
      medicationId: medication.id,
      medicationName: medication.name,
      dosage: '',
      recordedAt: DateTime(2026, 8, 10, 8, 5),
      status: DoseStatus.taken,
      doseKey: '3:2026-08-10:08:00',
    );

    final first = await CatRepository.instance.applyDose(medication, log);
    final second = await CatRepository.instance.applyDose(medication, log);

    expect(first?.fed, isTrue);
    expect(second?.fed, isFalse);
    expect(second?.profile.feedCount, 1);
  });

  test('a valid later dose restores one hunger step', () async {
    final hungry = CatProfile(
      name: 'Milo',
      variant: PetVariant.catGray,
      adoptedAt: DateTime(2026, 8, 1),
      hungerPoints: 3,
    );
    SharedPreferences.setMockInitialValues(<String, Object>{
      'adopted_cat_v1': jsonEncode(hungry.toJson()),
    });
    final log = DoseLog(
      id: 'recovery',
      medicationId: medication.id,
      medicationName: medication.name,
      dosage: '',
      recordedAt: DateTime(2026, 8, 10, 8),
      status: DoseStatus.taken,
      doseKey: '3:2026-08-10:08:00',
    );

    final result = await CatRepository.instance.applyDose(medication, log);

    expect(result?.profile.hungerPoints, 2);
    expect(result?.profile.feedCount, 1);
  });

  test('legacy orphan misses are repaired from dose history once', () async {
    final orphanKeys = <String>{
      for (var day = 1; day <= 9; day++)
        '3:2026-08-${day.toString().padLeft(2, '0')}:08:00',
    };
    final legacyJson = CatProfile(
      name: 'Milo',
      variant: PetVariant.catBlackBib,
      adoptedAt: DateTime(2026, 7, 1),
      hungerPoints: 4,
      missedDoseKeys: orphanKeys,
      resolvedMissDoseKeys: const <String>{'old-resolved'},
    ).toJson()..remove('hungerModelVersion');
    SharedPreferences.setMockInitialValues(<String, Object>{
      'adopted_cat_v1': jsonEncode(legacyJson),
    });
    final realMiss = DoseLog(
      id: 'real-miss',
      medicationId: medication.id,
      medicationName: medication.name,
      dosage: '',
      recordedAt: DateTime(2026, 8, 1, 8),
      status: DoseStatus.skipped,
      doseKey: '3:2026-08-01:08:00',
    );

    final repaired = await CatRepository.instance.reconcileDoseLogs(<DoseLog>[
      realMiss,
    ]);
    final repeated = await CatRepository.instance.reconcileDoseLogs(<DoseLog>[
      realMiss,
    ]);

    expect(repaired?.variant, PetVariant.catBlackBib);
    expect(repaired?.hungerModelVersion, 2);
    expect(repaired?.hungerPoints, 0);
    expect(repaired?.missedDoseKeys, <String>{realMiss.doseKey!});
    expect(repaired?.resolvedMissDoseKeys, isEmpty);
    expect(repeated?.hungerPoints, repaired?.hungerPoints);
  });

  test(
    'only skipped history logs can add hunger during reconciliation',
    () async {
      final noLogs = await CatRepository.instance.reconcileDoseLogs(
        const <DoseLog>[],
      );
      final missedLog = DoseLog(
        id: 'history-miss',
        medicationId: medication.id,
        medicationName: medication.name,
        dosage: '',
        recordedAt: DateTime(2026, 8, 10, 8),
        status: DoseStatus.skipped,
        doseKey: '3:2026-08-10:08:00',
      );
      final missed = await CatRepository.instance.reconcileDoseLogs(<DoseLog>[
        missedLog,
      ]);
      final repeated = await CatRepository.instance.reconcileDoseLogs(<DoseLog>[
        missedLog,
      ]);

      expect(noLogs?.hungerPoints, 0);
      expect(missed?.hungerPoints, 1);
      expect(repeated?.hungerPoints, 1);
    },
  );

  test('a newly adopted pet ignores dose history from an older pet', () async {
    final newPet = CatProfile(
      name: 'Donna',
      variant: PetVariant.dogBeagle,
      adoptedAt: DateTime(2026, 8, 10, 12),
    );
    SharedPreferences.setMockInitialValues(<String, Object>{
      'adopted_cat_v1': jsonEncode(newPet.toJson()),
    });
    final oldLogs = <DoseLog>[
      DoseLog(
        id: 'old-taken',
        medicationId: medication.id,
        medicationName: medication.name,
        dosage: '',
        recordedAt: DateTime(2026, 8, 10, 8),
        status: DoseStatus.taken,
        doseKey: '3:2026-08-10:08:00',
      ),
      DoseLog(
        id: 'old-missed',
        medicationId: medication.id,
        medicationName: medication.name,
        dosage: '',
        recordedAt: DateTime(2026, 8, 9, 8),
        status: DoseStatus.skipped,
        doseKey: '3:2026-08-09:08:00',
      ),
    ];

    final reconciled = await CatRepository.instance.reconcileDoseLogs(oldLogs);

    expect(reconciled?.feedCount, 0);
    expect(reconciled?.hungerPoints, 0);
    expect(reconciled?.rewardedDoseKeys, isEmpty);
    expect(reconciled?.missedDoseKeys, isEmpty);
  });

  test('three taken doses on one day give one growth day', () async {
    CatDoseResult? result;
    for (final time in <String>['08:00', '13:00', '20:00']) {
      result = await CatRepository.instance.applyDose(
        medication,
        DoseLog(
          id: time,
          medicationId: medication.id,
          medicationName: medication.name,
          dosage: '',
          recordedAt: DateTime(2026, 8, 10, int.parse(time.substring(0, 2))),
          status: DoseStatus.taken,
          doseKey: '3:2026-08-10:$time',
        ),
      );
    }

    expect(result?.profile.feedCount, 1);
    expect(result?.profile.rewardedDoseKeys, hasLength(3));

    result = await CatRepository.instance.applyDose(
      medication,
      DoseLog(
        id: 'next-day',
        medicationId: medication.id,
        medicationName: medication.name,
        dosage: '',
        recordedAt: DateTime(2026, 8, 11, 8),
        status: DoseStatus.taken,
        doseKey: '3:2026-08-11:08:00',
      ),
    );

    expect(result?.profile.feedCount, 2);
  });

  test('hunger stops at five and each taken dose restores one step', () async {
    CatDoseResult? result;
    for (var index = 0; index < 7; index++) {
      result = await CatRepository.instance.applyDose(
        medication,
        DoseLog(
          id: 'miss-$index',
          medicationId: medication.id,
          medicationName: medication.name,
          dosage: '',
          recordedAt: DateTime(2026, 8, index + 1, 8),
          status: DoseStatus.skipped,
          doseKey: '3:2026-08-${(index + 1).toString().padLeft(2, '0')}:08:00',
        ),
      );
    }
    expect(result?.profile.hungerPoints, 5);

    for (final time in <String>['08:00', '20:00']) {
      result = await CatRepository.instance.applyDose(
        medication,
        DoseLog(
          id: 'recover-$time',
          medicationId: medication.id,
          medicationName: medication.name,
          dosage: '',
          recordedAt: DateTime(2026, 8, 10, int.parse(time.substring(0, 2))),
          status: DoseStatus.taken,
          doseKey: '3:2026-08-10:$time',
        ),
      );
    }

    expect(result?.profile.hungerPoints, 3);
    expect(result?.profile.feedCount, 1);
  });

  test('happy points reach zero linearly over thirty minutes', () {
    final scheduledAt = DateTime(2026, 8, 10, 8);

    expect(
      CatRepository.calculateHappyPoints(
        scheduledAt: scheduledAt,
        recordedAt: scheduledAt,
        alarmCount: 1,
      ),
      30,
    );
    expect(
      CatRepository.calculateHappyPoints(
        scheduledAt: scheduledAt,
        recordedAt: scheduledAt.add(const Duration(minutes: 10)),
        alarmCount: 1,
      ),
      20,
    );
    expect(
      CatRepository.calculateHappyPoints(
        scheduledAt: scheduledAt,
        recordedAt: scheduledAt.add(const Duration(minutes: 30)),
        alarmCount: 1,
      ),
      0,
    );
  });

  test('two alarms split the daily maximum into fifteen points', () async {
    const twiceDaily = Medication(
      id: 3,
      name: 'Test',
      dosage: '',
      times: <String>['08:00', '20:00'],
      weekdays: <int>[DateTime.monday],
    );
    final adult = CatProfile(
      name: 'Milo',
      variant: PetVariant.catCalico,
      adoptedAt: DateTime(2026, 6, 1),
      feedCount: 60,
      happyPoints: 0,
    );
    SharedPreferences.setMockInitialValues(<String, Object>{
      'adopted_cat_v1': jsonEncode(adult.toJson()),
    });

    final first = await CatRepository.instance.applyDose(
      twiceDaily,
      DoseLog(
        id: 'adult-am',
        medicationId: 3,
        medicationName: 'Test',
        dosage: '',
        recordedAt: DateTime(2026, 8, 10, 8),
        status: DoseStatus.taken,
        doseKey: '3:2026-08-10:08:00',
      ),
      allMedications: const <Medication>[twiceDaily],
    );
    final second = await CatRepository.instance.applyDose(
      twiceDaily,
      DoseLog(
        id: 'adult-pm',
        medicationId: 3,
        medicationName: 'Test',
        dosage: '',
        recordedAt: DateTime(2026, 8, 10, 20, 2),
        status: DoseStatus.taken,
        doseKey: '3:2026-08-10:20:00',
      ),
      allMedications: const <Medication>[twiceDaily],
    );

    expect(first?.earnedHappyPoints, 15);
    expect(second?.earnedHappyPoints, 14);
    expect(second?.profile.happyPoints, 29);
  });

  test('the same adult dose cannot award happy points twice', () async {
    final adult = CatProfile(
      name: 'Milo',
      variant: PetVariant.catGray,
      adoptedAt: DateTime(2026, 6, 1),
      feedCount: 60,
    );
    SharedPreferences.setMockInitialValues(<String, Object>{
      'adopted_cat_v1': jsonEncode(adult.toJson()),
    });
    final log = DoseLog(
      id: 'same',
      medicationId: medication.id,
      medicationName: medication.name,
      dosage: '',
      recordedAt: DateTime(2026, 8, 10, 8),
      status: DoseStatus.taken,
      doseKey: '3:2026-08-10:08:00',
    );

    final first = await CatRepository.instance.applyDose(medication, log);
    final duplicate = await CatRepository.instance.applyDose(medication, log);

    expect(first?.profile.happyPoints, 30);
    expect(duplicate?.profile.happyPoints, 30);
    expect(duplicate?.earnedHappyPoints, 0);
  });

  test(
    'shop buys items and wardrobe equips at most one per category',
    () async {
      final adult = CatProfile(
        name: 'Milo',
        variant: PetVariant.catOrange,
        adoptedAt: DateTime(2026, 6, 1),
        feedCount: 60,
        happyPoints: 1000,
      );
      SharedPreferences.setMockInitialValues(<String, Object>{
        'adopted_cat_v1': jsonEncode(adult.toJson()),
      });
      final cap = catShopItemById('hat_cap')!;
      final wizard = catShopItemById('hat_wizard')!;

      await CatRepository.instance.purchaseAccessory(
        itemId: cap.id,
        category: cap.category,
        price: cap.price,
      );
      final updated = await CatRepository.instance.purchaseAccessory(
        itemId: wizard.id,
        category: wizard.category,
        price: wizard.price,
      );

      expect(
        updated?.ownedAccessoryIds,
        containsAll(<String>[cap.id, wizard.id]),
      );
      expect(updated?.equippedId(CatAccessoryCategory.hat), isNull);
      expect(updated?.happyPoints, 370);

      await CatRepository.instance.toggleAccessory(
        itemId: cap.id,
        category: cap.category,
      );
      final equipped = await CatRepository.instance.toggleAccessory(
        itemId: wizard.id,
        category: wizard.category,
      );
      expect(equipped?.equippedId(CatAccessoryCategory.hat), wizard.id);
    },
  );

  test('simultaneous shop taps charge an accessory only once', () async {
    final adult = CatProfile(
      name: 'Milo',
      variant: PetVariant.catOrange,
      adoptedAt: DateTime(2026, 6, 1),
      feedCount: 60,
      happyPoints: 500,
    );
    SharedPreferences.setMockInitialValues(<String, Object>{
      'adopted_cat_v1': jsonEncode(adult.toJson()),
    });
    final cap = catShopItemById('hat_cap')!;

    await Future.wait(<Future<CatProfile?>>[
      CatRepository.instance.purchaseAccessory(
        itemId: cap.id,
        category: cap.category,
        price: cap.price,
      ),
      CatRepository.instance.purchaseAccessory(
        itemId: cap.id,
        category: cap.category,
        price: cap.price,
      ),
    ]);

    final stored = await CatRepository.instance.getProfile();
    expect(stored?.ownedAccessoryIds, contains(cap.id));
    expect(stored?.happyPoints, 290);
  });

  test(
    'streak reward stays locked below its best-streak requirement',
    () async {
      final adult = CatProfile(
        name: 'Milo',
        variant: PetVariant.catOrange,
        adoptedAt: DateTime(2026, 6, 1),
        feedCount: 60,
        happyPoints: 5,
      );
      final streak = _streakWith(successDays: 39);
      SharedPreferences.setMockInitialValues(<String, Object>{
        'adopted_cat_v1': jsonEncode(adult.toJson()),
        MedicationStreakRepository.preferencesKey: jsonEncode(streak.toJson()),
      });
      final reward = catShopItemById('streak_40_hat_consistency')!;

      final unchanged = await CatRepository.instance.purchaseAccessory(
        itemId: reward.id,
        category: reward.category,
        price: reward.price,
      );

      expect(unchanged?.ownedAccessoryIds, isNot(contains(reward.id)));
      expect(unchanged?.happyPoints, 5);
    },
  );

  test('best streak permanently unlocks a free reward after a reset', () async {
    final adult = CatProfile(
      name: 'Milo',
      variant: PetVariant.catOrange,
      adoptedAt: DateTime(2026, 6, 1),
      feedCount: 60,
      happyPoints: 5,
    );
    final streak = _streakWith(successDays: 40, followedByFailure: true);
    expect(streak.current, 0);
    expect(streak.best, 40);
    SharedPreferences.setMockInitialValues(<String, Object>{
      'adopted_cat_v1': jsonEncode(adult.toJson()),
      MedicationStreakRepository.preferencesKey: jsonEncode(streak.toJson()),
    });
    final reward = catShopItemById('streak_40_hat_consistency')!;

    final claimed = await CatRepository.instance.purchaseAccessory(
      itemId: reward.id,
      category: reward.category,
      price: reward.price,
    );
    final duplicate = await CatRepository.instance.purchaseAccessory(
      itemId: reward.id,
      category: reward.category,
      price: reward.price,
    );

    expect(claimed?.ownedAccessoryIds, contains(reward.id));
    expect(claimed?.happyPoints, 5);
    expect(duplicate?.ownedAccessoryIds, contains(reward.id));
    expect(duplicate?.happyPoints, 5);
  });

  test('verified support grants the exclusive reward only once', () async {
    final adult = CatProfile(
      name: 'Milo',
      variant: PetVariant.catTuxedo,
      adoptedAt: DateTime(2026, 6, 1),
      feedCount: 60,
    );
    SharedPreferences.setMockInitialValues(<String, Object>{
      'adopted_cat_v1': jsonEncode(adult.toJson()),
    });

    final first = await CatRepository.instance.registerVerifiedSupport(
      transactionId: 'verified-1',
    );
    final second = await CatRepository.instance.registerVerifiedSupport(
      transactionId: 'verified-2',
    );
    final duplicate = await CatRepository.instance.registerVerifiedSupport(
      transactionId: 'verified-1',
    );

    expect(first?.firstRewardGranted, isTrue);
    expect(first?.profile.happyPoints, 100);
    expect(
      first?.profile.ownedAccessoryIds,
      containsAll(supporterAccessoryIds),
    );
    expect(first?.profile.equippedAccessories, isEmpty);
    expect(second?.firstRewardGranted, isFalse);
    expect(second?.profile.happyPoints, 100);
    expect(duplicate?.duplicateTransaction, isTrue);
    expect(duplicate?.profile.processedSupportTransactions, hasLength(2));
  });

  test('a young pet cannot receive happy points from support', () async {
    final young = CatProfile(
      name: 'Nova',
      variant: PetVariant.dogGolden,
      adoptedAt: DateTime(2026, 6, 1),
      feedCount: 14,
    );
    SharedPreferences.setMockInitialValues(<String, Object>{
      'adopted_cat_v1': jsonEncode(young.toJson()),
    });

    final result = await CatRepository.instance.registerVerifiedSupport(
      transactionId: 'too-young',
    );

    expect(result?.firstRewardGranted, isFalse);
    expect(result?.profile.happyPoints, 0);
    expect(result?.profile.processedSupportTransactions, isEmpty);
    expect(result?.profile.ownedAccessoryIds, isEmpty);
  });

  test('a taken dose cannot earn happy points while pet is young', () async {
    final young = CatProfile(
      name: 'Nova',
      variant: PetVariant.dogBeagle,
      adoptedAt: DateTime(2026, 6, 1),
      feedCount: 14,
    );
    SharedPreferences.setMockInitialValues(<String, Object>{
      'adopted_cat_v1': jsonEncode(young.toJson()),
    });
    final log = DoseLog(
      id: 'young-dose',
      medicationId: medication.id,
      medicationName: medication.name,
      dosage: '',
      recordedAt: DateTime(2026, 8, 10, 8),
      status: DoseStatus.taken,
      doseKey: '3:2026-08-10:08:00',
    );

    final result = await CatRepository.instance.applyDose(
      medication,
      log,
      allMedications: const <Medication>[medication],
    );

    expect(result?.profile.stage, CatStage.young);
    expect(result?.earnedHappyPoints, 0);
    expect(result?.profile.happyPoints, 0);
  });

  test('the dose that makes a pet adult does not award points yet', () async {
    final almostAdult = CatProfile(
      name: 'Nova',
      variant: PetVariant.dogBeagle,
      adoptedAt: DateTime(2026, 6, 1),
      feedCount: 59,
    );
    SharedPreferences.setMockInitialValues(<String, Object>{
      'adopted_cat_v1': jsonEncode(almostAdult.toJson()),
    });
    final log = DoseLog(
      id: 'adult-boundary',
      medicationId: medication.id,
      medicationName: medication.name,
      dosage: '',
      recordedAt: DateTime(2026, 8, 10, 8),
      status: DoseStatus.taken,
      doseKey: '3:2026-08-10:08:00',
    );

    final result = await CatRepository.instance.applyDose(
      medication,
      log,
      allMedications: const <Medication>[medication],
    );

    expect(result?.profile.stage, CatStage.adult);
    expect(result?.earnedHappyPoints, 0);
    expect(result?.profile.happyPoints, 0);
  });

  test('owned items survive a new adoption but wait for adulthood', () async {
    final adult = CatProfile(
      name: 'Milo',
      variant: PetVariant.catTuxedo,
      adoptedAt: DateTime(2026, 1, 1),
      feedCount: 60,
      ownedAccessoryIds: const <String>{'hat_cap', 'glasses_round'},
      equippedAccessories: const <String, String>{'hat': 'hat_cap'},
      supporterRewardClaimed: true,
      processedSupportTransactions: const <String>{'support-1'},
      processedCodeRedemptions: const <String>{'code-1'},
    );
    SharedPreferences.setMockInitialValues(<String, Object>{
      'adopted_cat_v1': jsonEncode(adult.toJson()),
    });

    await CatRepository.instance.remove();
    final kitten = await CatRepository.instance.adopt(
      name: 'Nova',
      variant: PetVariant.catGray,
    );

    expect(kitten.stage, CatStage.kitten);
    expect(
      kitten.ownedAccessoryIds,
      containsAll(<String>['hat_cap', 'glasses_round']),
    );
    expect(kitten.equippedAccessories, isEmpty);
    expect(kitten.supporterRewardClaimed, isTrue);
    expect(kitten.processedSupportTransactions, contains('support-1'));
    expect(kitten.processedCodeRedemptions, contains('code-1'));

    final unchanged = await CatRepository.instance.toggleAccessory(
      itemId: 'hat_cap',
      category: CatAccessoryCategory.hat,
    );
    expect(unchanged?.equippedAccessories, isEmpty);
    expect(await CatRepository.instance.isChickenUnlocked(), isTrue);
  });

  test('removing an adult dog does not unlock the chicken', () async {
    final dog = CatProfile(
      name: 'Bobby',
      variant: PetVariant.dogGolden,
      adoptedAt: DateTime(2026, 1, 1),
      feedCount: 60,
    );
    SharedPreferences.setMockInitialValues(<String, Object>{
      'adopted_cat_v1': jsonEncode(dog.toJson()),
    });

    await CatRepository.instance.remove();

    expect(await CatRepository.instance.isChickenUnlocked(), isFalse);
  });

  test('exclusive reward items cannot be bought with happy points', () async {
    final adult = CatProfile(
      name: 'Milo',
      variant: PetVariant.catOrange,
      adoptedAt: DateTime(2026, 6, 1),
      feedCount: 60,
      happyPoints: 1000,
    );
    SharedPreferences.setMockInitialValues(<String, Object>{
      'adopted_cat_v1': jsonEncode(adult.toJson()),
    });

    await CatRepository.instance.purchaseAccessory(
      itemId: 'supporter_hat',
      category: CatAccessoryCategory.hat,
      price: 0,
    );
    final updated = await CatRepository.instance.purchaseAccessory(
      itemId: 'doctor_hat_fezz',
      category: CatAccessoryCategory.hat,
      price: 0,
    );

    expect(updated?.ownedAccessoryIds, isNot(contains('supporter_hat')));
    expect(updated?.ownedAccessoryIds, isNot(contains('doctor_hat_fezz')));
    expect(updated?.happyPoints, 1000);
  });

  test('hidden reward items never appear in the shop', () {
    final adult = CatProfile(
      name: 'Milo',
      variant: PetVariant.catOrange,
      adoptedAt: DateTime(2026, 6, 1),
      feedCount: 60,
    );

    expect(
      visibleCatShopCatalog(adult).map((item) => item.id),
      isNot(contains('supporter_hat')),
    );
    expect(
      visibleCatShopCatalog(
        adult.copyWith(ownedAccessoryIds: const <String>{'supporter_hat'}),
      ).map((item) => item.id),
      isNot(contains('supporter_hat')),
    );
  });

  test('chicken-themed items appear only after the chicken unlock', () {
    final adult = CatProfile(
      name: 'Milo',
      variant: PetVariant.catOrange,
      adoptedAt: DateTime(2026, 6, 1),
      feedCount: 60,
    );

    expect(
      visibleCatShopCatalog(adult).map((item) => item.id),
      isNot(contains('chicken_hat_straw')),
    );
    expect(
      visibleCatShopCatalog(
        adult,
        chickenUnlocked: true,
      ).map((item) => item.id),
      containsAll(<String>[
        'chicken_hat_straw',
        'chicken_glasses_egg',
        'chicken_outfit_overalls',
        'chicken_toy_corn',
      ]),
    );
  });

  test('adult play schedule has two or three moments with 33 minute gaps', () {
    for (var seed = 0; seed < 30; seed++) {
      final random = Random(seed);
      final count = 2 + random.nextInt(2);
      final moments = CatRepository.generatePlayMomentMinutes(
        random: random,
        count: count,
      );

      expect(moments, hasLength(count));
      expect(moments, orderedEquals(<int>[...moments]..sort()));
      for (var index = 1; index < moments.length; index++) {
        expect(
          moments[index] - moments[index - 1],
          greaterThanOrEqualTo(CatRepository.minimumPlayGapMinutes),
        );
      }
    }
  });

  test(
    'adult daily play schedule is stored and does not move on refresh',
    () async {
      final adult = CatProfile(
        name: 'Milo',
        variant: PetVariant.catCalico,
        adoptedAt: DateTime(2026, 1, 1),
        feedCount: 60,
      );
      SharedPreferences.setMockInitialValues(<String, Object>{
        'adopted_cat_v1': jsonEncode(adult.toJson()),
      });

      final first = await CatRepository.instance.ensurePlaySchedule(
        at: DateTime(2026, 8, 10, 8),
        random: Random(12),
      );
      final refreshed = await CatRepository.instance.ensurePlaySchedule(
        at: DateTime(2026, 8, 10, 18),
        random: Random(99),
      );

      expect(first?.playScheduleDay, '2026-08-10');
      expect(first?.playMomentMinutes.length, anyOf(2, 3));
      expect(refreshed?.playMomentMinutes, first?.playMomentMinutes);
    },
  );

  test('playing during the one-minute window awards ten points once', () async {
    final now = DateTime(2026, 8, 10, 14, 27, 20);
    final day = '2026-08-10';
    final minute = now.hour * 60 + now.minute;
    final adult = CatProfile(
      name: 'Milo',
      variant: PetVariant.catGray,
      adoptedAt: DateTime(2026, 1, 1),
      feedCount: 60,
      happyPoints: 50,
      playScheduleDay: day,
      playMomentMinutes: <int>[minute, minute + 60],
    );
    SharedPreferences.setMockInitialValues(<String, Object>{
      'adopted_cat_v1': jsonEncode(adult.toJson()),
    });
    final key = CatRepository.currentPlayMomentKey(adult, at: now);

    expect(key, '$day:$minute');
    final first = await CatRepository.instance.playWithCat(
      momentKey: key!,
      at: now,
    );
    final second = await CatRepository.instance.playWithCat(
      momentKey: key,
      at: now,
    );

    expect(first?.rewarded, isTrue);
    expect(first?.profile.happyPoints, 60);
    expect(second?.rewarded, isFalse);
    expect(second?.profile.happyPoints, 60);
  });
}

MedicationStreakState _streakWith({
  required int successDays,
  bool followedByFailure = false,
}) {
  final results = <String, MedicationStreakDayResult>{};
  final start = DateTime(2026, 1, 1);
  for (var offset = 0; offset < successDays; offset++) {
    results[medicationStreakDayKey(start.add(Duration(days: offset)))] =
        MedicationStreakDayResult.success;
  }
  if (followedByFailure) {
    results[medicationStreakDayKey(start.add(Duration(days: successDays)))] =
        MedicationStreakDayResult.failed;
  }
  return MedicationStreakState(dayResults: results);
}

class _FixedBoolRandom implements Random {
  _FixedBoolRandom(this.value);

  final bool value;

  @override
  bool nextBool() => value;

  @override
  double nextDouble() => value ? .75 : .25;

  @override
  int nextInt(int max) => value && max > 1 ? 1 : 0;
}
