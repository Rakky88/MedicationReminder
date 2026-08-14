import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'app_localizations.dart';
import 'cat.dart';
import 'cat_avatar.dart';

enum CatActivity { normal, purring, doseDue }

class CatHomeCard extends StatefulWidget {
  const CatHomeCard({
    super.key,
    required this.profile,
    required this.activity,
    required this.onTap,
    required this.onSettings,
  });

  final CatProfile profile;
  final CatActivity activity;
  final VoidCallback onTap;
  final VoidCallback onSettings;

  @override
  State<CatHomeCard> createState() => _CatHomeCardState();
}

class _CatHomeCardState extends State<CatHomeCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 720),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _activityText(AppLocalizations loc) {
    final isCat = widget.profile.species == PetSpecies.cat;
    if (widget.activity == CatActivity.purring) {
      return isCat ? loc.catPurring : loc.petCelebrating;
    }
    if (widget.activity == CatActivity.doseDue) {
      return isCat ? loc.catDoseDue : loc.petDoseDue;
    }
    switch (widget.profile.hungerLevel) {
      case CatHungerLevel.full:
        return isCat ? loc.catFull : loc.petFull;
      case CatHungerLevel.peckish:
        return isCat ? loc.catPeckish : loc.petPeckish;
      case CatHungerLevel.hungry:
        return isCat ? loc.catHungry : loc.petHungry;
      case CatHungerLevel.veryHungry:
        return isCat ? loc.catVeryHungry : loc.petVeryHungry;
    }
  }

  String _stageText(AppLocalizations loc) {
    return switch ((widget.profile.species, widget.profile.stage)) {
      (PetSpecies.cat, CatStage.kitten) => loc.catKitten,
      (PetSpecies.cat, CatStage.young) => loc.catYoung,
      (PetSpecies.cat, CatStage.adult) => loc.catAdult,
      (PetSpecies.dog, CatStage.kitten) => loc.dogPuppy,
      (PetSpecies.dog, CatStage.young) => loc.dogYoung,
      (PetSpecies.dog, CatStage.adult) => loc.dogAdult,
      (PetSpecies.chicken, CatStage.kitten) => loc.chickenEgg,
      (PetSpecies.chicken, CatStage.young) => loc.chickenChick,
      (PetSpecies.chicken, CatStage.adult) => loc.chickenAdult,
    };
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final hunger = widget.profile.hungerPoints;
    return Card.filled(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: widget.onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 14),
          child: Row(
            children: <Widget>[
              SizedBox(
                width: 132,
                height: 142,
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    final wave = math.sin(_controller.value * math.pi);
                    final purring = widget.activity == CatActivity.purring;
                    final due = widget.activity == CatActivity.doseDue;
                    return Transform.translate(
                      offset: Offset(
                        due ? (wave - .5) * 5 : 0,
                        purring ? -wave * 3 : 0,
                      ),
                      child: Transform.scale(
                        scale: 1 + (purring ? wave * .025 : 0),
                        child: child,
                      ),
                    );
                  },
                  child: Stack(
                    alignment: Alignment.center,
                    children: <Widget>[
                      CatAvatar(
                        profile: widget.profile,
                        showHungerBadge: false,
                      ),
                      Positioned(
                        right: 1,
                        bottom: 5,
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: colorScheme.surface.withValues(alpha: .9),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            hunger == 0
                                ? Icons.rice_bowl
                                : Icons.no_food_outlined,
                            size: 25,
                            color: hunger == 0
                                ? Colors.green
                                : Colors.deepOrange,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            widget.profile.name,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        IconButton(
                          tooltip: loc.catSettings,
                          onPressed: widget.onSettings,
                          icon: const Icon(Icons.tune),
                        ),
                      ],
                    ),
                    Text('${_stageText(loc)} · ${_activityText(loc)}'),
                    if (widget.profile.stage == CatStage.adult) ...<Widget>[
                      const SizedBox(height: 7),
                      Row(
                        children: <Widget>[
                          const Icon(
                            Icons.favorite,
                            size: 17,
                            color: Colors.pink,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            loc.catHappyPoints(
                              _formatPoints(widget.profile.happyPoints),
                            ),
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                        ],
                      ),
                    ],
                    if (hunger > 0) ...<Widget>[
                      const SizedBox(height: 9),
                      Row(
                        children: List<Widget>.generate(
                          5,
                          (index) => Padding(
                            padding: const EdgeInsets.only(right: 3),
                            child: Icon(
                              index < hunger
                                  ? Icons.restaurant
                                  : Icons.restaurant_outlined,
                              size: 15,
                              color: index < hunger
                                  ? Colors.deepOrange
                                  : colorScheme.outline,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatPoints(double value) => value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toStringAsFixed(1);
}
