import 'dart:convert';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

import 'async_operation_queue.dart';
import 'cat.dart';
import 'cat_shop.dart';
import 'medication.dart';
import 'medication_streak_repository.dart';

class CatRepository {
  CatRepository._();

  static final CatRepository instance = CatRepository._();
  final AsyncOperationQueue _operations = AsyncOperationQueue();
  static const _catKey = 'adopted_cat_v1';
  static const _entitlementsKey = 'cat_entitlements_v1';

  /// Selects the initial adoption name. [nextBool] gives both names an equal
  /// probability and an injectable generator keeps this behavior testable.
  static String randomDefaultPetName([Random? random]) =>
      (random ?? Random.secure()).nextBool() ? 'Dimi' : 'Donna';

  Future<CatProfile?> getProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final source = prefs.getString(_catKey);
    if (source == null || source.isEmpty) return null;
    try {
      final json = Map<String, Object?>.from(
        jsonDecode(source) as Map<dynamic, dynamic>,
      );
      if (json['name'] is! String ||
          (json['name'] as String).trim().isEmpty ||
          json['variant'] is! String ||
          DateTime.tryParse(json['adoptedAt'] as String? ?? '') == null) {
        throw const FormatException('Stored pet profile is incomplete.');
      }
      final profile = CatProfile.fromJson(json);
      final entitlements = _CatEntitlements.fromPreferences(prefs);
      return profile.copyWith(
        ownedAccessoryIds: <String>{
          ...profile.ownedAccessoryIds,
          ...entitlements.ownedAccessoryIds,
        },
        supporterRewardClaimed:
            profile.supporterRewardClaimed ||
            entitlements.supporterRewardClaimed,
        processedSupportTransactions: <String>{
          ...profile.processedSupportTransactions,
          ...entitlements.processedSupportTransactions,
        },
        processedCodeRedemptions: <String>{
          ...profile.processedCodeRedemptions,
          ...entitlements.processedCodeRedemptions,
        },
      );
    } on FormatException {
      rethrow;
    } on Object catch (error) {
      throw FormatException('Stored pet data could not be decoded.', error);
    }
  }

  Future<CatProfile> adopt({
    required String name,
    required PetVariant variant,
    bool purrEnabled = true,
    bool meowEnabled = true,
    bool persistentMeowEnabled = true,
  }) => _operations.run(
    () => _adopt(
      name: name,
      variant: variant,
      purrEnabled: purrEnabled,
      meowEnabled: meowEnabled,
      persistentMeowEnabled: persistentMeowEnabled,
    ),
  );

  Future<CatProfile> _adopt({
    required String name,
    required PetVariant variant,
    required bool purrEnabled,
    required bool meowEnabled,
    required bool persistentMeowEnabled,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final existingSource = prefs.getString(_catKey);
    if (existingSource != null && existingSource.isNotEmpty) {
      final existing = await getProfile();
      if (existing != null) {
        throw StateError('A pet has already been adopted.');
      }
    }
    final entitlements = _CatEntitlements.fromPreferences(prefs);
    final profile = CatProfile(
      name: name.trim().isEmpty ? randomDefaultPetName() : name.trim(),
      variant: variant,
      adoptedAt: DateTime.now(),
      purrEnabled: purrEnabled,
      meowEnabled: meowEnabled,
      persistentMeowEnabled: persistentMeowEnabled,
      ownedAccessoryIds: entitlements.ownedAccessoryIds,
      supporterRewardClaimed: entitlements.supporterRewardClaimed,
      processedSupportTransactions: entitlements.processedSupportTransactions,
      processedCodeRedemptions: entitlements.processedCodeRedemptions,
    );
    await _save(profile);
    return profile;
  }

  Future<bool> isChickenUnlocked() async {
    final prefs = await SharedPreferences.getInstance();
    return _CatEntitlements.fromPreferences(prefs).adultCatEverRaised;
  }

  Future<CatProfile> updateSettings(
    CatProfile profile, {
    required String name,
    required bool purrEnabled,
    required bool meowEnabled,
    required bool persistentMeowEnabled,
    required bool dragonMode,
  }) => _operations.run(
    () => _updateSettings(
      profile,
      name: name,
      purrEnabled: purrEnabled,
      meowEnabled: meowEnabled,
      persistentMeowEnabled: persistentMeowEnabled,
      dragonMode: dragonMode,
    ),
  );

  Future<CatProfile> _updateSettings(
    CatProfile profile, {
    required String name,
    required bool purrEnabled,
    required bool meowEnabled,
    required bool persistentMeowEnabled,
    required bool dragonMode,
  }) async {
    final updated = profile.copyWith(
      name: name.trim().isEmpty ? profile.name : name.trim(),
      purrEnabled: purrEnabled,
      meowEnabled: meowEnabled,
      persistentMeowEnabled: persistentMeowEnabled,
      dragonMode: dragonMode,
    );
    await _save(updated);
    return updated;
  }

  Future<void> remove() => _operations.run(_remove);

  Future<void> _remove() async {
    final prefs = await SharedPreferences.getInstance();
    final source = prefs.getString(_catKey);
    if (source != null && source.isNotEmpty) {
      try {
        final profile = CatProfile.fromJson(
          Map<String, Object?>.from(
            jsonDecode(source) as Map<dynamic, dynamic>,
          ),
        );
        await _saveEntitlements(prefs, profile);
      } on Object {
        // A damaged cat profile must not block finding the cat a new home.
      }
    }
    await _requireStored(prefs.remove(_catKey), _catKey);
  }

  Future<CatProfile?> reconcileDoseLogs(List<DoseLog> logs) =>
      _operations.run(() => _reconcileDoseLogs(logs));

  Future<CatProfile?> _reconcileDoseLogs(List<DoseLog> logs) async {
    final loadedProfile = await getProfile();
    if (loadedProfile == null) return null;
    var profile = loadedProfile;

    final eligibleLogs = logs
        .where(
          (log) =>
              log.doseKey != null &&
              !log.scheduledAt.isBefore(profile.adoptedAt),
        )
        .toList();
    final takenKeys = eligibleLogs
        .where((log) => log.status == DoseStatus.taken)
        .map((log) => log.doseKey!)
        .toSet();
    final skippedKeys = eligibleLogs
        .where((log) => log.status == DoseStatus.skipped)
        .map((log) => log.doseKey!)
        .toSet();

    var changed = false;
    if (profile.hungerModelVersion < 2) {
      final validMissedKeys = profile.missedDoseKeys.intersection(skippedKeys);
      final orphanCount =
          profile.missedDoseKeys.length - validMissedKeys.length;
      profile = profile.copyWith(
        hungerModelVersion: 2,
        hungerPoints: (profile.hungerPoints - orphanCount).clamp(0, 5),
        missedDoseKeys: validMissedKeys,
        recoveryDoseKeys: profile.recoveryDoseKeys.intersection(takenKeys),
        resolvedMissDoseKeys: const <String>{},
      );
      changed = true;
    }

    final orderedLogs = eligibleLogs
      ..sort((left, right) {
        final scheduled = left.scheduledAt.compareTo(right.scheduledAt);
        return scheduled != 0
            ? scheduled
            : left.recordedAt.compareTo(right.recordedAt);
      });
    for (final log in orderedLogs) {
      final key = log.doseKey!;
      if (log.status == DoseStatus.taken) {
        if (!profile.rewardedDoseKeys.contains(key)) {
          profile = _feed(profile, key, log.recordedAt.toLocal());
          changed = true;
        }
      } else {
        final updated = _markMissed(profile, key);
        if (identical(updated, profile)) continue;
        profile = updated;
        changed = true;
      }
    }
    if (changed) await _save(profile);
    return profile;
  }

  Future<CatDoseResult?> applyDose(
    Medication medication,
    DoseLog log, {
    List<Medication> allMedications = const <Medication>[],
  }) => _operations.run(
    () => _applyDose(medication, log, allMedications: allMedications),
  );

  Future<CatDoseResult?> _applyDose(
    Medication medication,
    DoseLog log, {
    List<Medication> allMedications = const <Medication>[],
  }) async {
    var profile = await getProfile();
    if (profile == null || log.doseKey == null) return null;
    final key = log.doseKey!;

    if (log.status == DoseStatus.taken) {
      if (profile.rewardedDoseKeys.contains(key)) {
        return CatDoseResult(profile: profile);
      }
      final wasAdultBeforeDose = profile.stage == CatStage.adult;
      profile = _feed(profile, key, log.recordedAt.toLocal());
      var earnedHappyPoints = 0.0;
      if (wasAdultBeforeDose && !profile.happyPointAwards.containsKey(key)) {
        final scheduledAt = _scheduledAtFromDoseKey(key);
        if (scheduledAt != null) {
          final medications = allMedications.isEmpty
              ? <Medication>[medication]
              : allMedications;
          final alarmCount = medications
              .where(
                (item) =>
                    item.enabled && item.weekdays.contains(scheduledAt.weekday),
              )
              .fold<int>(0, (total, item) => total + item.times.length)
              .clamp(1, 1 << 20);
          earnedHappyPoints = calculateHappyPoints(
            scheduledAt: scheduledAt,
            recordedAt: log.recordedAt.toLocal(),
            alarmCount: alarmCount,
          );
          final awards = <String, double>{
            ...profile.happyPointAwards,
            key: earnedHappyPoints,
          };
          profile = profile.copyWith(
            happyPoints: profile.happyPoints + earnedHappyPoints,
            happyPointAwards: awards,
          );
        }
      }
      await _save(profile);
      return CatDoseResult(
        profile: profile,
        fed: true,
        earnedHappyPoints: earnedHappyPoints,
      );
    }

    final updated = _markMissed(profile, key);
    if (!identical(updated, profile)) {
      profile = updated;
      await _save(profile);
    }
    return CatDoseResult(profile: profile);
  }

  Future<CatProfile?> undoDose(DoseLog log) =>
      _operations.run(() => _undoDose(log));

  Future<CatProfile?> _undoDose(DoseLog log) async {
    var profile = await getProfile();
    final key = log.doseKey;
    if (profile == null || key == null) return profile;

    if (log.status == DoseStatus.taken &&
        profile.rewardedDoseKeys.contains(key)) {
      final rewarded = {...profile.rewardedDoseKeys}..remove(key);
      final recovery = {...profile.recoveryDoseKeys};
      final resolved = {...profile.resolvedMissDoseKeys};
      final missed = {...profile.missedDoseKeys};
      final awards = {...profile.happyPointAwards};
      final removedAward = awards.remove(key) ?? 0;
      final doseDay = _dayFromDoseKey(key);
      final stillRewardedOnDay =
          doseDay != null &&
          rewarded.any(
            (rewardedKey) => _dayFromDoseKey(rewardedKey) == doseDay,
          );
      var hunger = profile.hungerPoints;
      if (recovery.remove(key)) hunger = (hunger + 1).clamp(0, 5);
      if (resolved.remove(key)) {
        missed.add(key);
        hunger = (hunger + 1).clamp(0, 5);
      }
      profile = profile.copyWith(
        feedCount: stillRewardedOnDay
            ? profile.feedCount
            : (profile.feedCount - 1).clamp(0, 1 << 30),
        hungerPoints: hunger,
        rewardedDoseKeys: rewarded,
        recoveryDoseKeys: recovery,
        resolvedMissDoseKeys: resolved,
        missedDoseKeys: missed,
        happyPoints: (profile.happyPoints - removedAward).clamp(
          0,
          double.infinity,
        ),
        happyPointAwards: awards,
      );
    } else if (log.status == DoseStatus.skipped &&
        profile.missedDoseKeys.contains(key)) {
      final missed = {...profile.missedDoseKeys}..remove(key);
      profile = profile.copyWith(
        missedDoseKeys: missed,
        hungerPoints: (profile.hungerPoints - 1).clamp(0, 5),
      );
    }
    await _save(profile);
    return profile;
  }

  Future<CatProfile?> purchaseAccessory({
    required String itemId,
    required CatAccessoryCategory category,
    required double price,
  }) => _operations.run(
    () => _purchaseAccessory(itemId: itemId, category: category, price: price),
  );

  Future<CatProfile?> _purchaseAccessory({
    required String itemId,
    required CatAccessoryCategory category,
    required double price,
  }) async {
    final profile = await getProfile();
    final item = catShopItemById(itemId);
    if (profile == null ||
        item == null ||
        item.category != category ||
        item.price != price ||
        item.hiddenUntilOwned ||
        profile.stage != CatStage.adult ||
        profile.ownedAccessoryIds.contains(itemId) ||
        profile.happyPoints < item.price) {
      return profile;
    }
    if (item.requiredMedicationStreak case final requirement?) {
      final streak = await MedicationStreakRepository.instance.getState();
      if (streak.best < requirement) return profile;
    }
    final updated = profile.copyWith(
      happyPoints: profile.happyPoints - item.price,
      ownedAccessoryIds: <String>{...profile.ownedAccessoryIds, itemId},
    );
    await _save(updated);
    return updated;
  }

  Future<CatSupportResult?> registerVerifiedSupport({
    required String transactionId,
  }) => _operations.run(
    () => _registerVerifiedSupport(transactionId: transactionId),
  );

  Future<CatSupportResult?> _registerVerifiedSupport({
    required String transactionId,
  }) async {
    var profile = await getProfile();
    final id = transactionId.trim();
    if (profile == null || id.isEmpty) return null;
    if (profile.stage != CatStage.adult) {
      // Support rewards include happy points and therefore only become
      // claimable once the current pet is an adult.
      return CatSupportResult(profile: profile);
    }
    if (profile.processedSupportTransactions.contains(id)) {
      return CatSupportResult(profile: profile, duplicateTransaction: true);
    }
    final firstReward = !profile.supporterRewardClaimed;
    final transactions = <String>{...profile.processedSupportTransactions, id};
    if (firstReward) {
      profile = profile.copyWith(
        happyPoints: profile.happyPoints + 100,
        supporterRewardClaimed: true,
        processedSupportTransactions: transactions,
        ownedAccessoryIds: <String>{
          ...profile.ownedAccessoryIds,
          ...supporterAccessoryIds,
        },
      );
    } else {
      profile = profile.copyWith(processedSupportTransactions: transactions);
    }
    await _save(profile);
    return CatSupportResult(profile: profile, firstRewardGranted: firstReward);
  }

  Future<CatProfile?> toggleAccessory({
    required String itemId,
    required CatAccessoryCategory category,
  }) => _operations.run(
    () => _toggleAccessory(itemId: itemId, category: category),
  );

  Future<CatProfile?> _toggleAccessory({
    required String itemId,
    required CatAccessoryCategory category,
  }) async {
    final profile = await getProfile();
    final item = catShopItemById(itemId);
    if (profile == null ||
        item == null ||
        item.category != category ||
        profile.stage != CatStage.adult ||
        !profile.ownedAccessoryIds.contains(itemId)) {
      return profile;
    }
    final equipped = <String, String>{...profile.equippedAccessories};
    if (equipped[category.name] == itemId) {
      equipped.remove(category.name);
    } else {
      equipped[category.name] = itemId;
    }
    final updated = profile.copyWith(equippedAccessories: equipped);
    await _save(updated);
    return updated;
  }

  Future<CatProfile?> ensurePlaySchedule({DateTime? at, Random? random}) =>
      _operations.run(() => _ensurePlaySchedule(at: at, random: random));

  Future<CatProfile?> _ensurePlaySchedule({
    DateTime? at,
    Random? random,
  }) async {
    final profile = await getProfile();
    if (profile == null || profile.stage != CatStage.adult) return profile;
    final now = (at ?? DateTime.now()).toLocal();
    final day = _localDay(now);
    if (profile.playScheduleDay == day &&
        (profile.playMomentMinutes.length == 2 ||
            profile.playMomentMinutes.length == 3)) {
      return profile;
    }

    var earliestMinute = 0;
    final previousDay = DateTime(now.year, now.month, now.day - 1);
    if (profile.playScheduleDay == _localDay(previousDay) &&
        profile.playMomentMinutes.isNotEmpty) {
      final previousLast = profile.playMomentMinutes.reduce(max);
      final acrossMidnightGap = 24 * 60 - previousLast;
      if (acrossMidnightGap < minimumPlayGapMinutes) {
        earliestMinute = minimumPlayGapMinutes - acrossMidnightGap;
      }
    }
    final generator = random ?? Random.secure();
    final count = 2 + generator.nextInt(2);
    final moments = generatePlayMomentMinutes(
      random: generator,
      count: count,
      earliestMinute: earliestMinute,
    );
    final recentThreshold = now.subtract(const Duration(days: 45));
    final played = profile.playedMomentKeys.where((key) {
      final separator = key.lastIndexOf(':');
      if (separator <= 0) return false;
      final date = DateTime.tryParse(key.substring(0, separator));
      return date != null && !date.isBefore(recentThreshold);
    }).toSet();
    final updated = profile.copyWith(
      playScheduleDay: day,
      playMomentMinutes: moments,
      playedMomentKeys: played,
    );
    await _save(updated);
    return updated;
  }

  Future<CatPlayResult?> playWithCat({
    required String momentKey,
    DateTime? at,
  }) => _operations.run(() => _playWithCat(momentKey: momentKey, at: at));

  Future<CatPlayResult?> _playWithCat({
    required String momentKey,
    DateTime? at,
  }) async {
    final profile = await getProfile();
    if (profile == null ||
        profile.stage != CatStage.adult ||
        profile.playedMomentKeys.contains(momentKey) ||
        currentPlayMomentKey(profile, at: at) != momentKey) {
      return profile == null ? null : CatPlayResult(profile: profile);
    }
    final updated = profile.copyWith(
      happyPoints: profile.happyPoints + 10,
      playedMomentKeys: <String>{...profile.playedMomentKeys, momentKey},
    );
    await _save(updated);
    return CatPlayResult(profile: updated, rewarded: true);
  }

  Future<CatCodeRewardResult?> registerCodeReward({
    required String redemptionId,
    required Set<String> itemIds,
  }) => _operations.run(
    () => _registerCodeReward(redemptionId: redemptionId, itemIds: itemIds),
  );

  Future<CatCodeRewardResult?> _registerCodeReward({
    required String redemptionId,
    required Set<String> itemIds,
  }) async {
    final profile = await getProfile();
    final id = redemptionId.trim();
    if (profile == null || id.isEmpty) return null;
    if (profile.processedCodeRedemptions.contains(id)) {
      return CatCodeRewardResult(profile: profile, duplicate: true);
    }
    final validItems = itemIds.where((itemId) {
      final item = catShopItemById(itemId);
      return item?.codeExclusive == true;
    }).toSet();
    if (validItems.isEmpty) return CatCodeRewardResult(profile: profile);
    final updated = profile.copyWith(
      ownedAccessoryIds: <String>{...profile.ownedAccessoryIds, ...validItems},
      processedCodeRedemptions: <String>{
        ...profile.processedCodeRedemptions,
        id,
      },
    );
    await _save(updated);
    return CatCodeRewardResult(profile: updated, grantedItemIds: validItems);
  }

  static const minimumPlayGapMinutes = 33;

  static List<int> generatePlayMomentMinutes({
    required Random random,
    required int count,
    int earliestMinute = 0,
  }) {
    if (count < 1 || count > 3) {
      throw ArgumentError.value(count, 'count', 'Must be between 1 and 3.');
    }
    final firstMinute = earliestMinute.clamp(0, 24 * 60 - 1);
    final available = List<int>.generate(
      24 * 60 - firstMinute,
      (index) => firstMinute + index,
    )..shuffle(random);
    final selected = <int>[];
    for (final candidate in available) {
      if (selected.every(
        (value) => (value - candidate).abs() >= minimumPlayGapMinutes,
      )) {
        selected.add(candidate);
        if (selected.length == count) break;
      }
    }
    if (selected.length != count) {
      throw StateError('Could not create a valid cat play schedule.');
    }
    return selected..sort();
  }

  static String? currentPlayMomentKey(CatProfile profile, {DateTime? at}) {
    if (profile.stage != CatStage.adult || profile.playScheduleDay == null) {
      return null;
    }
    final now = (at ?? DateTime.now()).toLocal();
    final day = _dayString(now);
    if (profile.playScheduleDay != day) return null;
    for (final minute in profile.playMomentMinutes) {
      final start = DateTime(
        now.year,
        now.month,
        now.day,
        minute ~/ 60,
        minute % 60,
      );
      final key = '$day:$minute';
      if (!now.isBefore(start) &&
          now.isBefore(start.add(const Duration(minutes: 1))) &&
          !profile.playedMomentKeys.contains(key)) {
        return key;
      }
    }
    return null;
  }

  static double calculateHappyPoints({
    required DateTime scheduledAt,
    required DateTime recordedAt,
    required int alarmCount,
  }) {
    final count = alarmCount.clamp(1, 1 << 20);
    final maximum = 30 / count;
    final secondsLate = recordedAt
        .difference(scheduledAt)
        .inSeconds
        .clamp(0, 30 * 60);
    final score = maximum * (1 - secondsLate / (30 * 60));
    return (score * 10).round() / 10;
  }

  CatProfile _feed(CatProfile profile, String key, DateTime at) {
    final doseDay = _dayFromDoseKey(key) ?? _localDay(at);
    final alreadyRewardedOnDay = profile.rewardedDoseKeys.any(
      (rewardedKey) => _dayFromDoseKey(rewardedKey) == doseDay,
    );
    final rewarded = {...profile.rewardedDoseKeys, key};
    final missed = {...profile.missedDoseKeys};
    final recovery = {...profile.recoveryDoseKeys};
    final resolved = {...profile.resolvedMissDoseKeys};
    var hunger = profile.hungerPoints;

    if (missed.remove(key)) {
      if (hunger > 0) hunger--;
      resolved.add(key);
    } else if (hunger > 0) {
      hunger--;
      recovery.add(key);
    }
    return profile.copyWith(
      feedCount: profile.feedCount + (alreadyRewardedOnDay ? 0 : 1),
      hungerPoints: hunger,
      rewardedDoseKeys: rewarded,
      missedDoseKeys: missed,
      recoveryDoseKeys: recovery,
      resolvedMissDoseKeys: resolved,
      lastFedAt: at,
    );
  }

  CatProfile _markMissed(CatProfile profile, String key) {
    if (profile.missedDoseKeys.contains(key) ||
        profile.rewardedDoseKeys.contains(key)) {
      return profile;
    }
    return profile.copyWith(
      missedDoseKeys: {...profile.missedDoseKeys, key},
      hungerPoints: (profile.hungerPoints + 1).clamp(0, 5),
    );
  }

  String? _dayFromDoseKey(String key) {
    final parts = key.split(':');
    if (parts.length < 3 || DateTime.tryParse(parts[1]) == null) return null;
    return parts[1];
  }

  DateTime? _scheduledAtFromDoseKey(String key) {
    return scheduledAtFromDoseKey(key);
  }

  String _localDay(DateTime value) {
    return _dayString(value.toLocal());
  }

  static String _dayString(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }

  Future<void> _save(CatProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await _requireStored(
      prefs.setString(_catKey, jsonEncode(profile.toJson())),
      _catKey,
    );
    await _saveEntitlements(prefs, profile);
  }

  Future<void> _saveEntitlements(
    SharedPreferences prefs,
    CatProfile profile,
  ) async {
    final current = _CatEntitlements.fromPreferences(prefs);
    final entitlements = _CatEntitlements(
      ownedAccessoryIds: <String>{
        ...current.ownedAccessoryIds,
        ...profile.ownedAccessoryIds,
      },
      supporterRewardClaimed:
          current.supporterRewardClaimed || profile.supporterRewardClaimed,
      processedSupportTransactions: <String>{
        ...current.processedSupportTransactions,
        ...profile.processedSupportTransactions,
      },
      processedCodeRedemptions: <String>{
        ...current.processedCodeRedemptions,
        ...profile.processedCodeRedemptions,
      },
      adultCatEverRaised:
          current.adultCatEverRaised ||
          (profile.species == PetSpecies.cat &&
              profile.stage == CatStage.adult),
    );
    await _requireStored(
      prefs.setString(_entitlementsKey, jsonEncode(entitlements.toJson())),
      _entitlementsKey,
    );
  }

  Future<void> _requireStored(Future<bool> result, String key) async {
    if (!await result) {
      throw StateError('Could not persist local data for $key.');
    }
  }
}

