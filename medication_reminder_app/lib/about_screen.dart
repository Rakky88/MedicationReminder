import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_branding.dart';
import 'app_localizations.dart';
import 'app_release.dart';
import 'cat_repository.dart';
import 'external_link_service.dart';
import 'gradual_app_bar.dart';
import 'special_code_service.dart';

class _AboutBrandHero extends StatelessWidget {
  const _AboutBrandHero({
    required this.title,
    required this.madeBy,
    required this.version,
  });

  final String title;
  final String madeBy;
  final String version;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final cardStart = Color.alphaBlend(
      colors.primary.withValues(alpha: 0.07),
      colors.surfaceContainerLow,
    );
    final cardEnd = Color.alphaBlend(
      colors.secondary.withValues(alpha: 0.08),
      colors.surfaceContainerLow,
    );

    return Container(
      key: const ValueKey<String>('about-brand-hero'),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[cardStart, cardEnd],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: colors.outlineVariant.withValues(alpha: 0.65),
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.09),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: <Widget>[
          Positioned(
            top: -72,
            right: -54,
            child: _BrandGlow(
              size: 170,
              color: colors.secondary.withValues(alpha: 0.08),
            ),
          ),
          Positioned(
            bottom: -68,
            left: -48,
            child: _BrandGlow(
              size: 150,
              color: colors.primary.withValues(alpha: 0.08),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
            child: SizedBox(
              width: double.infinity,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  AppLogoMark(
                    size: 112,
                    imageKey: const ValueKey<String>('about-brand-logo'),
                    semanticLabel: title,
                  ),
                  const SizedBox(height: 14),
                  FittedBox(
                    alignment: Alignment.center,
                    fit: BoxFit.scaleDown,
                    child: AppWordmark(
                      title: title,
                      textKey: const ValueKey<String>('about-brand-title'),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1.1,
                        height: 1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 13),
                  Container(
                    width: 58,
                    height: 4,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: <Color>[colors.primary, colors.secondary],
                      ),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Center(
                    child: _AboutInfoPill(
                      key: const ValueKey<String>('about-maker-badge'),
                      icon: Icons.person_outline_rounded,
                      label: madeBy,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: _AboutInfoPill(
                      key: const ValueKey<String>('about-version-badge'),
                      icon: Icons.sell_outlined,
                      label: version,
                    ),
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

class _BrandGlow extends StatelessWidget {
  const _BrandGlow({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}

class _AboutInfoPill extends StatelessWidget {
  const _AboutInfoPill({super.key, required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.76),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.7)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 16, color: colors.primary),
          const SizedBox(width: 7),
          Flexible(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: theme.textTheme.labelLarge?.copyWith(
                color: colors.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

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
      appBar: GradualAppBar(title: Text(loc.aboutApp)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: <Widget>[
          _AboutBrandHero(
            title: loc.title,
            madeBy: loc.madeBy,
            version: loc.appVersion(AppRelease.displayVersion),
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
