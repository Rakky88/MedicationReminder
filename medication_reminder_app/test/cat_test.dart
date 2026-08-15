import 'package:flutter_test/flutter_test.dart';
import 'package:medication_reminder_app/cat.dart';
import 'package:medication_reminder_app/pet_costumes.dart';

void main() {
  CatProfile catWithGrowthDays(int growthDays) => CatProfile(
    name: 'Milo',
    variant: PetVariant.catOrange,
    adoptedAt: DateTime(2026, 8, 9),
    feedCount: growthDays,
  );

  test('cat grows at exactly 14 and 60 rewarded calendar days', () {
    expect(catWithGrowthDays(13).stage, CatStage.kitten);
    expect(catWithGrowthDays(14).stage, CatStage.young);
    expect(catWithGrowthDays(59).stage, CatStage.young);
    expect(catWithGrowthDays(60).stage, CatStage.adult);
  });

  test('growth progress follows both calendar-day stages internally', () {
    expect(catWithGrowthDays(7).growthProgress, 0.5);
    expect(catWithGrowthDays(14).growthProgress, 0);
    expect(catWithGrowthDays(37).growthProgress, 0.5);
    expect(catWithGrowthDays(60).growthProgress, 1);
  });

  test('stored dose history migrates to unique rewarded days', () {
    final legacyJson = CatProfile(
      name: 'Milo',
      variant: PetVariant.catOrange,
      adoptedAt: DateTime(2026, 8, 1),
      feedCount: 3,
      rewardedDoseKeys: const <String>{
        '1:2026-08-10:08:00',
        '1:2026-08-10:20:00',
        '1:2026-08-11:08:00',
      },
    ).toJson()..remove('growthModelVersion');
    final restored = CatProfile.fromJson(legacyJson);

    expect(restored.feedCount, 2);
  });

  test('stored hunger is capped at five missed doses', () {
    final restored = CatProfile.fromJson(
      CatProfile(
        name: 'Milo',
        variant: PetVariant.catOrange,
        adoptedAt: DateTime(2026, 8, 1),
        hungerPoints: 99,
      ).toJson(),
    );

    expect(restored.hungerPoints, 5);
    expect(restored.hungerLevel, CatHungerLevel.veryHungry);
  });

  test('legacy hunger data is marked for one-time reconciliation', () {
    final legacyJson = CatProfile(
      name: 'Milo',
      variant: PetVariant.catBlackBib,
      adoptedAt: DateTime(2026, 8, 1),
    ).toJson()..remove('hungerModelVersion');

    expect(CatProfile.fromJson(legacyJson).hungerModelVersion, 1);
    expect(
      CatProfile.fromJson(
        CatProfile(
          name: 'Milo',
          variant: PetVariant.catBlackBib,
          adoptedAt: DateTime(2026, 8, 1),
        ).toJson(),
      ).hungerModelVersion,
      2,
    );
  });

  test('persistent meowing preference survives storage', () {
    final restored = CatProfile.fromJson(
      CatProfile(
        name: 'Milo',
        variant: PetVariant.catTuxedo,
        adoptedAt: DateTime(2026, 8, 1),
        persistentMeowEnabled: false,
      ).toJson(),
    );

    expect(restored.persistentMeowEnabled, isFalse);
  });

  test('dragon mode is opt-in, persists, and only shows while young', () {
    final legacy = CatProfile.fromJson(<String, Object?>{
      'name': 'Nova',
      'variant': PetVariant.dogGolden.name,
      'adoptedAt': DateTime(2026, 8, 1).toIso8601String(),
      'feedCount': 14,
      'growthModelVersion': 2,
    });
    final young = CatProfile.fromJson(
      legacy.copyWith(dragonMode: true).toJson(),
    );

    expect(legacy.dragonMode, isFalse);
    expect(young.dragonMode, isTrue);
    expect(showsDragonModeCostume(young), isTrue);
    expect(showsDragonModeCostume(young.copyWith(feedCount: 13)), isFalse);
    expect(showsDragonModeCostume(young.copyWith(feedCount: 60)), isFalse);
  });

  test('legacy sound setting migrates to separate purr and meow settings', () {
    final disabled = CatProfile.fromJson(<String, Object?>{
      'name': 'Milo',
      'variant': 'orange',
      'adoptedAt': DateTime(2026, 8, 1).toIso8601String(),
      'soundEnabled': false,
    });
    final split = CatProfile.fromJson(<String, Object?>{
      'name': 'Milo',
      'variant': 'orange',
      'adoptedAt': DateTime(2026, 8, 1).toIso8601String(),
      'soundEnabled': false,
      'purrEnabled': true,
      'meowEnabled': false,
    });

    expect(disabled.purrEnabled, isFalse);
    expect(disabled.meowEnabled, isFalse);
    expect(split.purrEnabled, isTrue);
    expect(split.meowEnabled, isFalse);
    expect(disabled.variant, PetVariant.catOrange);
    expect(disabled.species, PetSpecies.cat);
    expect(disabled.happySoundEnabled, isFalse);
    expect(disabled.hungrySoundEnabled, isFalse);
  });

  test('long-running pet timelines keep only the newest thousand entries', () {
    String day(DateTime value) =>
        '${value.year}-${value.month.toString().padLeft(2, '0')}-'
        '${value.day.toString().padLeft(2, '0')}';
    final dates = List<DateTime>.generate(
      CatProfile.maxStoredTimelineEntries + 5,
      (index) => DateTime(2020, 1, 1).add(Duration(days: index)),
    );
    final doseKeys = dates.map((date) => '1:${day(date)}:08:00').toSet();
    final playKeys = dates.map((date) => '${day(date)}:600').toSet();
    final restored = CatProfile.fromJson(
      CatProfile(
        name: 'Dimi',
        variant: PetVariant.dogGolden,
        adoptedAt: DateTime(2020),
        rewardedDoseKeys: doseKeys,
        missedDoseKeys: doseKeys,
        recoveryDoseKeys: doseKeys,
        resolvedMissDoseKeys: doseKeys,
        happyPointAwards: {for (final key in doseKeys) key: 1},
        playedMomentKeys: playKeys,
      ).toJson(),
    );

    expect(restored.rewardedDoseKeys, hasLength(1000));
    expect(restored.missedDoseKeys, hasLength(1000));
    expect(restored.recoveryDoseKeys, hasLength(1000));
    expect(restored.resolvedMissDoseKeys, hasLength(1000));
    expect(restored.happyPointAwards, hasLength(1000));
    expect(restored.playedMomentKeys, hasLength(1000));
    expect(restored.rewardedDoseKeys, contains('1:${day(dates.last)}:08:00'));
    expect(
      restored.rewardedDoseKeys,
      isNot(contains('1:${day(dates.first)}:08:00')),
    );
  });

  test('dog and chicken variants use their own growth sprites', () {
    final dog = CatProfile(
      name: 'Bobby',
      variant: PetVariant.dogBeagle,
      adoptedAt: DateTime(2026, 8, 1),
      feedCount: 60,
    );
    final chicken = dog.copyWith(variant: PetVariant.chickenHen, feedCount: 14);

    expect(dog.species, PetSpecies.dog);
    expect(dog.assetPath, 'assets/cats/dog_beagle_adult.png');
    expect(chicken.species, PetSpecies.chicken);
    expect(chicken.assetPath, 'assets/cats/chicken_hen_young.png');
    expect(petVariantsForSpecies(PetSpecies.dog), hasLength(5));
    expect(petVariantsForSpecies(PetSpecies.cat), hasLength(5));
  });
}
