import 'cat.dart';

/// Measured registration of a dressed pet's face against its naked adult.
///
/// Values are expressed in the shared 512 x 512 sprite canvas. The order of
/// every list is deliberately identical to [PetVariant.values].
typedef OutfitFaceFit = (double faceX, double faceY, double scale);

typedef PetAccessoryLandmarks = (
  double faceX,
  double faceY,
  double neckX,
  double neckY,
);

const petAccessoryLandmarks = <PetAccessoryLandmarks>[
  (248, 158, 245, 214), // orange cat
  (249, 158, 246, 222), // tuxedo cat
  (247, 158, 245, 222), // gray cat
  (247, 158, 244, 214), // calico cat
  (246, 158, 246, 220), // black-bib cat
  (271, 106, 271, 174), // golden retriever
  (260, 116, 260, 212), // beagle
  (260, 110, 260, 170), // black labrador
  (270, 126, 270, 194), // border collie
  (262, 114, 262, 222), // dachshund
  (256, 150, 256, 220), // hen
];

/// First visible row of each fitted hat on each naked-pet canvas.
///
/// This lets a tall hat become slightly shallower only when a dressed head is
/// so high that the artwork would otherwise touch the top of the 512px sprite.
const fittedHatTopInsets = <String, List<double>>{
  'hat_cap': [12, 12, 12, 12, 12, 8, 14, 6, 28, 21, 28],
  'hat_wizard': [5, 5, 5, 5, 5, 1, 5, 2, 25, 5, 11],
  'hat_crown': [14, 14, 14, 14, 14, 6, 8, 2, 30, 12, 18],
  'supporter_hat': [25, 14, 14, 14, 14, 6, 13, 2, 22, 21, 33],
  'chicken_hat_straw': [32, 32, 32, 32, 32, 11, 17, 9, 31, 23, 33],
  'doctor_hat_fezz': [10, 10, 10, 10, 10, 3, 9, 1, 42, 21, 13],
  'streak_40_hat_consistency': [12, 12, 12, 12, 12, 12, 15, 9, 19, 11, 31],
  'streak_250_hat_laurel': [39, 39, 39, 39, 39, 26, 32, 24, 46, 39, 48],
  'streak_365_hat_year_crown': [21, 21, 21, 21, 21, 15, 11, 7, 35, 12, 24],
};

double? fittedHatTopInsetFor(String itemId, PetVariant variant) {
  final values = fittedHatTopInsets[itemId];
  if (values == null || values.length != PetVariant.values.length) return null;
  return values[variant.index];
}

/// Face registrations for every tailored outfit and every adult pet.
///
/// These measurements are intentionally independent of review selections.
/// Each dressed face was registered to the approved naked-pet landmark and
/// then checked on an annotated contact sheet. Accessories can therefore keep
/// their naked-pet fit while following the head movement in the outfit sprite.
const outfitFaceFits = <String, List<OutfitFaceFit>>{
  'outfit_hoodie': [
    (249, 137, .955),
    (250, 134, .940),
    (250, 140, .940),
    (249, 145, .940),
    (242, 156, .985),
    (272, 103, 1.000),
    (256, 113, .970),
    (258, 107, .985),
    (270, 126, 1.015),
    (250, 113, 1.000),
    (253, 151, 1.015),
  ],
  'outfit_cape': [
    (234, 177, .925),
    (238, 180, .910),
    (237, 175, .925),
    (239, 181, .910),
    (233, 158, .895),
    (249, 106, 1.015),
    (242, 115, 1.000),
    (246, 113, 1.030),
    (252, 125, 1.000),
    (250, 112, 1.000),
    (256, 149, .985),
  ],
  'outfit_sweater': [
    (247, 159, 1.000),
    (250, 162, .985),
    (248, 161, 1.000),
    (246, 165, .985),
    (237, 158, .985),
    (270, 106, .985),
    (258, 115, 1.000),
    (261, 111, 1.000),
    (268, 125, 1.000),
    (248, 114, 1.000),
    (249, 151, 1.000),
  ],
  'supporter_outfit': [
    (240, 173, .895),
    (242, 170, .895),
    (244, 172, .895),
    (237, 167, .895),
    (242, 177, .955),
    (252, 105, 1.000),
    (243, 119, .970),
    (240, 111, 1.000),
    (249, 134, .940),
    (248, 113, .985),
    (255, 144, .925),
  ],
  'chicken_outfit_overalls': [
    (248, 156, 1.000),
    (248, 167, .955),
    (249, 158, 1.000),
    (248, 169, .970),
    (238, 158, .985),
    (269, 105, 1.000),
    (259, 114, .985),
    (254, 109, 1.000),
    (267, 124, 1.000),
    (253, 113, 1.000),
    (254, 147, .970),
  ],
  'doctor_outfit': [
    (247, 157, 1.000),
    (250, 166, .970),
    (249, 162, .985),
    (249, 165, .985),
    (237, 158, 1.000),
    (269, 106, 1.000),
    (259, 116, 1.000),
    (257, 110, .985),
    (267, 125, 1.000),
    (248, 114, 1.000),
    (253, 151, 1.000),
  ],
  'streak_150_outfit_varsity': [
    (240, 153, .940),
    (250, 153, .955),
    (246, 152, .940),
    (251, 152, .940),
    (243, 159, 1.015),
    (269, 106, 1.015),
    (259, 117, 1.015),
    (248, 111, 1.000),
    (253, 125, 1.015),
    (251, 111, .925),
    (255, 150, .985),
  ],
  'streak_365_outfit_year_champion': [
    (271, 143, .895),
    (252, 142, .895),
    (257, 143, .895),
    (261, 144, .895),
    (248, 154, .985),
    (269, 105, 1.030),
    (255, 111, .925),
    (256, 111, 1.015),
    (261, 119, .940),
    (248, 107, .910),
    (258, 143, .940),
  ],
  'streak_500_outfit_legend': [
    (245, 159, .865),
    (248, 159, .850),
    (248, 155, .865),
    (242, 150, .865),
    (240, 151, .940),
    (249, 104, .985),
    (241, 113, .955),
    (245, 107, .955),
    (245, 119, .925),
    (240, 109, .910),
    (256, 145, .925),
  ],
  'streak_1000_outfit_millennium': [
    (260, 140, .850),
    (266, 136, .835),
    (257, 136, .850),
    (251, 139, .835),
    (258, 147, .955),
    (263, 99, .985),
    (256, 106, .910),
    (257, 104, .955),
    (264, 115, .910),
    (251, 106, .910),
    (254, 141, .880),
  ],
};

OutfitFaceFit? outfitFaceFitFor(String? outfitId, PetVariant variant) {
  final fits = outfitFaceFits[outfitId];
  if (fits == null || fits.length != PetVariant.values.length) return null;
  return fits[variant.index];
}
