import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

enum ContactSendStatus { sent, unavailable, failed }

class SupportService {
  SupportService._();

  static const _clientIdKey = 'contact_client_id_v1';

  static const _contactEndpoint = String.fromEnvironment(
    'CONTACT_FORM_ENDPOINT',
  );

  static bool get contactFormConfigured =>
      _secureEndpoint(_contactEndpoint) != null;

  static Future<ContactSendStatus> sendContactMessage({
    required String replyEmail,
    required String subject,
    required String message,
    required String languageCode,
  }) async {
    final endpoint = _secureEndpoint(_contactEndpoint);
    if (endpoint == null) return ContactSendStatus.unavailable;
    final clientId = await _getOrCreateClientId();
    final messageId = _randomHex(16);
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 12);
    try {
      final request = await client.postUrl(endpoint);
      request.followRedirects = false;
      request.headers.contentType = ContentType.json;
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      request.write(
        jsonEncode(<String, Object?>{
          'replyEmail': replyEmail.trim(),
          'subject': subject.trim(),
          'message': message.trim(),
          'languageCode': languageCode,
          'source': 'medication-reminder-app',
          'clientId': clientId,
          'messageId': messageId,
          // A non-empty value is rejected by the relay. It is deliberately
          // not exposed as a field in the app UI.
          'website': '',
        }),
      );
      final response = await request.close().timeout(
        const Duration(seconds: 15),
      );
      await response.drain<void>();
      return response.statusCode >= 200 && response.statusCode < 300
          ? ContactSendStatus.sent
          : ContactSendStatus.failed;
    } on Object {
      return ContactSendStatus.failed;
    } finally {
      client.close(force: true);
    }
  }

  static Uri? _secureEndpoint(String source) {
    final uri = Uri.tryParse(source.trim());
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) return null;
    return uri;
  }

  static Future<String> _getOrCreateClientId() async {
    final preferences = await SharedPreferences.getInstance();
    final existing = preferences.getString(_clientIdKey);
    if (existing != null && RegExp(r'^[a-f0-9]{32}$').hasMatch(existing)) {
      return existing;
    }
    final generated = _randomHex(16);
    await preferences.setString(_clientIdKey, generated);
    return generated;
  }

  static String _randomHex(int byteCount) {
    final random = Random.secure();
    return List<String>.generate(
      byteCount,
      (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
      growable: false,
    ).join();
  }
}
