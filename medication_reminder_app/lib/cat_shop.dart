import 'cat.dart';
import 'outfit_accessory_fits.dart';

class CatShopItem {
  const CatShopItem({
    required this.id,
    required this.category,
    required this.price,
    required this.assetPath,
    required this.nameEn,
    required this.nameNl,
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
  final bool codeExclusive;
  final bool requiresChickenUnlock;
  final int? requiredMedicationStreak;
  final bool adaptiveOverlay;
  final double overlayScale;
  final double overlayDx;
  final double overlayDy;

  bool get hiddenUntilOwned => codeExclusive;
  bool get isStreakReward => requiredMedicationStreak != null;

  String localizedName(String languageCode) => switch (languageCode) {
    'nl' => nameNl,
    'de' => _additionalShopNames[id]?[0] ?? nameEn,
    'fr' => _additionalShopNames[id]?[1] ?? nameEn,
    'es' => _additionalShopNames[id]?[2] ?? nameEn,
    _ => nameEn,
  };

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

  CatAccessoryTransform adaptiveTransform(
    PetVariant variant, {
    String? outfitId,
  }) {
    var scale = overlayScale;
    var dy = overlayDy;
    if (adaptiveOverlay &&
        (category == CatAccessoryCategory.hat ||
            category == CatAccessoryCategory.glasses)) {
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
    } else if (adaptiveOverlay && category == CatAccessoryCategory.outfit) {
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
    final base = CatAccessoryTransform(scale: scale, dx: overlayDx, dy: dy);
    if (adaptiveOverlay ||
        (category != CatAccessoryCategory.hat &&
            category != CatAccessoryCategory.glasses &&
            category != CatAccessoryCategory.neckwear)) {
      return base;
    }
    final outfitFit = outfitFaceFitFor(outfitId, variant);
    if (outfitFit == null) return base;

    // Fitted overlays were approved on the naked adult. Move and scale their
    // complete 512px canvas by the measured head transform of this outfit.
    // Because the neck landmark is part of the same registration, bow ties
    // follow the dressed collar instead of remaining at the naked-pet neck.
    final landmarks = petAccessoryLandmarks[variant.index];
    final targetScale = outfitFit.$3;
    final anchorX = category == CatAccessoryCategory.neckwear
        ? landmarks.$3
        : landmarks.$1;
    final anchorY = category == CatAccessoryCategory.neckwear
        ? landmarks.$4
        : landmarks.$2;
    final targetX = outfitFit.$1 + (anchorX - landmarks.$1) * targetScale;
    final targetY = outfitFit.$2 + (anchorY - landmarks.$2) * targetScale;
    var targetScaleX = targetScale;
    var targetScaleY = targetScale;
    if (category == CatAccessoryCategory.hat) {
      final baseTop = fittedHatTopInsetFor(id, variant);
      if (baseTop != null && baseTop < anchorY) {
        const safeTop = 2.0;
        final maximumScaleY = (targetY - safeTop) / (anchorY - baseTop);
        if (maximumScaleY < targetScaleY) targetScaleY = maximumScaleY;
      }
    }
    const canvasCenter = 256.0;
    const canvasSize = 512.0;
    final dx =
        (targetX - (canvasCenter + (anchorX - canvasCenter) * targetScaleX)) /
        canvasSize;
    final outfitDy =
        (targetY - (canvasCenter + (anchorY - canvasCenter) * targetScaleY)) /
        canvasSize;
    return CatAccessoryTransform(
      scale: 1,
      scaleX: targetScaleX,
      scaleY: targetScaleY,
      dx: dx,
      dy: outfitDy,
    );
  }
}

const Map<String, List<String>> _additionalShopNames = {
  'supporter_hat': [
    'Supporter-Krone',
    'Couronne de soutien',
    'Corona de apoyo',
  ],
  'streak_40_hat_consistency': [
    'Ausdauer-Kappe',
    'Casquette de régularité',
    'Gorra de constancia',
  ],
  'streak_100_glasses_century': [
    'Jahrhundertbrille',
    'Lunettes du centenaire',
    'Gafas del centenario',
  ],
  'streak_150_outfit_varsity': [
    'Fortschritts-Collegejacke',
    'Veste universitaire de progression',
    'Chaqueta universitaria de progreso',
  ],
  'streak_200_toy_rocket': [
    'Stabile Raketenplüschfigur',
    'Fusée en peluche stable',
    'Cohete de peluche estable',
  ],
  'streak_250_hat_laurel': [
    'Goldener Lorbeerkranz',
    'Lauriers dorés',
    'Laurel dorado',
  ],
  'streak_300_glasses_prism': [
    'Fokus-Prismenbrille',
    'Lunettes prisme de concentration',
    'Gafas prisma de enfoque',
  ],
  'streak_365_hat_year_crown': [
    'Krone des ersten Jahres',
    'Couronne de la première année',
    'Corona del primer año',
  ],
  'streak_365_glasses_year_star': [
    'Jubiläums-Sternbrille',
    'Lunettes étoiles anniversaire',
    'Gafas de estrellas de aniversario',
  ],
  'streak_365_outfit_year_champion': [
    'Championjacke des ersten Jahres',
    'Veste championne de la première année',
    'Chaqueta campeona del primer año',
  ],
  'streak_365_toy_year_cake': [
    'Kuchen des ersten Jahres',
    'Gâteau de la première année',
    'Tarta del primer año',
  ],
  'streak_500_outfit_legend': [
    'Legendenmantel',
    'Manteau de légende',
    'Abrigo de leyenda',
  ],
  'streak_750_toy_comet': [
    'Kometenplüschfigur',
    'Comète en peluche',
    'Cometa de peluche',
  ],
  'streak_1000_outfit_millennium': [
    'Millenniumsgewand',
    'Tenue du millénaire',
    'Atuendo del milenio',
  ],
  'hat_cap': ['Rote Kappe', 'Casquette rouge', 'Gorra roja'],
  'doctor_hat_fezz': ['Fezz', 'Fezz', 'Fezz'],
  'hat_wizard': ['Zaubererhut', 'Chapeau de sorcier', 'Sombrero de mago'],
  'hat_crown': ['Goldene Krone', 'Couronne dorée', 'Corona dorada'],
  'glasses_round': ['Runde Brille', 'Lunettes rondes', 'Gafas redondas'],
  'supporter_glasses': [
    'Supporter-Brille',
    'Lunettes de soutien',
    'Gafas de apoyo',
  ],
  'glasses_sun': ['Sonnenbrille', 'Lunettes de soleil', 'Gafas de sol'],
  'glasses_star': ['Sternbrille', 'Lunettes étoiles', 'Gafas de estrellas'],
  'doctor_bow_tie': ['Rote Fliege', 'Nœud papillon rouge', 'Pajarita roja'],
  'outfit_hoodie': [
    'Blauer Kapuzenpullover',
    'Sweat à capuche bleu',
    'Sudadera azul con capucha',
  ],
  'doctor_outfit': ['Tweed-Outfit', 'Tenue en tweed', 'Atuendo de tweed'],
  'supporter_outfit': ['Supporter-Umhang', 'Cape de soutien', 'Capa de apoyo'],
  'outfit_sweater': ['Grüner Pullover', 'Pull vert', 'Jersey verde'],
  'outfit_cape': ['Königlicher Umhang', 'Cape royale', 'Capa real'],
  'toy_yarn': ['Wollknäuel', 'Pelote de laine', 'Ovillo de lana'],
  'doctor_tardis_toy': ['Blaue Box', 'Boîte bleue', 'Caja azul'],
  'supporter_toy': ['Supporter-Herz', 'Cœur de soutien', 'Corazón de apoyo'],
  'toy_mouse': ['Spielzeugmaus', 'Souris en jouet', 'Ratón de juguete'],
  'toy_teddy': ['Teddybär', 'Ours en peluche', 'Osito de peluche'],
  'chicken_hat_straw': ['Strohhut', 'Chapeau de paille', 'Sombrero de paja'],
  'chicken_glasses_egg': ['Eierbrille', 'Lunettes œuf', 'Gafas de huevo'],
  'chicken_outfit_overalls': [
    'Farmer-Latzhose',
    'Salopette de ferme',
    'Peto de granja',
  ],
  'chicken_toy_corn': ['Mais-Spielzeug', 'Jouet maïs', 'Juguete de maíz'],
};

class CatAccessoryTransform {
  const CatAccessoryTransform({
    required this.scale,
    this.scaleX = 1,
    this.scaleY = 1,
    required this.dx,
    required this.dy,
  });

  final double scale;
  final double scaleX;
  final double scaleY;
  final double dx;
  final double dy;

  double get effectiveScaleX => scale * scaleX;
  double get effectiveScaleY => scale * scaleY;
}

const catShopCatalog = <CatShopItem>[
  CatShopItem(
    id: 'supporter_hat',
    category: CatAccessoryCategory.hat,
    price: 850,
    assetPath: 'assets/cats/fitted_accessories/cat_orange_supporter_hat.png',
    nameEn: 'Supporter crown',
    nameNl: 'Supporterskroon',
  ),
  CatShopItem(
    id: 'streak_40_hat_consistency',
    category: CatAccessoryCategory.hat,
    price: 0,
    assetPath:
        'assets/cats/fitted_accessories/cat_orange_streak_40_hat_consistency.png',
    nameEn: 'Consistency cap',
    nameNl: 'Doorzetterspet',
    requiredMedicationStreak: 40,
  ),
  CatShopItem(
    id: 'streak_100_glasses_century',
    category: CatAccessoryCategory.glasses,
    price: 0,
    assetPath:
        'assets/cats/fitted_accessories/cat_orange_streak_100_glasses_century.png',
    nameEn: 'Century glasses',
    nameNl: 'Eeuwbril',
    requiredMedicationStreak: 100,
  ),
  CatShopItem(
    id: 'streak_150_outfit_varsity',
    category: CatAccessoryCategory.outfit,
    price: 0,
    assetPath: 'assets/cats/fitted/cat_orange_streak_150_outfit_varsity.png',
    nameEn: 'Progress varsity jacket',
    nameNl: 'Voortgangsjack',
    requiredMedicationStreak: 150,
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
    assetPath:
        'assets/cats/fitted_accessories/cat_orange_streak_250_hat_laurel.png',
    nameEn: 'Golden laurel',
    nameNl: 'Gouden lauwerkrans',
    requiredMedicationStreak: 250,
  ),
  CatShopItem(
    id: 'streak_300_glasses_prism',
    category: CatAccessoryCategory.glasses,
    price: 0,
    assetPath:
        'assets/cats/fitted_accessories/cat_orange_streak_300_glasses_prism.png',
    nameEn: 'Focus prism glasses',
    nameNl: 'Focusprismabril',
    requiredMedicationStreak: 300,
  ),
  CatShopItem(
    id: 'streak_365_hat_year_crown',
    category: CatAccessoryCategory.hat,
    price: 0,
    assetPath:
        'assets/cats/fitted_accessories/cat_orange_streak_365_hat_year_crown.png',
    nameEn: 'First-year crown',
    nameNl: 'Eerstejaarskroon',
    requiredMedicationStreak: 365,
  ),
  CatShopItem(
    id: 'streak_365_glasses_year_star',
    category: CatAccessoryCategory.glasses,
    price: 0,
    assetPath:
        'assets/cats/fitted_accessories/cat_orange_streak_365_glasses_year_star.png',
    nameEn: 'Anniversary star glasses',
    nameNl: 'Jubileumsterrenbril',
    requiredMedicationStreak: 365,
  ),
  CatShopItem(
    id: 'streak_365_outfit_year_champion',
    category: CatAccessoryCategory.outfit,
    price: 0,
    assetPath:
        'assets/cats/fitted/cat_orange_streak_365_outfit_year_champion.png',
    nameEn: 'First-year champion jacket',
    nameNl: 'Eerstejaarskampioensjack',
    requiredMedicationStreak: 365,
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
    assetPath: 'assets/cats/fitted/cat_orange_streak_500_outfit_legend.png',
    nameEn: 'Legend coat',
    nameNl: 'Legendejas',
    requiredMedicationStreak: 500,
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
    assetPath:
        'assets/cats/fitted/cat_orange_streak_1000_outfit_millennium.png',
    nameEn: 'Millennium regalia',
    nameNl: 'Millenniumgewaad',
    requiredMedicationStreak: 1000,
  ),
  CatShopItem(
    id: 'hat_cap',
    category: CatAccessoryCategory.hat,
    price: 210,
    assetPath: 'assets/cats/fitted_accessories/cat_orange_hat_cap.png',
    nameEn: 'Red cap',
    nameNl: 'Rode pet',
  ),
  CatShopItem(
    id: 'doctor_hat_fezz',
    category: CatAccessoryCategory.hat,
    price: 0,
    assetPath: 'assets/cats/fitted_accessories/cat_orange_doctor_hat_fezz.png',
    nameEn: 'Fezz',
    nameNl: 'Fezz',
    codeExclusive: true,
  ),
  CatShopItem(
    id: 'hat_wizard',
    category: CatAccessoryCategory.hat,
    price: 420,
    assetPath: 'assets/cats/fitted_accessories/cat_orange_hat_wizard.png',
    nameEn: 'Wizard hat',
    nameNl: 'Tovenaarshoed',
  ),
  CatShopItem(
    id: 'hat_crown',
    category: CatAccessoryCategory.hat,
    price: 720,
    assetPath: 'assets/cats/fitted_accessories/cat_orange_hat_crown.png',
    nameEn: 'Golden crown',
    nameNl: 'Gouden kroon',
  ),
  CatShopItem(
    id: 'glasses_round',
    category: CatAccessoryCategory.glasses,
    price: 240,
    assetPath: 'assets/cats/fitted_accessories/cat_orange_glasses_round.png',
    nameEn: 'Round glasses',
    nameNl: 'Ronde bril',
  ),
  CatShopItem(
    id: 'supporter_glasses',
    category: CatAccessoryCategory.glasses,
    price: 650,
    assetPath:
        'assets/cats/fitted_accessories/cat_orange_supporter_glasses.png',
    nameEn: 'Supporter glasses',
    nameNl: 'Supportersbril',
  ),
  CatShopItem(
    id: 'glasses_sun',
    category: CatAccessoryCategory.glasses,
    price: 390,
    assetPath: 'assets/cats/fitted_accessories/cat_orange_glasses_sun.png',
    nameEn: 'Sunglasses',
    nameNl: 'Zonnebril',
  ),
  CatShopItem(
    id: 'glasses_star',
    category: CatAccessoryCategory.glasses,
    price: 600,
    assetPath: 'assets/cats/fitted_accessories/cat_orange_glasses_star.png',
    nameEn: 'Star glasses',
    nameNl: 'Sterrenbril',
  ),
  CatShopItem(
    id: 'doctor_bow_tie',
    category: CatAccessoryCategory.neckwear,
    price: 0,
    assetPath: 'assets/cats/fitted_accessories/cat_orange_doctor_bow_tie.png',
    nameEn: 'Red bowtie',
    nameNl: 'Rode strik',
    codeExclusive: true,
  ),
  CatShopItem(
    id: 'outfit_hoodie',
    category: CatAccessoryCategory.outfit,
    price: 300,
    assetPath: 'assets/cats/fitted/cat_orange_outfit_hoodie.png',
    nameEn: 'Blue hoodie',
    nameNl: 'Blauwe hoodie',
  ),
  CatShopItem(
    id: 'doctor_outfit',
    category: CatAccessoryCategory.outfit,
    price: 0,
    assetPath: 'assets/cats/fitted/cat_orange_doctor_outfit.png',
    nameEn: 'Tweed outfit',
    nameNl: 'Tweed-outfit',
    codeExclusive: true,
  ),
  CatShopItem(
    id: 'supporter_outfit',
    category: CatAccessoryCategory.outfit,
    price: 1100,
    assetPath: 'assets/cats/fitted/cat_orange_supporter_outfit.png',
    nameEn: 'Supporter cape',
    nameNl: 'Supporterscape',
  ),
  CatShopItem(
    id: 'outfit_sweater',
    category: CatAccessoryCategory.outfit,
    price: 480,
    assetPath: 'assets/cats/fitted/cat_orange_outfit_sweater.png',
    nameEn: 'Green sweater',
    nameNl: 'Groene trui',
  ),
  CatShopItem(
    id: 'outfit_cape',
    category: CatAccessoryCategory.outfit,
    price: 900,
    assetPath: 'assets/cats/fitted/cat_orange_outfit_cape.png',
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
    nameEn: 'Blue box',
    nameNl: 'Blauwe doos',
    codeExclusive: true,
  ),
  CatShopItem(
    id: 'supporter_toy',
    category: CatAccessoryCategory.toy,
    price: 700,
    assetPath: 'assets/cats/supporter_toy.png',
    nameEn: 'Supporter heart',
    nameNl: 'Supportershart',
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
    assetPath:
        'assets/cats/fitted_accessories/cat_orange_chicken_hat_straw.png',
    nameEn: 'Straw hat',
    nameNl: 'Strohoed',
    requiresChickenUnlock: true,
  ),
  CatShopItem(
    id: 'chicken_glasses_egg',
    category: CatAccessoryCategory.glasses,
    price: 420,
    assetPath:
        'assets/cats/fitted_accessories/cat_orange_chicken_glasses_egg.png',
    nameEn: 'Egg glasses',
    nameNl: 'Eierbril',
    requiresChickenUnlock: true,
  ),
  CatShopItem(
    id: 'chicken_outfit_overalls',
    category: CatAccessoryCategory.outfit,
    price: 650,
    assetPath: 'assets/cats/fitted/cat_orange_chicken_outfit_overalls.png',
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

String? tailoredOutfitId(CatProfile profile) {
  if (profile.stage != CatStage.adult) return null;
  final outfit = catShopItemById(
    profile.equippedId(CatAccessoryCategory.outfit),
  );
  return outfit == null || outfit.adaptiveOverlay ? null : outfit.id;
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
          item.isStreakReward ||
          (!item.requiresChickenUnlock || chickenUnlocked) &&
              !item.hiddenUntilOwned,
    )
    .toList();
