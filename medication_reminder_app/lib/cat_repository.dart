import 'dart:convert';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

import 'cat.dart';
import 'cat_shop.dart';
import 'medication.dart';

class CatRepository {
  CatRepository._();

  static final CatRepository instance = CatRepository._();
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
      final profile = CatProfile.fromJson(
        Map<String, Object?>.from(jsonDecode(source) as Map<dynamic, dynamic>),
      );
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
    } on Object {
      return null;
    }
  }

  Future<CatProfile> adopt({
    required String name,
    required PetVariant variant,
    bool purrEnabled = true,
    bool meowEnabled = true,
    bool persistentMeowEnabled = true,
  }) async {
    final prefs = await SharedPreferences.getInstance();
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
  }) async {
    final updated = profile.copyWith(
      name: name.trim().isEmpty ? profile.name : name.trim(),
      purrEnabled: purrEnabled,
      meowEnabled: meowEnabled,
      persistentMeowEnabled: persistentMeowEnabled,
    );
    await _save(updated);
    return updated;
  }

  Future<void> remove() async {
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
    await prefs.remove(_catKey);
  }

  Future<CatProfile?> reconcileDoseLogs(List<DoseLog> logs) async {
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

  Future<CatProfile?> undoDose(DoseLog log) async {
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
  }) async {
    final profile = await getProfile();
    if (profile == null ||
        supporterAccessoryIds.contains(itemId) ||
        profile.stage != CatStage.adult ||
        profile.ownedAccessoryIds.contains(itemId) ||
        profile.happyPoints < price) {
      return profile;
    }
    final updated = profile.copyWith(
      happyPoints: profile.happyPoints - price,
      ownedAccessoryIds: <String>{...profile.ownedAccessoryIds, itemId},
    );
    await _save(updated);
    return updated;
  }

  Future<CatSupportResult?> registerVerifiedSupport({
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
  }) async {
    final profile = await getProfile();
    if (profile == null ||
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

  Future<CatProfile?> ensurePlaySchedule({DateTime? at, Random? random}) async {
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
    final parts = key.split(':');
    if (parts.length < 4) return null;
    final date = DateTime.tryParse(parts[1]);
    final hour = int.tryParse(parts[2]);
    final minute = int.tryParse(parts[3]);
    if (date == null || hour == null || minute == null) return null;
    return DateTime(date.year, date.month, date.day, hour, minute);
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
    await prefs.setString(_catKey, jsonEncode(profile.toJson()));
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
    await prefs.setString(_entitlementsKey, jsonEncode(entitlements.toJson()));
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
    } on Object {
      return const _CatEntitlements();
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
