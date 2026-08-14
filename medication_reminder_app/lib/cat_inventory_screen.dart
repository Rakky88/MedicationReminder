import 'package:flutter/material.dart';

import 'app_localizations.dart';
import 'cat.dart';
import 'cat_avatar.dart';
import 'cat_repository.dart';
import 'cat_shop.dart';

class CatInventoryScreen extends StatefulWidget {
  const CatInventoryScreen({super.key, required this.profile});

  final CatProfile profile;

  @override
  State<CatInventoryScreen> createState() => _CatInventoryScreenState();
}

class _CatInventoryScreenState extends State<CatInventoryScreen> {
  late CatProfile _profile = widget.profile;

  Future<void> _toggle(CatShopItem item) async {
    final updated = await CatRepository.instance.toggleAccessory(
      itemId: item.id,
      category: item.category,
    );
    if (updated != null && mounted) setState(() => _profile = updated);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final owned = catShopCatalog
        .where((item) => _profile.ownedAccessoryIds.contains(item.id))
        .toList();
    final canEquip = _profile.stage == CatStage.adult;

    return Scaffold(
      appBar: AppBar(title: Text(loc.catInventory)),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Card.filled(
              margin: EdgeInsets.zero,
              clipBehavior: Clip.antiAlias,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: <Widget>[
                    SizedBox(
                      width: 108,
                      height: 108,
                      child: CatAvatar(profile: _profile),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            _profile.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 4),
                          Text(loc.inventoryOwnedCount(owned.length)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
              children: <Widget>[
                Card(
                  clipBehavior: Clip.antiAlias,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      canEquip
                          ? loc.catInventoryBody
                          : loc.catInventoryKittenBody,
                    ),
                  ),
                ),
                if (owned.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 52),
                    child: Column(
                      children: <Widget>[
                        Icon(
                          Icons.checkroom_outlined,
                          size: 64,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        const SizedBox(height: 14),
                        Text(
                          loc.inventoryEmpty,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                  )
                else
                  ...CatAccessoryCategory.values.expand((category) {
                    final items = owned
                        .where((item) => item.category == category)
                        .toList();
                    if (items.isEmpty) return const <Widget>[];
                    return <Widget>[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(4, 22, 4, 8),
                        child: Text(
                          _categoryName(loc, category),
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      SizedBox(
                        height: 260,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: items.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 10),
                          itemBuilder: (context, index) {
                            final item = items[index];
                            return _InventoryItemCard(
                              item: item,
                              profile: _profile,
                              canEquip: canEquip,
                              onToggle: () => _toggle(item),
                            );
                          },
                        ),
                      ),
                    ];
                  }),
              ],
            ),
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
}

class _InventoryItemCard extends StatelessWidget {
  const _InventoryItemCard({
    required this.item,
    required this.profile,
    required this.canEquip,
    required this.onToggle,
  });

  final CatShopItem item;
  final CatProfile profile;
  final bool canEquip;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final equipped = canEquip && profile.equippedId(item.category) == item.id;
    final preview = profile.copyWith(
      feedCount: 60,
      hungerPoints: 0,
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
              const SizedBox(height: 6),
              Text(
                item.localizedName(loc.locale.languageCode),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 7),
              SizedBox(
                width: double.infinity,
                child: equipped
                    ? FilledButton.tonalIcon(
                        onPressed: onToggle,
                        icon: const Icon(Icons.check, size: 18),
                        label: Text(loc.shopUnequip),
                      )
                    : OutlinedButton(
                        onPressed: canEquip ? onToggle : null,
                        child: Text(
                          canEquip ? loc.shopEquip : loc.inventoryAdultOnly,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
