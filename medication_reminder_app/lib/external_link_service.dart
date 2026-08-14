import 'package:flutter/services.dart';

class ExternalLinkService {
  ExternalLinkService._();

  static const _channel = MethodChannel('medication_reminder/app_links');

  static Future<bool> openHttps(String value) async {
    final uri = Uri.tryParse(value);
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) return false;
    try {
      return await _channel.invokeMethod<bool>('openUrl', <String, String>{
            'url': uri.toString(),
          }) ??
          false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }
}
