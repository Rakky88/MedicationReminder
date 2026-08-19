import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:medication_reminder_app/app_release.dart';

void main() {
  test('display version stays aligned with the Flutter package version', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final versionMatch = RegExp(
      r'^version:\s*([0-9]+\.[0-9]+\.[0-9]+)\+([0-9]+)$',
      multiLine: true,
    ).firstMatch(pubspec)!;
    final packageParts = versionMatch
        .group(1)!
        .split('.')
        .map(int.parse)
        .join('.');
    final displayParts = AppRelease.displayVersion
        .substring(1)
        .split('.')
        .map(int.parse)
        .join('.');

    expect(displayParts, packageParts);
    expect(int.parse(versionMatch.group(2)!), greaterThan(4));
    expect(AppRelease.downloadUrl, startsWith('https://'));
    expect(AppRelease.downloadUrl, endsWith('/MedicationReminder.apk'));
  });
}
