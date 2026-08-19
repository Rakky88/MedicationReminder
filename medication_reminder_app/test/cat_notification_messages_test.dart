import 'package:flutter_test/flutter_test.dart';
import 'package:medication_reminder_app/cat.dart';
import 'package:medication_reminder_app/cat_notification_messages.dart';
import 'package:medication_reminder_app/medication.dart';
import 'package:medication_reminder_app/notification_models.dart';

void main() {
  for (final languageCode in <String>['en', 'nl', 'de', 'fr', 'es']) {
    test('contains 500 unique $languageCode cat reminder messages', () {
      final messages = List<String>.generate(
        CatNotificationMessages.count,
        (index) => CatNotificationMessages.messageAt(
          index: index,
          catName: 'MiloDemon123',
          languageCode: languageCode,
        ),
      );

      expect(messages, hasLength(500));
      expect(messages.toSet(), hasLength(500));
      expect(
        messages.every((message) => message.contains('MiloDemon123')),
        isTrue,
      );
      expect(messages.every((message) => message.length <= 82), isTrue);
      expect(
        messages.where((message) => message.contains('Donna')),
        hasLength(3),
      );
      expect(
        messages.where((message) => message.contains('dimi')),
        hasLength(3),
      );
    });
  }

  test('every pet phrase fits even when a medication name is shown', () {
    const medication = Medication(
      id: 1,
      name: 'A deliberately long medication name',
      dosage: '',
      times: <String>['08:00'],
      weekdays: <int>[DateTime.monday],
      showNameInNotifications: true,
    );
    for (final languageCode in <String>['en', 'nl', 'de', 'fr', 'es']) {
      for (var index = 0; index < CatNotificationMessages.count; index++) {
        final body = medicationNotificationBody(
          body: CatNotificationMessages.messageAt(
            index: index,
            catName: 'MiloDemon123',
            languageCode: languageCode,
          ),
          medication: medication,
          languageCode: languageCode,
        );
        expect(body.length, lessThanOrEqualTo(maxNotificationBodyLength));
      }
    }
  });

  test('dog and chicken reminders use the correct animal sound', () {
    final dog = CatNotificationMessages.messageAt(
      index: 58,
      catName: 'Bobby',
      languageCode: 'nl',
      species: PetSpecies.dog,
    );
    final chicken = CatNotificationMessages.messageAt(
      index: 58,
      catName: 'Kiki',
      languageCode: 'en',
      species: PetSpecies.chicken,
    );

    expect(dog, contains('blaft'));
    expect(dog, isNot(contains('miauw')));
    expect(chicken, contains('clucks'));
    expect(chicken, isNot(contains('meow')));
  });
}
