import 'cat.dart';

enum PetSoundMood { happy, hungry }

/// Single source of truth for every bundled pet-sound variant.
abstract final class PetSoundCatalog {
  static const variantCount = 20;

  static String assetPath(PetSpecies species, PetSoundMood mood, int index) {
    if (index < 0 || index >= variantCount) {
      throw RangeError.range(index, 0, variantCount - 1, 'index');
    }
    final number = (index + 1).toString().padLeft(2, '0');
    return 'sounds/${stem(species, mood)}_$number.${extension(species)}';
  }

  static List<String> assetPaths(PetSpecies species, PetSoundMood mood) =>
      List<String>.generate(
        variantCount,
        (index) => assetPath(species, mood, index),
        growable: false,
      );

  static List<String> reminderSoundNames(
    PetSpecies species,
  ) => List<String>.generate(
    variantCount,
    (index) =>
        '${stem(species, PetSoundMood.hungry)}_${(index + 1).toString().padLeft(2, '0')}',
    growable: false,
  );

  static List<String> reminderChannelIds(PetSpecies species) {
    final channelVersion = species == PetSpecies.cat ? 'v3' : 'v2';
    return List<String>.generate(
      variantCount,
      (index) =>
          'medication_${species.name}_voice_${(index + 1).toString().padLeft(2, '0')}_$channelVersion',
      growable: false,
    );
  }

  static String stem(PetSpecies species, PetSoundMood mood) =>
      switch ((species, mood)) {
        (PetSpecies.cat, PetSoundMood.happy) => 'cat_purr',
        (PetSpecies.cat, PetSoundMood.hungry) => 'cat_meow',
        (PetSpecies.dog, PetSoundMood.happy) => 'dog_pant',
        (PetSpecies.dog, PetSoundMood.hungry) => 'dog_bark',
        (PetSpecies.chicken, PetSoundMood.happy) => 'chicken_cluck',
        (PetSpecies.chicken, PetSoundMood.hungry) => 'chicken_crow',
      };

  static String extension(PetSpecies species) =>
      species == PetSpecies.cat ? 'wav' : 'mp3';

  static Duration maximumPlaybackLength(
    PetSpecies species,
    PetSoundMood mood,
  ) => switch ((species, mood)) {
    (PetSpecies.cat, PetSoundMood.happy) => const Duration(seconds: 6),
    (PetSpecies.cat, PetSoundMood.hungry) => const Duration(seconds: 3),
    (PetSpecies.dog, PetSoundMood.happy) => const Duration(seconds: 6),
    (PetSpecies.dog, PetSoundMood.hungry) => const Duration(seconds: 4),
    (PetSpecies.chicken, PetSoundMood.happy) => const Duration(seconds: 5),
    (PetSpecies.chicken, PetSoundMood.hungry) => const Duration(seconds: 5),
  };
}
