import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_localizations.dart';
import 'app_release.dart';
import 'cat_repository.dart';
import 'external_link_service.dart';
import 'special_code_service.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  final _codeController = TextEditingController();
  bool _redeeming = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _redeem() async {
    final loc = AppLocalizations.of(context);
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      _message(loc.specialCodeRequired);
      return;
    }
    setState(() => _redeeming = true);
    try {
      if (await CatRepository.instance.getProfile() == null) {
        if (mounted) _message(loc.specialCodeNeedsCat);
        return;
      }
      final response = await SpecialCodeService.redeem(
        code: code,
        languageCode: loc.locale.languageCode,
      );
      if (!mounted) return;
      var message = switch (response.status) {
        SpecialCodeStatus.redeemed => loc.specialCodeInvalid,
        SpecialCodeStatus.invalid => loc.specialCodeInvalid,
        SpecialCodeStatus.alreadyUsed => loc.specialCodeAlreadyUsed,
        SpecialCodeStatus.unavailable ||
        SpecialCodeStatus.failed => loc.specialCodeFailed,
      };
      if (response.status == SpecialCodeStatus.redeemed &&
          response.redemptionId != null) {
        final granted = await CatRepository.instance.registerCodeReward(
          redemptionId: response.redemptionId!,
          itemIds: response.itemIds,
        );
        if (!mounted) return;
        if (granted?.duplicate == true) {
          message = loc.specialCodeAlreadyUsed;
        } else if (granted?.grantedItemIds.isNotEmpty == true) {
          message = loc.specialCodeRedeemed;
          _codeController.clear();
        }
      }
      _message(message);
    } on Object {
      if (mounted) _message(loc.specialCodeFailed);
    } finally {
      if (mounted) setState(() => _redeeming = false);
    }
  }

  void _message(String value) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(value)));
  }

  Future<void> _copyDownloadLink() async {
    final loc = AppLocalizations.of(context);
    try {
      await Clipboard.setData(
        const ClipboardData(text: AppRelease.downloadUrl),
      );
      if (mounted) _message(loc.appLinkCopied);
    } on Object {
      if (mounted) _message(loc.appLinkOpenFailed);
    }
  }

  Future<void> _downloadOrUpdate() async {
    final loc = AppLocalizations.of(context);
    final opened = await ExternalLinkService.openHttps(AppRelease.downloadUrl);
    if (!mounted || opened) return;
    try {
      await Clipboard.setData(
        const ClipboardData(text: AppRelease.downloadUrl),
      );
    } on Object {
      // The same localized message covers both opening and copying failures.
    }
    if (mounted) _message(loc.appLinkOpenFailed);
  }

  Future<void> _openKofi() async {
    final loc = AppLocalizations.of(context);
    final opened = await ExternalLinkService.openHttps(AppRelease.kofiUrl);
    if (!mounted || opened) return;
    try {
      await Clipboard.setData(const ClipboardData(text: AppRelease.kofiUrl));
    } on Object {
      // The localized message also covers the uncommon copy failure.
    }
    if (mounted) _message(loc.buyMeCoffeeOpenFailed);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(loc.aboutApp)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: <Widget>[
          Card.filled(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: <Widget>[
                  Image.asset(
                    'assets/branding/app_logo.png',
                    width: 92,
                    height: 92,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    loc.title,
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    loc.madeBy,
                    style: Theme.of(context).textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    loc.appVersion(AppRelease.displayVersion),
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      const Icon(Icons.share_outlined),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          loc.shareApp,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(loc.shareAppBody),
                  const SizedBox(height: 14),
                  OutlinedButton.icon(
                    onPressed: _copyDownloadLink,
                    icon: const Icon(Icons.content_copy_outlined),
                    label: Text(loc.copyDownloadLink),
                  ),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    onPressed: _downloadOrUpdate,
                    icon: const Icon(Icons.system_update_alt_outlined),
                    label: Text(loc.downloadOrUpdate),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      const Icon(Icons.card_giftcard_outlined),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          loc.specialCodes,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(loc.specialCodesBody),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _codeController,
                    autocorrect: false,
                    enableSuggestions: false,
                    textCapitalization: TextCapitalization.characters,
                    onSubmitted: (_) => _redeem(),
                    decoration: InputDecoration(
                      labelText: loc.specialCodeLabel,
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.key_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _redeeming ? null : _redeem,
                    icon: _redeeming
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.redeem_outlined),
                    label: Text(loc.specialCodeRedeem),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      const Icon(Icons.coffee_outlined),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          loc.buyMeCoffee,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(loc.buyMeCoffeeBody),
                  const SizedBox(height: 12),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Row(
                        children: <Widget>[
                          Image.asset(
                            'assets/branding/paypal_monogram.png',
                            key: const ValueKey<String>('paypal-payment-logo'),
                            width: 32,
                            height: 32,
                            fit: BoxFit.contain,
                            semanticLabel: loc.paypalPayment,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              loc.paypalPayment,
                              style: Theme.of(context).textTheme.labelLarge,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  FilledButton.icon(
                    onPressed: _openKofi,
                    icon: const Icon(Icons.open_in_new),
                    label: Text(loc.buyMeCoffeeAction),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
