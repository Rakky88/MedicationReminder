import 'dart:convert';
import 'dart:io';

enum SpecialCodeStatus { redeemed, noEffect, invalid, alreadyUsed, failed }

class SpecialCodeResult {
  const SpecialCodeResult({
    required this.status,
    this.redemptionId,
    this.itemIds = const <String>{},
  });

  final SpecialCodeStatus status;
  final String? redemptionId;
  final Set<String> itemIds;
}

class SpecialCodeService {
  SpecialCodeService._();

  static const _endpoint = String.fromEnvironment('SPECIAL_CODE_ENDPOINT');
  static const _doctorWhoCode = 'BOWTIESAREFLY';
  static const _doctorWhoRedemptionId = 'built-in:doctor-who:v1';
  static const _doctorWhoItemIds = <String>{
    'doctor_hat_fezz',
    'doctor_bow_tie',
    'doctor_outfit',
    'doctor_tardis_toy',
  };

  static bool get configured => _secureEndpoint(_endpoint) != null;

  static Future<SpecialCodeResult> redeem({
    required String code,
    required String languageCode,
  }) async {
    if (code.trim().toUpperCase() == _doctorWhoCode) {
      return const SpecialCodeResult(
        status: SpecialCodeStatus.redeemed,
        redemptionId: _doctorWhoRedemptionId,
        itemIds: _doctorWhoItemIds,
      );
    }
    final endpoint = _secureEndpoint(_endpoint);
    if (endpoint == null) {
      return const SpecialCodeResult(status: SpecialCodeStatus.noEffect);
    }
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 12);
    try {
      final request = await client.postUrl(endpoint);
      request.followRedirects = false;
      request.headers.contentType = ContentType.json;
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      request.write(
        jsonEncode(<String, Object?>{
          'code': code.trim(),
          'languageCode': languageCode,
          'source': 'medication-reminder-app',
        }),
      );
      final response = await request.close().timeout(
        const Duration(seconds: 15),
      );
      final body = await utf8.decoder.bind(response).join();
      if (response.statusCode == HttpStatus.notFound ||
          response.statusCode == HttpStatus.badRequest) {
        return const SpecialCodeResult(status: SpecialCodeStatus.invalid);
      }
      if (response.statusCode == HttpStatus.conflict) {
        return const SpecialCodeResult(status: SpecialCodeStatus.alreadyUsed);
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return const SpecialCodeResult(status: SpecialCodeStatus.failed);
      }
      final value = jsonDecode(body);
      if (value is! Map<dynamic, dynamic>) {
        return const SpecialCodeResult(status: SpecialCodeStatus.failed);
      }
      final redemptionId = value['redemptionId'] as String?;
      final itemIds = (value['itemIds'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<String>()
          .toSet();
      if (redemptionId == null ||
          redemptionId.trim().isEmpty ||
          itemIds.isEmpty) {
        return const SpecialCodeResult(status: SpecialCodeStatus.invalid);
      }
      return SpecialCodeResult(
        status: SpecialCodeStatus.redeemed,
        redemptionId: redemptionId,
        itemIds: itemIds,
      );
    } on Object {
      return const SpecialCodeResult(status: SpecialCodeStatus.failed);
    } finally {
      client.close(force: true);
    }
  }

  static Uri? _secureEndpoint(String source) {
    final uri = Uri.tryParse(source.trim());
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) return null;
    return uri;
  }
}
