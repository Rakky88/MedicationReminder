import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Android 12 splash uses the transparent logo mark', () async {
    for (final path in <String>[
      'android/app/src/main/res/values-v31/styles.xml',
      'android/app/src/main/res/values-night-v31/styles.xml',
    ]) {
      final styles = await File(path).readAsString();
      expect(
        styles,
        contains(
          '<item name="android:windowSplashScreenAnimatedIcon">'
          '@drawable/ic_launcher_foreground</item>',
        ),
      );
      expect(
        styles,
        contains(
          '<item name="android:windowSplashScreenIconBackgroundColor">'
          '@android:color/transparent</item>',
        ),
      );
      expect(
        styles,
        contains(
          '<item name="android:windowSplashScreenBrandingImage">'
          '@drawable/splash_branding</item>',
        ),
      );
      expect(styles, isNot(contains('@mipmap/ic_launcher')));
    }

    for (final path in <String>[
      'android/app/src/main/res/drawable-xxxhdpi/splash_branding.png',
      'android/app/src/main/res/drawable-night-xxxhdpi/splash_branding.png',
    ]) {
      final branding = File(path);
      expect(await branding.exists(), isTrue);
      expect(await branding.length(), greaterThan(1000));
    }

    final logoBytes = await File(
      'android/app/src/main/res/drawable/ic_launcher_foreground.png',
    ).readAsBytes();
    final codec = await ui.instantiateImageCodec(logoBytes);
    final frame = await codec.getNextFrame();
    final image = frame.image;
    final pixels = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    expect(pixels, isNotNull);
    final rowStride = image.width * 4;
    final cornerAlphas = <int>[
      pixels!.getUint8(3),
      pixels.getUint8((image.width - 1) * 4 + 3),
      pixels.getUint8((image.height - 1) * rowStride + 3),
      pixels.getUint8(image.height * rowStride - 1),
    ];
    expect(cornerAlphas, everyElement(0));
    image.dispose();
    codec.dispose();
  });
}
