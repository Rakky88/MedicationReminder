enum PetSpecies { cat, dog, chicken }

enum PetVariant {
  catOrange,
  catTuxedo,
  catGray,
  catCalico,
  catBlackBib,
  dogGolden,
  dogBeagle,
  dogBlackLab,
  dogBorderCollie,
  dogDachshund,
  chickenHen,
}

extension PetVariantDetails on PetVariant {
  PetSpecies get species => switch (this) {
    PetVariant.catOrange ||
    PetVariant.catTuxedo ||
    PetVariant.catGray ||
    PetVariant.catCalico ||
    PetVariant.catBlackBib => PetSpecies.cat,
    PetVariant.dogGolden ||
    PetVariant.dogBeagle ||
    PetVariant.dogBlackLab ||
    PetVariant.dogBorderCollie ||
    PetVariant.dogDachshund => PetSpecies.dog,
    PetVariant.chickenHen => PetSpecies.chicken,
  };

  String get assetPrefix => switch (this) {
    PetVariant.catOrange => 'cat_orange',
    PetVariant.catTuxedo => 'cat_tuxedo',
    PetVariant.catGray => 'cat_gray',
    PetVariant.catCalico => 'cat_calico',
    PetVariant.catBlackBib => 'cat_black_bib',
    PetVariant.dogGolden => 'dog_golden',
    PetVariant.dogBeagle => 'dog_beagle',
    PetVariant.dogBlackLab => 'dog_black_lab',
    PetVariant.dogBorderCollie => 'dog_border_collie',
    PetVariant.dogDachshund => 'dog_dachshund',
    PetVariant.chickenHen => 'chicken_hen',
  };
}

List<PetVariant> petVariantsForSpecies(PetSpecies species) => PetVariant.values
    .where((variant) => variant.species == species)
    .toList(growable: false);

enum CatStage { kitten, young, adult }

enum CatHungerLevel { full, peckish, hungry, veryHungry }

enum CatAccessoryCategory { hat, glasses, neckwear, outfit, toy }

class CatProfile {
  static const maxStoredTimelineEntries = 1000;

  const CatProfile({
    required this.name,
    required this.variant,
    required this.adoptedAt,
    this.feedCount = 0,
    this.hungerPoints = 0,
    this.hungerModelVersion = 2,
    this.rewardedDoseKeys = const <String>{},
    this.missedDoseKeys = const <String>{},
    this.recoveryDoseKeys = const <String>{},
    this.resolvedMissDoseKeys = const <String>{},
    this.purrEnabled = true,
    this.meowEnabled = true,
    this.persistentMeowEnabled = true,
    this.dragonMode = false,
    this.lastFedAt,
    this.happyPoints = 0,
    this.happyPointAwards = const <String, double>{},
    this.ownedAccessoryIds = const <String>{},
    this.equippedAccessories = const <String, String>{},
    this.supporterRewardClaimed = false,
    this.processedSupportTransactions = const <String>{},
    this.playScheduleDay,
    this.playMomentMinutes = const <int>[],
    this.playedMomentKeys = const <String>{},
    this.processedCodeRedemptions = const <String>{},
  });

  final String name;
  final PetVariant variant;
  PetSpecies get species => variant.species;
  final DateTime adoptedAt;
  final int feedCount;
  final int hungerPoints;
  final int hungerModelVersion;
  final Set<String> rewardedDoseKeys;
  final Set<String> missedDoseKeys;
  final Set<String> recoveryDoseKeys;
  final Set<String> resolvedMissDoseKeys;
  // These persisted names predate dogs and chickens. Keep them for update
  // compatibility, while the species-neutral getters are used by new code.
  final bool purrEnabled;
  final bool meowEnabled;
  bool get happySoundEnabled => purrEnabled;
  bool get hungrySoundEnabled => meowEnabled;
  final bool persistentMeowEnabled;
  final bool dragonMode;
  final DateTime? lastFedAt;
  final double happyPoints;
  final Map<String, double> happyPointAwards;
  final Set<String> ownedAccessoryIds;
  final Map<String, String> equippedAccessories;
  final bool supporterRewardClaimed;
  final Set<String> processedSupportTransactions;
  final String? playScheduleDay;
  final List<int> playMomentMinutes;
  final Set<String> playedMomentKeys;
  final Set<String> processedCodeRedemptions;

