import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:medication_reminder_app/cat.dart';
import 'package:medication_reminder_app/pet_sound_catalog.dart';

void main() {
  for (final species in PetSpecies.values) {
    for (final mood in PetSoundMood.values) {
      test('${species.name} has twenty unique ${mood.name} sounds', () {
        final paths = PetSoundCatalog.assetPaths(species, mood);
        final sounds = paths
            .map((path) => File('assets/$path'))
            .toList(growable: false);

        expect(PetSoundCatalog.variantCount, 20);
        expect(paths, hasLength(20));
        expect(sounds.every((sound) => sound.existsSync()), isTrue);
        expect(
          sounds.map((sound) => base64Encode(sound.readAsBytesSync())).toSet(),
          hasLength(20),
        );

        for (final sound in sounds) {
          expect(sound.lengthSync(), greaterThan(10000), reason: sound.path);
          final bytes = sound.readAsBytesSync();
          if (species == PetSpecies.cat) {
            expect(String.fromCharCodes(bytes.take(4)), 'RIFF');
            expect(
              _maximumPcmAmplitude(bytes),
              greaterThan(1000),
              reason: sound.path,
            );
          } else {
            expect(String.fromCharCodes(bytes.take(3)), 'ID3');
          }
        }
      });
    }
  }

  test('all hungry sound variants are available to Android notifications', () {
    for (final species in PetSpecies.values) {
      final names = PetSoundCatalog.reminderSoundNames(species);
      final notificationChannels = PetSoundCatalog.reminderChannelIds(species);
      final alarmChannels = PetSoundCatalog.alarmChannelIds(species);
      expect(names, hasLength(20));
      expect(notificationChannels, hasLength(20));
      expect(notificationChannels.toSet(), hasLength(20));
      expect(alarmChannels, hasLength(20));
      expect(alarmChannels.toSet(), hasLength(20));
      expect(
        notificationChannels.toSet().intersection(alarmChannels.toSet()),
        isEmpty,
      );
      for (final name in names) {
        expect(
          File(
            'android/app/src/main/res/raw/$name.${PetSoundCatalog.extension(species)}',
          ).existsSync(),
          isTrue,
          reason: '$species: $name',
        );
      }
    }
  });

  test('native Android escalation uses the same twenty-variant stems', () {
    final source = File(
      'android/app/src/main/kotlin/com/example/medication_reminder_app/'
      'MedicationEscalation.kt',
    ).readAsStringSync();
    expect(source, contains('SOUND_VARIANT_COUNT = 20'));
    for (final stem in <String>['cat_meow', 'dog_bark', 'chicken_crow']) {
      expect(source, contains('"$stem"'));
    }
  });

  test('alarm, follow-up, and in-app audio use separate Android usages', () {
    final notificationSource = File(
      'lib/notification_service_native.dart',
    ).readAsStringSync();
    final inAppSource = File('lib/pet_audio.dart').readAsStringSync();
    final escalationSource = File(
      'android/app/src/main/kotlin/com/example/medication_reminder_app/'
      'MedicationEscalation.kt',
    ).readAsStringSync();

    expect(notificationSource, contains('AudioAttributesUsage.alarm'));
    expect(notificationSource, contains('AndroidNotificationCategory.alarm'));
    expect(
      notificationSource,
      contains('useAlarmAudio: !reminder.slot.medication.notificationsOnly'),
    );
    expect(inAppSource, contains('AndroidUsageType.media'));
    expect(escalationSource, contains('AudioAttributes.USAGE_NOTIFICATION'));
  });
}

int _maximumPcmAmplitude(Uint8List bytes) {
  final data = ByteData.sublistView(bytes);
  var offset = 12;
  while (offset + 8 <= bytes.length) {
    final chunkName = String.fromCharCodes(bytes.sublist(offset, offset + 4));
    final chunkLength = data.getUint32(offset + 4, Endian.little);
    final chunkStart = offset + 8;
    final chunkEnd = (chunkStart + chunkLength).clamp(0, bytes.length);
    if (chunkName == 'data') {
      var peak = 0;
      for (var sample = chunkStart; sample + 1 < chunkEnd; sample += 2) {
        final amplitude = data.getInt16(sample, Endian.little).abs();
        if (amplitude > peak) peak = amplitude;
      }
      return peak;
    }
    offset = chunkEnd + (chunkLength.isOdd ? 1 : 0);
  }
  return 0;
}
