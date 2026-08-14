import 'dart:async';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import 'cat.dart';
import 'pet_sound_catalog.dart';

class PetAudio {
  PetAudio._();

  static final PetAudio instance = PetAudio._();

  final AudioPlayer _player = AudioPlayer();
  final Random _random = Random();
  final Map<(PetSpecies, PetSoundMood), List<int>> _shuffleBags = {};
  final Map<(PetSpecies, PetSoundMood), int> _lastIndices = {};
  Timer? _stopTimer;

  Future<void> hungry(CatProfile pet) async {
    if (!pet.hungrySoundEnabled) return;
    await _playSafely(pet.species, PetSoundMood.hungry);
  }

  Future<void> happy(CatProfile pet) async {
    if (!pet.happySoundEnabled) return;
    await _playSafely(pet.species, PetSoundMood.happy);
  }

  Future<void> _playSafely(PetSpecies species, PetSoundMood mood) async {
    try {
      await _playRandom(species, mood);
    } on Object catch (error, stack) {
      // Pet audio is decorative and must never interrupt a medication action.
      debugPrint('Could not play pet audio: $error\n$stack');
    }
  }

  Future<void> _playRandom(PetSpecies species, PetSoundMood mood) async {
    final key = (species, mood);
    final index = _nextIndex(key);
    await _play(
      PetSoundCatalog.assetPath(species, mood, index),
      PetSoundCatalog.maximumPlaybackLength(species, mood),
    );
  }

  int _nextIndex((PetSpecies, PetSoundMood) key) {
    final bag = _shuffleBags.putIfAbsent(key, () => <int>[]);
    if (bag.isEmpty) {
      bag.addAll(
        List<int>.generate(PetSoundCatalog.variantCount, (index) => index)
          ..shuffle(_random),
      );
      final previous = _lastIndices[key];
      if (bag.length > 1 && bag.first == previous) {
        final replacement = bag[1];
        bag[1] = bag.first;
        bag[0] = replacement;
      }
    }
    final next = bag.removeAt(0);
    _lastIndices[key] = next;
    return next;
  }

  Future<void> _play(String assetPath, Duration length) async {
    _stopTimer?.cancel();
    await _player.stop();
    await _player.setReleaseMode(ReleaseMode.stop);
    await _player.play(
      AssetSource(assetPath),
      volume: 1,
      mode: PlayerMode.mediaPlayer,
      ctx: AudioContext(
        android: const AudioContextAndroid(
          contentType: AndroidContentType.sonification,
          usageType: AndroidUsageType.alarm,
          audioFocus: AndroidAudioFocus.gainTransient,
        ),
      ),
    );
    _stopTimer = Timer(length, () async {
      try {
        await _player.stop();
      } on Object catch (error, stack) {
        debugPrint('Could not stop pet audio: $error\n$stack');
      }
    });
  }

  Future<void> dispose() async {
    _stopTimer?.cancel();
    await _player.dispose();
  }
}
