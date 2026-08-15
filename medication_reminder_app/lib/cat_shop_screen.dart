import 'package:flutter/material.dart';

import 'app_localizations.dart';
import 'cat.dart';
import 'cat_avatar.dart';
import 'cat_repository.dart';
import 'cat_shop.dart';
import 'medication_streak.dart';
import 'medication_streak_repository.dart';

class CatShopScreen extends StatefulWidget {
  const CatShopScreen({super.key, required this.profile});

  final CatProfile profile;

  @override
  State<CatShopScreen> createState() => _CatShopScreenState();
}

class _CatShopScreenState extends State<CatShopScreen> {
  late CatProfile _profile = widget.profile;
  bool _chickenUnlocked = false;
  MedicationStreakState _streak = MedicationStreakState.empty;
  final Set<String> _buyingItemIds = <String>{};

  @override
  void initState() {
    super.initState();
    _loadUnlocks();
  }

  Future<void> _loadUnlocks() async {
    try {
      final unlocked = await CatRepository.instance.isChickenUnlocked();
      if (mounted) setState(() => _chickenUnlocked = unlocked);
    } on Object {
      // The regular catalog remains usable if this optional unlock cannot load.
    }
    try {
      final streak = await MedicationStreakRepository.instance.getState();
      if (mounted) setState(() => _streak = streak);
    } on Object {
      // A damaged streak record must not make the regular shop unavailable.
    }
  }

  Future<void> _buy(CatShopItem item) async {
    final loc = AppLocalizations.of(context);
    if (_buyingItemIds.contains(item.id)) return;
    if (item.requiredMedicationStreak case final requirement?
        when _streak.best < requirement) {
      _message(loc.shopStreakLocked(requirement));
      return;
    }
    if (_profile.happyPoints < item.price) {
      _message(loc.shopNotEnough);
      return;
    }
    setState(() => _buyingItemIds.add(item.id));
    try {
      final updated = await CatRepository.instance.purchaseAccessory(
        itemId: item.id,
        category: item.category,
        price: item.price,
      );
      if (updated == null || !mounted) return;
      setState(() => _profile = updated);
      _message(loc.shopPurchased(item.localizedName(loc.locale.languageCode)));
    } on Object {
      if (mounted) _message(loc.loadError);
    } finally {
      if (mounted) setState(() => _buyingItemIds.remove(item.id));
    }
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
    final regularCatalog = visibleCatalog
        .where((item) => !item.isStreakReward)
        .toList(growable: false);
    final streakCatalog = visibleCatalog
        .where((item) => item.isStreakReward)
        .toList(growable: false);
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(loc.catShop),
          bottom: TabBar(
            tabs: <Widget>[
              Tab(text: loc.shopRegularItems),
              Tab(text: loc.shopStreakItems),
            ],
          ),
        ),
        body: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Card.filled(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: <Widget>[
                      SizedBox(
                        width: 92,
                        height: 92,
                        child: CatAvatar(profile: _profile),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              loc.shopBalance(
                                _formatPoints(_profile.happyPoints),
                              ),
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              loc.shopStreakSummary(
                                _streak.current,
                                _streak.best,
                              ),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: TabBarView(
                children: <Widget>[
                  _catalogList(loc, regularCatalog),
                  _catalogList(loc, streakCatalog),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _catalogList(AppLocalizations loc, List<CatShopItem> catalog) {
    final visibleCategories = CatAccessoryCategory.values
        .where((category) => catalog.any((item) => item.category == category))
        .toList(growable: false);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
      children: <Widget>[
        ...visibleCategories.expand((category) {
          final items = catalog
              .where((item) => item.category == category)
              .toList(growable: false);
          return <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 14, 4, 8),
              child: Text(
                _categoryName(loc, category),
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            SizedBox(
              height: 300,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: items.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (context, index) => _ShopItemCard(
                  item: items[index],
                  profile: _profile,
                  bestMedicationStreak: _streak.best,
                  onBuy: _buyingItemIds.contains(items[index].id)
                      ? null
                      : () => _buy(items[index]),
                ),
              ),
            ),
          ];
        }),
      ],
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
    required this.bestMedicationStreak,
    required this.onBuy,
  });

  final CatShopItem item;
  final CatProfile profile;
  final int bestMedicationStreak;
  final VoidCallback? onBuy;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final owned = profile.ownedAccessoryIds.contains(item.id);
    final streakUnlocked =
        item.requiredMedicationStreak == null ||
        bestMedicationStreak >= item.requiredMedicationStreak!;
    final preview = profile.copyWith(
      equippedAccessories: <String, String>{
        ...profile.equippedAccessories,
        item.category.name: item.id,
      },
    );
    return SizedBox(
      width: 170,
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
                item.isStreakReward
                    ? loc.shopStreakRequirement(item.requiredMedicationStreak!)
                    : item.supporterExclusive
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
                        onPressed: item.supporterExclusive || !streakUnlocked
                            ? null
                            : onBuy,
                        child: Text(
                          item.supporterExclusive
                              ? loc.shopSupporterLocked
                              : !streakUnlocked
                              ? loc.shopStreakLocked(
                                  item.requiredMedicationStreak!,
                                )
                              : item.isStreakReward
                              ? loc.shopStreakClaim
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
