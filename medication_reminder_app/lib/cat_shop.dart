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

  bool get hiddenUntilOwned => supporterExclusive || codeExclusive;

  String localizedName(String languageCode) =>
      languageCode == 'nl' ? nameNl : nameEn;

  String fittedAssetPath(PetVariant variant) {
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
    assetPath: 'assets/cats/doctor_outfit.png',
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
  return outfit?.fittedAssetPath(profile.variant) ?? profile.assetPath;
}

List<CatShopItem> equippedPetOverlayItems(CatProfile profile) =>
    equippedCatShopItems(profile)
        .where((item) => item.category != CatAccessoryCategory.outfit)
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
