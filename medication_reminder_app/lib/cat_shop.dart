import 'cat.dart';

class CatShopItem {
  const CatShopItem({
    required this.id,
    required this.category,
    required this.price,
    required this.assetPath,
    required this.nameEn,
    required this.nameNl,
    this.supporterExclusive = false,
    this.codeExclusive = false,
    this.requiresChickenUnlock = false,
    this.requiredMedicationStreak,
    this.adaptiveOverlay = false,
    this.overlayScale = 1,
    this.overlayDx = 0,
    this.overlayDy = 0,
  });

  final String id;
  final CatAccessoryCategory category;
  final double price;
  final String assetPath;
  final String nameEn;
  final String nameNl;
  final bool supporterExclusive;
  final bool codeExclusive;
  final bool requiresChickenUnlock;
  final int? requiredMedicationStreak;
  final bool adaptiveOverlay;
  final double overlayScale;
  final double overlayDx;
  final double overlayDy;

  bool get hiddenUntilOwned => supporterExclusive || codeExclusive;
  bool get isStreakReward => requiredMedicationStreak != null;

  String localizedName(String languageCode) =>
      languageCode == 'nl' ? nameNl : nameEn;

  String fittedAssetPath(PetVariant variant) {
    if (adaptiveOverlay) return assetPath;
    return switch (category) {
      CatAccessoryCategory.outfit =>
        'assets/cats/fitted/${variant.assetPrefix}_$id.png',
      CatAccessoryCategory.hat ||
      CatAccessoryCategory.glasses ||
      CatAccessoryCategory.neckwear =>
        'assets/cats/fitted_accessories/${variant.assetPrefix}_$id.png',
      CatAccessoryCategory.toy => assetPath,
    };
  }

  CatAccessoryTransform adaptiveTransform(PetVariant variant) {
    var scale = overlayScale;
    var dy = overlayDy;
    if (category == CatAccessoryCategory.hat ||
        category == CatAccessoryCategory.glasses) {
      final isDog = variant.species == PetSpecies.dog;
      if (isDog) {
        scale *= category == CatAccessoryCategory.hat ? .82 : .76;
      }
      final landmarkFactor = category == CatAccessoryCategory.hat ? .68 : 1.0;
      dy += switch (variant) {
        PetVariant.dogGolden => -.082 * landmarkFactor,
        PetVariant.dogBeagle => -.070 * landmarkFactor,
        PetVariant.dogBlackLab => -.090 * landmarkFactor,
        PetVariant.dogBorderCollie => -.043 * landmarkFactor,
        PetVariant.dogDachshund => -.074 * landmarkFactor,
        _ => 0,
      };
    } else if (category == CatAccessoryCategory.outfit) {
      scale *= switch (variant) {
        PetVariant.catBlackBib => .90,
        PetVariant.dogGolden => .88,
        PetVariant.dogBeagle => .88,
        PetVariant.dogBlackLab => .84,
        PetVariant.dogBorderCollie => .82,
        PetVariant.dogDachshund => .76,
        PetVariant.chickenHen => .88,
        _ => 1,
      };
      dy += switch (variant) {
        PetVariant.dogGolden ||
        PetVariant.dogBeagle ||
        PetVariant.dogBlackLab ||
        PetVariant.dogBorderCollie ||
        PetVariant.dogDachshund => .025,
        PetVariant.chickenHen => .015,
        _ => 0,
      };
    }
    return CatAccessoryTransform(scale: scale, dx: overlayDx, dy: dy);
  }
}

class CatAccessoryTransform {
  const CatAccessoryTransform({
    required this.scale,
    required this.dx,
    required this.dy,
  });

  final double scale;
  final double dx;
  final double dy;
}