class _CatEntitlements {
  const _CatEntitlements({
    this.ownedAccessoryIds = const <String>{},
    this.supporterRewardClaimed = false,
    this.processedSupportTransactions = const <String>{},
    this.processedCodeRedemptions = const <String>{},
    this.adultCatEverRaised = false,
  });

  final Set<String> ownedAccessoryIds;
  final bool supporterRewardClaimed;
  final Set<String> processedSupportTransactions;
  final Set<String> processedCodeRedemptions;
  final bool adultCatEverRaised;

  factory _CatEntitlements.fromPreferences(SharedPreferences prefs) {
    final source = prefs.getString(CatRepository._entitlementsKey);
    if (source == null || source.isEmpty) return const _CatEntitlements();
    try {
      final json = Map<String, Object?>.from(
        jsonDecode(source) as Map<dynamic, dynamic>,
      );
      Set<String> stringSet(String key) =>
          (json[key] as List<dynamic>? ?? const <dynamic>[])
              .whereType<String>()
              .toSet();
      return _CatEntitlements(
        ownedAccessoryIds: stringSet('ownedAccessoryIds'),
        supporterRewardClaimed:
            json['supporterRewardClaimed'] as bool? ?? false,
        processedSupportTransactions: stringSet('processedSupportTransactions'),
        processedCodeRedemptions: stringSet('processedCodeRedemptions'),
        adultCatEverRaised: json['adultCatEverRaised'] as bool? ?? false,
      );
    } on FormatException {
      rethrow;
    } on Object catch (error) {
      throw FormatException(
        'Stored pet entitlements could not be decoded.',
        error,
      );
    }
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'ownedAccessoryIds': ownedAccessoryIds.toList()..sort(),
    'supporterRewardClaimed': supporterRewardClaimed,
    'processedSupportTransactions': processedSupportTransactions.toList()
      ..sort(),
    'processedCodeRedemptions': processedCodeRedemptions.toList()..sort(),
    'adultCatEverRaised': adultCatEverRaised,
  };
}

class CatSupportResult {
  const CatSupportResult({
    required this.profile,
    this.firstRewardGranted = false,
    this.duplicateTransaction = false,
  });

  final CatProfile profile;
  final bool firstRewardGranted;
  final bool duplicateTransaction;
}

class CatPlayResult {
  const CatPlayResult({required this.profile, this.rewarded = false});

  final CatProfile profile;
  final bool rewarded;
}

class CatCodeRewardResult {
  const CatCodeRewardResult({
    required this.profile,
    this.grantedItemIds = const <String>{},
    this.duplicate = false,
  });

  final CatProfile profile;
  final Set<String> grantedItemIds;
  final bool duplicate;
}
