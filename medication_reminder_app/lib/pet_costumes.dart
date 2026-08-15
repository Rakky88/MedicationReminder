import 'cat.dart';

String dragonModeFittedAssetPath(PetVariant variant) =>
    'assets/cats/fitted/${variant.assetPrefix}_dragon_mode_young.png';

bool showsDragonModeCostume(CatProfile profile) =>
    profile.stage == CatStage.young && profile.dragonMode;