  CatStage get stage {
    if (feedCount < 14) return CatStage.kitten;
    if (feedCount < 60) return CatStage.young;
    return CatStage.adult;
  }

  CatHungerLevel get hungerLevel {
    if (hungerPoints <= 0) return CatHungerLevel.full;
    if (hungerPoints <= 2) return CatHungerLevel.peckish;
    if (hungerPoints <= 4) return CatHungerLevel.hungry;
    return CatHungerLevel.veryHungry;
  }

  String get assetPath =>
      'assets/cats/${variant.assetPrefix}_${stage.name}.png';

  String? equippedId(CatAccessoryCategory category) =>
      equippedAccessories[category.name];

  double get growthProgress {
    switch (stage) {
      case CatStage.kitten:
        return feedCount / 14;
      case CatStage.young:
        return (feedCount - 14) / 46;
      case CatStage.adult:
        return 1;
    }
  }

  CatProfile copyWith({
    String? name,
    PetVariant? variant,
    DateTime? adoptedAt,
    int? feedCount,
    int? hungerPoints,
    int? hungerModelVersion,
    Set<String>? rewardedDoseKeys,
    Set<String>? missedDoseKeys,
    Set<String>? recoveryDoseKeys,
    Set<String>? resolvedMissDoseKeys,
    bool? purrEnabled,
    bool? meowEnabled,
    bool? persistentMeowEnabled,
    bool? dragonMode,
    DateTime? lastFedAt,
    double? happyPoints,
    Map<String, double>? happyPointAwards,
    Set<String>? ownedAccessoryIds,
    Map<String, String>? equippedAccessories,
    bool? supporterRewardClaimed,
    Set<String>? processedSupportTransactions,
    String? playScheduleDay,
    List<int>? playMomentMinutes,
    Set<String>? playedMomentKeys,
    Set<String>? processedCodeRedemptions,
  }) {
    return CatProfile(
      name: name ?? this.name,
      variant: variant ?? this.variant,
      adoptedAt: adoptedAt ?? this.adoptedAt,
      feedCount: feedCount ?? this.feedCount,
      hungerPoints: hungerPoints ?? this.hungerPoints,
      hungerModelVersion: hungerModelVersion ?? this.hungerModelVersion,
      rewardedDoseKeys: rewardedDoseKeys ?? this.rewardedDoseKeys,
      missedDoseKeys: missedDoseKeys ?? this.missedDoseKeys,
      recoveryDoseKeys: recoveryDoseKeys ?? this.recoveryDoseKeys,
      resolvedMissDoseKeys: resolvedMissDoseKeys ?? this.resolvedMissDoseKeys,
      purrEnabled: purrEnabled ?? this.purrEnabled,
      meowEnabled: meowEnabled ?? this.meowEnabled,
      persistentMeowEnabled:
          persistentMeowEnabled ?? this.persistentMeowEnabled,
      dragonMode: dragonMode ?? this.dragonMode,
      lastFedAt: lastFedAt ?? this.lastFedAt,
      happyPoints: happyPoints ?? this.happyPoints,
      happyPointAwards: happyPointAwards ?? this.happyPointAwards,
      ownedAccessoryIds: ownedAccessoryIds ?? this.ownedAccessoryIds,
      equippedAccessories: equippedAccessories ?? this.equippedAccessories,
      supporterRewardClaimed:
          supporterRewardClaimed ?? this.supporterRewardClaimed,
      processedSupportTransactions:
          processedSupportTransactions ?? this.processedSupportTransactions,
      playScheduleDay: playScheduleDay ?? this.playScheduleDay,
      playMomentMinutes: playMomentMinutes ?? this.playMomentMinutes,
      playedMomentKeys: playedMomentKeys ?? this.playedMomentKeys,
      processedCodeRedemptions:
          processedCodeRedemptions ?? this.processedCodeRedemptions,
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'growthModelVersion': 2,
    'name': name,
    'variant': variant.name,
    'adoptedAt': adoptedAt.toUtc().toIso8601String(),
    'feedCount': feedCount,
    'hungerPoints': hungerPoints,
    'hungerModelVersion': hungerModelVersion,
    'rewardedDoseKeys': _boundedTimelineSet(rewardedDoseKeys).toList(),
    'missedDoseKeys': _boundedTimelineSet(missedDoseKeys).toList(),
    'recoveryDoseKeys': _boundedTimelineSet(recoveryDoseKeys).toList(),
    'resolvedMissDoseKeys': _boundedTimelineSet(resolvedMissDoseKeys).toList(),
    'purrEnabled': purrEnabled,
    'meowEnabled': meowEnabled,
    'persistentMeowEnabled': persistentMeowEnabled,
    'dragonMode': dragonMode,
    'lastFedAt': lastFedAt?.toUtc().toIso8601String(),
    'happyPoints': happyPoints,
    'happyPointAwards': _boundedTimelineMap(happyPointAwards),
    'ownedAccessoryIds': ownedAccessoryIds.toList(),
    'equippedAccessories': equippedAccessories,
    'supporterRewardClaimed': supporterRewardClaimed,
    'processedSupportTransactions': processedSupportTransactions.toList(),
    'playScheduleDay': playScheduleDay,
    'playMomentMinutes': playMomentMinutes,
    'playedMomentKeys': _boundedTimelineSet(playedMomentKeys).toList(),
    'processedCodeRedemptions': processedCodeRedemptions.toList(),
  };

  factory CatProfile.fromJson(Map<String, Object?> json) {
    final variantName = json['variant'] as String?;
    final rewardedDoseKeys = _stringSet(json['rewardedDoseKeys']);
    final storedFeedCount = (json['feedCount'] as num?)?.toInt() ?? 0;
    final rewardedDayCount = _rewardedDayCount(rewardedDoseKeys);
    final legacySoundEnabled = json['soundEnabled'] as bool? ?? true;
    return CatProfile(
      name: json['name'] as String? ?? 'Milo',
      variant: _variantFromStoredName(variantName),
      adoptedAt:
          DateTime.tryParse(json['adoptedAt'] as String? ?? '')?.toLocal() ??
          DateTime.now(),
      feedCount: json['growthModelVersion'] == 2
          ? storedFeedCount
          : (rewardedDoseKeys.isEmpty ? storedFeedCount : rewardedDayCount),
      hungerPoints: ((json['hungerPoints'] as num?)?.toInt() ?? 0).clamp(0, 5),
      hungerModelVersion: (json['hungerModelVersion'] as num?)?.toInt() ?? 1,
      rewardedDoseKeys: _boundedTimelineSet(rewardedDoseKeys),
      missedDoseKeys: _boundedTimelineSet(_stringSet(json['missedDoseKeys'])),
      recoveryDoseKeys: _boundedTimelineSet(
        _stringSet(json['recoveryDoseKeys']),
      ),
      resolvedMissDoseKeys: _boundedTimelineSet(
        _stringSet(json['resolvedMissDoseKeys']),
      ),
      purrEnabled: json['purrEnabled'] as bool? ?? legacySoundEnabled,
      meowEnabled: json['meowEnabled'] as bool? ?? legacySoundEnabled,
      persistentMeowEnabled: json['persistentMeowEnabled'] as bool? ?? true,
      dragonMode: json['dragonMode'] as bool? ?? false,
      lastFedAt: DateTime.tryParse(
        json['lastFedAt'] as String? ?? '',
      )?.toLocal(),
      happyPoints: ((json['happyPoints'] as num?)?.toDouble() ?? 0).clamp(
        0,
        double.infinity,
      ),
      happyPointAwards: _boundedTimelineMap(
        _doubleMap(json['happyPointAwards']),
      ),
      ownedAccessoryIds: _stringSet(json['ownedAccessoryIds']),
      equippedAccessories: _stringMap(json['equippedAccessories']),
      supporterRewardClaimed: json['supporterRewardClaimed'] as bool? ?? false,
      processedSupportTransactions: _stringSet(
        json['processedSupportTransactions'],
      ),
      playScheduleDay: json['playScheduleDay'] as String?,
      playMomentMinutes:
          (json['playMomentMinutes'] as List<dynamic>? ?? const <dynamic>[])
              .whereType<num>()
              .map((value) => value.toInt())
              .where((value) => value >= 0 && value < 24 * 60)
              .toSet()
              .toList()
            ..sort(),
      playedMomentKeys: _boundedTimelineSet(
        _stringSet(json['playedMomentKeys']),
      ),
      processedCodeRedemptions: _stringSet(json['processedCodeRedemptions']),
    );
  }

  static Set<String> _stringSet(Object? value) =>
      (value as List<dynamic>? ?? const <dynamic>[])
          .whereType<String>()
          .toSet();

  static PetVariant _variantFromStoredName(String? name) {
    // Older releases stored only the colour name. Keeping this explicit makes
    // the species migration safe for every existing adopted cat.
    const legacy = <String, PetVariant>{
      'orange': PetVariant.catOrange,
      'tuxedo': PetVariant.catTuxedo,
      'gray': PetVariant.catGray,
      'calico': PetVariant.catCalico,
    };
    return legacy[name] ??
        PetVariant.values.firstWhere(
          (value) => value.name == name,
          orElse: () => PetVariant.catOrange,
        );
  }

  static Map<String, double> _doubleMap(Object? value) =>
      (value as Map<dynamic, dynamic>? ?? const <dynamic, dynamic>{}).map(
        (key, amount) =>
            MapEntry(key.toString(), amount is num ? amount.toDouble() : 0),
      );

  static Map<String, String> _stringMap(Object? value) =>
      (value as Map<dynamic, dynamic>? ?? const <dynamic, dynamic>{}).map(
        (key, item) => MapEntry(key.toString(), item.toString()),
      );

  static Set<String> _boundedTimelineSet(Set<String> values) {
    if (values.length <= maxStoredTimelineEntries) return values;
    final sorted = values.toList()..sort(_newestTimelineKeyFirst);
    return sorted.take(maxStoredTimelineEntries).toSet();
  }

  static Map<String, double> _boundedTimelineMap(Map<String, double> values) {
    if (values.length <= maxStoredTimelineEntries) return values;
    final sortedKeys = values.keys.toList()..sort(_newestTimelineKeyFirst);
    return <String, double>{
      for (final key in sortedKeys.take(maxStoredTimelineEntries))
        key: values[key]!,
    };
  }

  static int _newestTimelineKeyFirst(String left, String right) {
    final timeComparison = _timelineTimestamp(
      right,
    ).compareTo(_timelineTimestamp(left));
    return timeComparison == 0 ? right.compareTo(left) : timeComparison;
  }

  static DateTime _timelineTimestamp(String key) {
    final parts = key.split(':');
    final dateIndex = parts.indexWhere(
      (part) => RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(part),
    );
    if (dateIndex == -1) return DateTime.fromMillisecondsSinceEpoch(0);
    final date = DateTime.tryParse(parts[dateIndex]);
    if (date == null) return DateTime.fromMillisecondsSinceEpoch(0);
    final firstNumber = dateIndex + 1 < parts.length
        ? int.tryParse(parts[dateIndex + 1])
        : null;
    final secondNumber = dateIndex + 2 < parts.length
        ? int.tryParse(parts[dateIndex + 2])
        : null;
    if (secondNumber != null) {
      return DateTime(
        date.year,
        date.month,
        date.day,
        firstNumber ?? 0,
        secondNumber,
      );
    }
    return date.add(Duration(minutes: firstNumber ?? 0));
  }

  static int _rewardedDayCount(Set<String> doseKeys) =>
      doseKeys.map(_dayFromDoseKey).whereType<String>().toSet().length;

  static String? _dayFromDoseKey(String key) {
    final parts = key.split(':');
    if (parts.length < 3 || DateTime.tryParse(parts[1]) == null) return null;
    return parts[1];
  }
}

class CatDoseResult {
  const CatDoseResult({
    required this.profile,
    this.fed = false,
    this.earnedHappyPoints = 0,
  });

  final CatProfile profile;
  final bool fed;
  final double earnedHappyPoints;
}
