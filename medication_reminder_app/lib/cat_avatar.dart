import 'package:flutter/material.dart';

import 'cat.dart';
import 'cat_shop.dart';

class CatAvatar extends StatelessWidget {
  const CatAvatar({
    super.key,
    required this.profile,
    this.fit = BoxFit.contain,
    this.showHungerBadge = true,
  });

  final CatProfile profile;
  final BoxFit fit;
  final bool showHungerBadge;

  @override
  Widget build(BuildContext context) {
    final hunger = profile.hungerPoints.clamp(0, 5);
    final saturation = 1 - hunger * .12;
    final canWearAccessories = profile.stage == CatStage.adult;
    final outfit = canWearAccessories
        ? catShopItemById(profile.equippedId(CatAccessoryCategory.outfit))
        : null;
    final hat = canWearAccessories
        ? catShopItemById(profile.equippedId(CatAccessoryCategory.hat))
        : null;
    final glasses = canWearAccessories
        ? catShopItemById(profile.equippedId(CatAccessoryCategory.glasses))
        : null;
    final neckwear = canWearAccessories
        ? catShopItemById(profile.equippedId(CatAccessoryCategory.neckwear))
        : null;
    final toy = canWearAccessories
        ? catShopItemById(profile.equippedId(CatAccessoryCategory.toy))
        : null;

    return Semantics(
      label: hunger == 0
          ? '${profile.name}, healthy ${profile.species.name}'
          : '${profile.name}, hungry ${profile.species.name}, $hunger of 5',
      image: true,
      child: Stack(
        fit: StackFit.expand,
        alignment: Alignment.center,
        children: <Widget>[
          Transform.scale(
            scaleX: 1 - hunger * .055,
            scaleY: 1 - hunger * .01,
            child: ColorFiltered(
              colorFilter: ColorFilter.matrix(_saturationMatrix(saturation)),
              child: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  Image.asset(petBodyAssetPath(profile), fit: fit),
                  if (outfit?.adaptiveOverlay == true) _accessoryImage(outfit!),
                  if (neckwear != null) _accessoryImage(neckwear),
                  if (hat != null) _accessoryImage(hat),
                  if (glasses != null) _accessoryImage(glasses),
                  if (hunger >= 2 && profile.stage == CatStage.adult)
                    CustomPaint(painter: _HungryRibsPainter(hunger / 5)),
                ],
              ),
            ),
          ),
          if (toy != null) _accessoryImage(toy),
          if (showHungerBadge && hunger > 0)
            Positioned(
              left: 4,
              bottom: 4,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.surface.withValues(alpha: .92),
                  shape: BoxShape.circle,
                ),
                child: const Padding(
                  padding: EdgeInsets.all(6),
                  child: Icon(
                    Icons.no_food_outlined,
                    color: Colors.deepOrange,
                    size: 24,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _accessoryImage(CatShopItem item) {
    if (!item.adaptiveOverlay) {
      return Image.asset(item.fittedAssetPath(profile.variant), fit: fit);
    }
    final transform = item.adaptiveTransform(profile.variant);
    return LayoutBuilder(
      builder: (context, constraints) => Transform.translate(
        offset: Offset(
          constraints.maxWidth * transform.dx,
          constraints.maxHeight * transform.dy,
        ),
        child: Transform.scale(
          scale: transform.scale,
          child: Image.asset(
            item.assetPath,
            key: ValueKey<String>(
              'adaptive-${profile.variant.name}-${item.id}',
            ),
            fit: fit,
          ),
        ),
      ),
    );
  }

  List<double> _saturationMatrix(double saturation) {
    final inv = 1 - saturation;
    final r = .213 * inv;
    final g = .715 * inv;
    final b = .072 * inv;
    return <double>[
      r + saturation,
      g,
      b,
      0,
      0,
      r,
      g + saturation,
      b,
      0,
      0,
      r,
      g,
      b + saturation,
      0,
      0,
      0,
      0,
      0,
      1,
      0,
    ];
  }
}

class _HungryRibsPainter extends CustomPainter {
  const _HungryRibsPainter(this.strength);

  final double strength;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.deepOrange.withValues(alpha: .22 + strength * .35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.shortestSide * .009
      ..strokeCap = StrokeCap.round;
    for (var index = 0; index < 3; index++) {
      final top = size.height * (.53 + index * .055);
      canvas.drawArc(
        Rect.fromLTRB(
          size.width * .29,
          top,
          size.width * .51,
          top + size.height * .09,
        ),
        3.55,
        1.25,
        false,
        paint,
      );
      canvas.drawArc(
        Rect.fromLTRB(
          size.width * .49,
          top,
          size.width * .71,
          top + size.height * .09,
        ),
        5.76,
        1.25,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _HungryRibsPainter oldDelegate) =>
      oldDelegate.strength != strength;
}