const catShopCatalog = <CatShopItem>[
  CatShopItem(
    id: 'supporter_hat',
    category: CatAccessoryCategory.hat,
    price: 0,
    assetPath: 'assets/cats/supporter_hat.png',
    nameEn: 'Supporter crown',
    nameNl: 'Supporterskroon',
    supporterExclusive: true,
  ),
  CatShopItem(
    id: 'streak_40_hat_consistency',
    category: CatAccessoryCategory.hat,
    price: 0,
    assetPath: 'assets/cats/streak_40_hat_consistency.png',
    nameEn: 'Consistency cap',
    nameNl: 'Doorzetterspet',
    requiredMedicationStreak: 40,
    adaptiveOverlay: true,
    overlayScale: .55,
    overlayDy: -.225,
  ),
  CatShopItem(
    id: 'streak_100_glasses_century',
    category: CatAccessoryCategory.glasses,
    price: 0,
    assetPath: 'assets/cats/streak_100_glasses_century.png',
    nameEn: 'Century glasses',
    nameNl: 'Eeuwbril',
    requiredMedicationStreak: 100,
    adaptiveOverlay: true,
    overlayScale: .37,
    overlayDx: .025,
    overlayDy: -.285,
  ),
  CatShopItem(
    id: 'streak_150_outfit_varsity',
    category: CatAccessoryCategory.outfit,
    price: 0,
    assetPath: 'assets/cats/streak_150_outfit_varsity.png',
    nameEn: 'Progress varsity jacket',
    nameNl: 'Voortgangsjack',
    requiredMedicationStreak: 150,
    adaptiveOverlay: true,
    overlayScale: .75,
    overlayDy: .09,
  ),
  CatShopItem(
    id: 'streak_200_toy_rocket',
    category: CatAccessoryCategory.toy,
    price: 0,
    assetPath: 'assets/cats/streak_200_toy_rocket.png',
    nameEn: 'Steady rocket plush',
    nameNl: 'Stabiele raketknuffel',
    requiredMedicationStreak: 200,
    adaptiveOverlay: true,
    overlayScale: .58,
    overlayDx: .155,
    overlayDy: .155,
  ),
  CatShopItem(
    id: 'streak_250_hat_laurel',
    category: CatAccessoryCategory.hat,
    price: 0,
    assetPath: 'assets/cats/streak_250_hat_laurel.png',
    nameEn: 'Golden laurel',
    nameNl: 'Gouden lauwerkrans',
    requiredMedicationStreak: 250,
    adaptiveOverlay: true,
    overlayScale: .63,
    overlayDy: -.215,
  ),
  CatShopItem(
    id: 'streak_300_glasses_prism',
    category: CatAccessoryCategory.glasses,
    price: 0,
    assetPath: 'assets/cats/streak_300_glasses_prism.png',
    nameEn: 'Focus prism glasses',
    nameNl: 'Focusprismabril',
    requiredMedicationStreak: 300,
    adaptiveOverlay: true,
    overlayScale: .41,
    overlayDx: .025,
    overlayDy: -.255,
  ),
  CatShopItem(
    id: 'streak_365_hat_year_crown',
    category: CatAccessoryCategory.hat,
    price: 0,
    assetPath: 'assets/cats/streak_365_hat_year_crown.png',
    nameEn: 'First-year crown',
    nameNl: 'Eerstejaarskroon',
    requiredMedicationStreak: 365,
    adaptiveOverlay: true,
    overlayScale: .48,
    overlayDy: -.26,
  ),
  CatShopItem(
    id: 'streak_365_glasses_year_star',
    category: CatAccessoryCategory.glasses,
    price: 0,
    assetPath: 'assets/cats/streak_365_glasses_year_star.png',
    nameEn: 'Anniversary star glasses',
    nameNl: 'Jubileumsterrenbril',
    requiredMedicationStreak: 365,
    adaptiveOverlay: true,
    overlayScale: .42,
    overlayDy: -.265,
  ),
  CatShopItem(
    id: 'streak_365_outfit_year_champion',
    category: CatAccessoryCategory.outfit,
    price: 0,
    assetPath: 'assets/cats/streak_365_outfit_year_champion.png',
    nameEn: 'First-year champion jacket',
    nameNl: 'Eerstejaarskampioensjack',
    requiredMedicationStreak: 365,
    adaptiveOverlay: true,
    overlayScale: .75,
    overlayDy: .09,
  ),
  CatShopItem(
    id: 'streak_365_toy_year_cake',
    category: CatAccessoryCategory.toy,
    price: 0,
    assetPath: 'assets/cats/streak_365_toy_year_cake.png',
    nameEn: 'First-year cake',
    nameNl: 'Eerstejaarstaart',
    requiredMedicationStreak: 365,
    adaptiveOverlay: true,
    overlayScale: .55,
    overlayDx: .155,
    overlayDy: .155,
  ),
  CatShopItem(
    id: 'streak_500_outfit_legend',
    category: CatAccessoryCategory.outfit,
    price: 0,
    assetPath: 'assets/cats/streak_500_outfit_legend.png',
    nameEn: 'Legend coat',
    nameNl: 'Legendejas',
    requiredMedicationStreak: 500,
    adaptiveOverlay: true,
    overlayScale: .72,
    overlayDy: .10,
  ),
  CatShopItem(
    id: 'streak_750_toy_comet',
    category: CatAccessoryCategory.toy,
    price: 0,
    assetPath: 'assets/cats/streak_750_toy_comet.png',
    nameEn: 'Comet plush',
    nameNl: 'Komeetknuffel',
    requiredMedicationStreak: 750,
    adaptiveOverlay: true,
    overlayScale: .50,
    overlayDx: .205,
    overlayDy: .175,
  ),
  CatShopItem(
    id: 'streak_1000_outfit_millennium',
    category: CatAccessoryCategory.outfit,
    price: 0,
    assetPath: 'assets/cats/streak_1000_outfit_millennium.png',
    nameEn: 'Millennium regalia',
    nameNl: 'Millenniumgewaad',
    requiredMedicationStreak: 1000,
    adaptiveOverlay: true,
    overlayScale: .82,
    overlayDy: .055,
  ),
  CatShopItem(
    id: 'hat_cap',
    category: CatAccessoryCategory.hat,
    price: 210,
    assetPath: 'assets/cats/shop_hat_cap.png',
    nameEn: 'Red cap',
    nameNl: 'Rode pet',
  ),
  CatShopItem(
    id: 'doctor_hat_fezz',
    category: CatAccessoryCategory.hat,
    price: 0,
    assetPath: 'assets/cats/doctor_hat_fezz.png',
    nameEn: 'Eleventh Doctor fez',
    nameNl: 'Fez van de Elfde Doctor',
    codeExclusive: true,
  ),
  CatShopItem(
    id: 'hat_wizard',
    category: CatAccessoryCategory.hat,
    price: 420,
    assetPath: 'assets/cats/shop_hat_wizard.png',
    nameEn: 'Wizard hat',
    nameNl: 'Tovenaarshoed',
  ),
  CatShopItem(
    id: 'hat_crown',
    category: CatAccessoryCategory.hat,
    price: 720,
    assetPath: 'assets/cats/shop_hat_crown.png',
    nameEn: 'Golden crown',
    nameNl: 'Gouden kroon',
  ),
  CatShopItem(
    id: 'glasses_round',
    category: CatAccessoryCategory.glasses,
    price: 240,
    assetPath: 'assets/cats/shop_glasses_round.png',
    nameEn: 'Round glasses',
    nameNl: 'Ronde bril',
  ),
  CatShopItem(
    id: 'supporter_glasses',
    category: CatAccessoryCategory.glasses,
    price: 0,
    assetPath: 'assets/cats/supporter_glasses.png',
    nameEn: 'Supporter glasses',
    nameNl: 'Supportersbril',
    supporterExclusive: true,
  ),
  CatShopItem(
    id: 'glasses_sun',
    category: CatAccessoryCategory.glasses,
    price: 390,
    assetPath: 'assets/cats/shop_glasses_sun.png',
    nameEn: 'Sunglasses',
    nameNl: 'Zonnebril',
  ),
  CatShopItem(
    id: 'glasses_star',
    category: CatAccessoryCategory.glasses,
    price: 600,
    assetPath: 'assets/cats/shop_glasses_star.png',
    nameEn: 'Star glasses',
    nameNl: 'Sterrenbril',
  ),
  CatShopItem(
    id: 'doctor_bow_tie',
    category: CatAccessoryCategory.neckwear,
    price: 0,
    assetPath: 'assets/cats/doctor_bow_tie.png',
    nameEn: 'Eleventh Doctor bow tie',
    nameNl: 'Strikje van de Elfde Doctor',
    codeExclusive: true,
  ),
  CatShopItem(
    id: 'outfit_hoodie',
    category: CatAccessoryCategory.outfit,
    price: 300,
    assetPath: 'assets/cats/shop_outfit_hoodie.png',
    nameEn: 'Blue hoodie',
    nameNl: 'Blauwe hoodie',
  ),
  CatShopItem(
    id: 'doctor_outfit',
    category: CatAccessoryCategory.outfit,
    price: 0,
    assetPath: 'assets/cats/fitted/cat_orange_doctor_outfit.png',
    nameEn: 'Eleventh Doctor outfit',
    nameNl: 'Outfit van de Elfde Doctor',
    codeExclusive: true,
  ),
  CatShopItem(
    id: 'supporter_outfit',
    category: CatAccessoryCategory.outfit,
    price: 0,
    assetPath: 'assets/cats/supporter_outfit.png',
    nameEn: 'Supporter cape',
    nameNl: 'Supporterscape',
    supporterExclusive: true,
  ),
  CatShopItem(
    id: 'outfit_sweater',
    category: CatAccessoryCategory.outfit,
    price: 480,
    assetPath: 'assets/cats/shop_outfit_sweater.png',
    nameEn: 'Green sweater',
    nameNl: 'Groene trui',
  ),
  CatShopItem(
    id: 'outfit_cape',
    category: CatAccessoryCategory.outfit,
    price: 900,
    assetPath: 'assets/cats/shop_outfit_cape.png',
    nameEn: 'Royal cape',
    nameNl: 'Koninklijke cape',
  ),
  CatShopItem(
    id: 'toy_yarn',
    category: CatAccessoryCategory.toy,
    price: 210,
    assetPath: 'assets/cats/shop_toy_yarn.png',
    nameEn: 'Yarn ball',
    nameNl: 'Bolletje wol',
  ),
  CatShopItem(
    id: 'doctor_tardis_toy',
    category: CatAccessoryCategory.toy,
    price: 0,
    assetPath: 'assets/cats/doctor_tardis_toy.png',
    nameEn: 'TARDIS toy',
    nameNl: 'TARDIS-speeltje',
    codeExclusive: true,
  ),
  CatShopItem(
    id: 'supporter_toy',
    category: CatAccessoryCategory.toy,
    price: 0,
    assetPath: 'assets/cats/supporter_toy.png',
    nameEn: 'Supporter heart',
    nameNl: 'Supportershart',
    supporterExclusive: true,
  ),
  CatShopItem(
    id: 'toy_mouse',
    category: CatAccessoryCategory.toy,
    price: 330,
    assetPath: 'assets/cats/shop_toy_mouse.png',
    nameEn: 'Toy mouse',
    nameNl: 'Speelmuis',
  ),
  CatShopItem(
    id: 'toy_teddy',
    category: CatAccessoryCategory.toy,
    price: 540,
    assetPath: 'assets/cats/shop_toy_teddy.png',
    nameEn: 'Teddy bear',
    nameNl: 'Teddybeer',
  ),
  CatShopItem(
    id: 'chicken_hat_straw',
    category: CatAccessoryCategory.hat,
    price: 360,
    assetPath: 'assets/cats/chicken_hat_straw.png',
    nameEn: 'Straw hat',
    nameNl: 'Strohoed',
    requiresChickenUnlock: true,
  ),
  CatShopItem(
    id: 'chicken_glasses_egg',
    category: CatAccessoryCategory.glasses,
    price: 420,
    assetPath: 'assets/cats/chicken_glasses_egg.png',
    nameEn: 'Egg glasses',
    nameNl: 'Eierbril',
    requiresChickenUnlock: true,
  ),
  CatShopItem(
    id: 'chicken_outfit_overalls',
    category: CatAccessoryCategory.outfit,
    price: 650,
    assetPath: 'assets/cats/chicken_outfit_overalls.png',
    nameEn: 'Farm overalls',
    nameNl: 'Boerderijtuinbroek',
    requiresChickenUnlock: true,
  ),
  CatShopItem(
    id: 'chicken_toy_corn',
    category: CatAccessoryCategory.toy,
    price: 300,
    assetPath: 'assets/cats/chicken_toy_corn.png',
    nameEn: 'Corn toy',
    nameNl: 'Maïsspeeltje',
    requiresChickenUnlock: true,
  ),
];

