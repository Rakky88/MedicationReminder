import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_localizations.dart';
import 'cat.dart';
import 'main.dart' show MedicationReminderApp;
import 'medication_repository.dart';
import 'medication_streak.dart';
import 'medication_streak_repository.dart';
import 'notification_service.dart';

const _catPreferencesKey = 'adopted_cat_v1';
const _demoHappyPoints = 99999.0;
const _demoStreakDays = 99999;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  String? languageCode;
  try {
    languageCode = await MedicationRepository.instance.getPreferredLocale();
  } on Object catch (error, stack) {
    debugPrint('Could not load the demo locale: $error\n$stack');
  }
  try {
    await NotificationService().init();
  } on Object catch (error, stack) {
    debugPrint('Notification startup failed in growth demo: $error\n$stack');
  }

  final adoptedAt = DateTime.now();
  await _storeDemoStreak();
  await _showStage(
    feedCount: 0,
    adoptedAt: adoptedAt,
    languageCode: languageCode,
  );

  Timer(
    const Duration(seconds: 10),
    () => unawaited(
      _showStage(
        feedCount: 14,
        adoptedAt: adoptedAt,
        languageCode: languageCode,
      ),
    ),
  );
  Timer(
    const Duration(seconds: 30),
    () => unawaited(
      _showStage(
        feedCount: 60,
        adoptedAt: adoptedAt,
        languageCode: languageCode,
      ),
    ),
  );
}

Future<void> _showStage({
  required int feedCount,
  required DateTime adoptedAt,
  required String? languageCode,
}) async {
  final profile = CatProfile(
    name: 'Kat 1',
    variant: PetVariant.catOrange,
    adoptedAt: adoptedAt,
    feedCount: feedCount,
    happyPoints: _demoHappyPoints,
  );
  final preferences = await SharedPreferences.getInstance();
  final stored = await preferences.setString(
    _catPreferencesKey,
    jsonEncode(profile.toJson()),
  );
  if (!stored) throw StateError('Could not store the emulator demo pet.');

  runApp(
    MedicationReminderApp(
      key: ValueKey<int>(feedCount),
      initialLocale: appLocaleFromStoredCode(languageCode),
    ),
  );
}

Future<void> _storeDemoStreak() async {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final results = <String, MedicationStreakDayResult>{
    for (var offset = _demoStreakDays; offset >= 1; offset--)
      medicationStreakDayKey(
        DateTime(today.year, today.month, today.day - offset),
      ): MedicationStreakDayResult.success,
  };
  final state = MedicationStreakState(dayResults: results);
  assert(state.current == _demoStreakDays);
  assert(state.best == _demoStreakDays);

  final preferences = await SharedPreferences.getInstance();
  final stored = await preferences.setString(
    MedicationStreakRepository.preferencesKey,
    jsonEncode(state.toJson()),
  );
  if (!stored) throw StateError('Could not store the emulator demo streak.');
}
