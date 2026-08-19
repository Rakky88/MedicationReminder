import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medication_reminder_app/app_localizations.dart';

void main() {
  test('a fresh install defaults to English', () {
    expect(appLocaleFromStoredCode(null), const Locale('en'));
    expect(appLocaleFromStoredCode('unsupported'), const Locale('en'));
  });

  test('every saved supported language is preserved', () {
    for (final languageCode in supportedAppLanguageCodes) {
      expect(
        appLocaleFromStoredCode(languageCode),
        Locale(languageCode),
        reason: 'The stored $languageCode choice must survive an update.',
      );
    }
  });

  test('all five languages contain the same complete set of translations', () {
    final english = AppLocalizations.translationsFor('en');
    expect(english, isNotEmpty);

    for (final languageCode in supportedAppLanguageCodes) {
      final translated = AppLocalizations.translationsFor(languageCode);
      expect(
        translated.keys.toSet(),
        english.keys.toSet(),
        reason: '$languageCode must not silently fall back to English.',
      );
      for (final key in english.keys) {
        expect(translated[key], isNotEmpty, reason: '$languageCode.$key');
        expect(
          _placeholders(translated[key]!),
          _placeholders(english[key]!),
          reason: '$languageCode.$key must preserve its placeholders.',
        );
      }
    }
  });

  test('the localization delegate supports all app languages', () {
    const delegate = AppLocalizationsDelegate();
    for (final locale in supportedAppLocales) {
      expect(delegate.isSupported(locale), isTrue);
    }
    expect(delegate.isSupported(const Locale('it')), isFalse);
  });

  test('the no-effect code response is clear in every app language', () {
    const expected = <String, String>{
      'en': 'This code has no effect right now.',
      'nl': 'Deze code heeft op dit moment geen effect.',
      'de': 'Dieser Code hat derzeit keine Wirkung.',
      'fr': 'Ce code n’a aucun effet pour le moment.',
      'es': 'Este código no tiene ningún efecto por ahora.',
    };
    for (final entry in expected.entries) {
      expect(
        AppLocalizations.translationsFor(entry.key)['specialCodeNoEffect'],
        entry.value,
      );
    }
  });
}

Set<String> _placeholders(String value) => RegExp(
  r'\{[^}]+\}',
).allMatches(value).map((match) => match.group(0)!).toSet();