const supporterAccessoryIds = <String>{
  'supporter_hat',
  'supporter_glasses',
  'supporter_outfit',
  'supporter_toy',
};

CatShopItem? catShopItemById(String? id) {
  if (id == null) return null;
  for (final item in catShopCatalog) {
    if (item.id == id) return item;
  }
  return null;
}

List<CatShopItem> equippedCatShopItems(CatProfile profile) =>
    profile.stage != CatStage.adult
    ? const <CatShopItem>[]
    : const <CatAccessoryCategory>[
            CatAccessoryCategory.outfit,
            CatAccessoryCategory.hat,
            CatAccessoryCategory.glasses,
            CatAccessoryCategory.neckwear,
            CatAccessoryCategory.toy,
          ]
          .map((category) => catShopItemById(profile.equippedId(category)))
          .whereType<CatShopItem>()
          .toList();

String petBodyAssetPath(CatProfile profile) {
  if (profile.stage != CatStage.adult) return profile.assetPath;
  final outfit = catShopItemById(
    profile.equippedId(CatAccessoryCategory.outfit),
  );
  if (outfit == null || outfit.adaptiveOverlay) return profile.assetPath;
  return outfit.fittedAssetPath(profile.variant);
}

List<CatShopItem> equippedPetOverlayItems(CatProfile profile) =>
    equippedCatShopItems(profile)
        .where(
          (item) =>
              item.category != CatAccessoryCategory.outfit ||
              item.adaptiveOverlay,
        )
        .toList(growable: false);

List<CatShopItem> visibleCatShopCatalog(
  CatProfile _, {
  bool chickenUnlocked = false,
}) => catShopCatalog
    .where(
      (item) =>
          (!item.requiresChickenUnlock || chickenUnlocked) &&
          !item.hiddenUntilOwned,
    )
    .toList();
