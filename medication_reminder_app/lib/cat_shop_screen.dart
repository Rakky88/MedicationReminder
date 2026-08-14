import 'package:flutter/material.dart';

import 'app_localizations.dart';
import 'cat.dart';
import 'cat_avatar.dart';
import 'cat_repository.dart';
import 'cat_shop.dart';

class CatShopScreen extends StatefulWidget {
  const CatShopScreen({super.key, required this.profile});

  final CatProfile profile;

  @override
  State<CatShopScreen> createState() => _CatShopScreenState();
}

class _CatShopScreenState extends State<CatShopScreen> {
  late CatProfile _profile = widget.profile;
  bool _chickenUnlocked = false;

  @override
  void initState() {
    super.initState();
    _loadUnlocks();
  }

  Future<void> _loadUnlocks() async {
    final unlocked = await CatRepository.instance.isChickenUnlocked();
    if (mounted) setState(() => _chickenUnlocked = unlocked);
  }

  Future<void> _buy(CatShopItem item) async {
    final loc = AppLocalizations.of(context);
    if (_profile.happyPoints < item.price) {
      _message(loc.shopNotEnough);
      return;
    }
    final updated = await CatRepository.instance.purchaseAccessory(
      itemId: item.id,
      category: item.category,
      price: item.price,
    );
    if (updated == null || !mounted) return;
    setState(() => _profile = updated);
    _message(loc.shopPurchased(item.localizedName(loc.locale.languageCode)));
  }

  void _message(String value) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(value)));
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final visibleCatalog = visibleCatShopCatalog(
      _profile,
      chickenUnlocked: _chickenUnlocked,
    );
    final visibleCategories = CatAccessoryCategory.values
        .where(
          (category) => visibleCatalog.any((item) => item.category == category),
        )
        .toList(growable: false);
    return Scaffold(
      appBar: AppBar(title: Text(loc.catShop)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Card.filled(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: <Widget>[
                  SizedBox(
                    width: 120,
                    height: 120,
                    child: CatAvatar(profile: _profile),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          loc.shopBalance(_formatPoints(_profile.happyPoints)),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          ...visibleCategories.expand(
            (category) => <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 14, 4, 8),
                child: Text(
                  _categoryName(loc, category),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              SizedBox(
                height: 285,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: visibleCatalog
                      .where((item) => item.category == category)
                      .length,
                  separatorBuilder: (_, _) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final item = visibleCatalog
                        .where((candidate) => candidate.category == category)
                        .elementAt(index);
                    return _ShopItemCard(
                      item: item,
                      profile: _profile,
                      onBuy: () => _buy(item),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _categoryName(AppLocalizations loc, CatAccessoryCategory category) =>
      switch (category) {
        CatAccessoryCategory.hat => loc.shopHats,
        CatAccessoryCategory.glasses => loc.shopGlasses,
        CatAccessoryCategory.neckwear => loc.shopNeckwear,
        CatAccessoryCategory.outfit => loc.shopOutfits,
        CatAccessoryCategory.toy => loc.shopToys,
      };

  String _formatPoints(double value) => value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toStringAsFixed(1);
}

class _ShopItemCard extends StatelessWidget {
  const _ShopItemCard({
    required this.item,
    required this.profile,
    required this.onBuy,
  });

  final CatShopItem item;
  final CatProfile profile;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final owned = profile.ownedAccessoryIds.contains(item.id);
    final preview = profile.copyWith(
      equippedAccessories: <String, String>{
        ...profile.equippedAccessories,
        item.category.name: item.id,
      },
    );
    return SizedBox(
      width: 165,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            children: <Widget>[
              Expanded(
                child: CatAvatar(profile: preview, showHungerBadge: false),
              ),
              const SizedBox(height: 5),
              Text(
                item.localizedName(loc.locale.languageCode),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              Text(
                item.supporterExclusive
                    ? loc.shopSupporterExclusive
                    : '${_formatPrice(item.price)} ♥',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 5),
              SizedBox(
                height: 28,
                child: owned
                    ? DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.green.shade700,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              const Icon(
                                Icons.check_circle,
                                size: 16,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                loc.shopOwned,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
              const SizedBox(height: 6),
              SizedBox(
                height: 40,
                width: double.infinity,
                child: owned
                    ? const SizedBox.shrink()
                    : FilledButton(
                        onPressed: item.supporterExclusive ? null : onBuy,
                        child: Text(
                          item.supporterExclusive
                              ? loc.shopSupporterLocked
                              : loc.shopBuy,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatPrice(double value) => value.toInt().toString();
}
