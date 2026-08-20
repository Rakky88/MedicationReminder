import 'dart:math';

import 'package:flutter/material.dart';

import 'app_localizations.dart';
import 'cat.dart';
import 'cat_avatar.dart';
import 'cat_inventory_screen.dart';
import 'cat_repository.dart';
import 'cat_shop_screen.dart';
import 'gradual_app_bar.dart';

class CatScreenResult {
  const CatScreenResult({this.profile, this.removed = false});

  final CatProfile? profile;
  final bool removed;
}

class CatScreen extends StatefulWidget {
  const CatScreen({super.key, this.profile});

  final CatProfile? profile;

  @override
  State<CatScreen> createState() => _CatScreenState();
}

class _CatScreenState extends State<CatScreen> {
  late final TextEditingController _nameController;
  late CatProfile? _profile;
  late PetSpecies _species;
  late PetVariant _variant;
  late bool _purrEnabled;
  late bool _meowEnabled;
  late bool _persistentMeowEnabled;
  late bool _dragonMode;
  bool _chickenUnlocked = false;
  bool _saving = false;

  bool get _isAdopting => _profile == null;

  @override
  void initState() {
    super.initState();
    _profile = widget.profile;
    _nameController = TextEditingController(
      text: _profile?.name ?? CatRepository.randomDefaultPetName(),
    );
    _species = _profile?.species ?? PetSpecies.cat;
    final variants = petVariantsForSpecies(_species);
    _variant = _profile?.variant ?? variants[Random().nextInt(variants.length)];
    _purrEnabled = _profile?.purrEnabled ?? true;
    _meowEnabled = _profile?.meowEnabled ?? true;
    _persistentMeowEnabled = _profile?.persistentMeowEnabled ?? false;
    _dragonMode = _profile?.dragonMode ?? false;
    _loadUnlocks();
  }

  Future<void> _loadUnlocks() async {
    try {
      final unlocked = await CatRepository.instance.isChickenUnlocked();
      if (mounted) setState(() => _chickenUnlocked = unlocked);
    } on Object {
      // Cats and dogs remain available if this optional unlock cannot load.
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _meetAnother() {
    final variants = petVariantsForSpecies(_species);
    final current = variants.indexOf(_variant);
    setState(() => _variant = variants[(current + 1) % variants.length]);
  }

  void _selectSpecies(PetSpecies species) {
    if (!_isAdopting || species == PetSpecies.chicken && !_chickenUnlocked) {
      return;
    }
    final variants = petVariantsForSpecies(species);
    setState(() {
      _species = species;
      _variant = variants[Random().nextInt(variants.length)];
    });
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final current = _profile;
      final profile = current == null
          ? await CatRepository.instance.adopt(
              name: _nameController.text,
              variant: _variant,
              purrEnabled: _purrEnabled,
              meowEnabled: _meowEnabled,
              persistentMeowEnabled: _persistentMeowEnabled,
            )
          : await CatRepository.instance.updateSettings(
              current,
              name: _nameController.text,
              purrEnabled: _purrEnabled,
              meowEnabled: _meowEnabled,
              persistentMeowEnabled: _persistentMeowEnabled,
              dragonMode: _dragonMode,
            );
      if (mounted) Navigator.pop(context, CatScreenResult(profile: profile));
    } on Object {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).loadError)),
        );
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _openShop() async {
    final profile = _profile;
    if (profile == null || profile.stage != CatStage.adult) return;
    try {
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => CatShopScreen(profile: profile),
        ),
      );
      final updated = await CatRepository.instance.getProfile();
      if (updated != null && mounted) setState(() => _profile = updated);
    } on Object {
      if (mounted) _showStorageError();
    }
  }

  Future<void> _openInventory() async {
    final profile = _profile;
    if (profile == null || profile.stage != CatStage.adult) return;
    try {
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => CatInventoryScreen(profile: profile),
        ),
      );
      final updated = await CatRepository.instance.getProfile();
      if (updated != null && mounted) setState(() => _profile = updated);
    } on Object {
      if (mounted) _showStorageError();
    }
  }

  Future<void> _remove() async {
    final loc = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.catRemoveTitle),
        content: Text(loc.catRemoveBody),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(loc.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(loc.catRemove),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _saving = true);
    try {
      await CatRepository.instance.remove();
      if (mounted) Navigator.pop(context, const CatScreenResult(removed: true));
    } on Object {
      if (mounted) {
        setState(() => _saving = false);
        _showStorageError();
      }
    }
  }

  void _showStorageError() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).loadError)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final happySoundTitle = switch (_species) {
      PetSpecies.cat => loc.catPurrSound,
      PetSpecies.dog => loc.dogPantSound,
      PetSpecies.chicken => loc.chickenCluckSound,
    };
    final reminderSoundTitle = switch (_species) {
      PetSpecies.cat => loc.catMeowSound,
      PetSpecies.dog => loc.dogBarkSound,
      PetSpecies.chicken => loc.chickenCrowSound,
    };
    final previewBase =
        _profile ??
        CatProfile(
          name: _nameController.text,
          variant: _variant,
          adoptedAt: DateTime.now(),
        );
    final preview = previewBase.copyWith(dragonMode: _dragonMode);
    return Scaffold(
      appBar: GradualAppBar(
        title: Text(_isAdopting ? loc.adoptCat : loc.catSettings),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: <Widget>[
          Card.filled(
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: <Widget>[
                  SizedBox(height: 230, child: CatAvatar(profile: preview)),
                  if (_isAdopting) ...<Widget>[
                    const SizedBox(height: 8),
                    SegmentedButton<PetSpecies>(
                      segments: <ButtonSegment<PetSpecies>>[
                        ButtonSegment<PetSpecies>(
                          value: PetSpecies.cat,
                          icon: const Icon(Icons.pets),
                          label: Text(loc.petCat),
                        ),
                        ButtonSegment<PetSpecies>(
                          value: PetSpecies.dog,
                          icon: const Icon(Icons.pets_outlined),
                          label: Text(loc.petDog),
                        ),
                        if (_chickenUnlocked)
                          ButtonSegment<PetSpecies>(
                            value: PetSpecies.chicken,
                            icon: const Icon(Icons.egg_alt_outlined),
                            label: Text(loc.petChicken),
                          ),
                      ],
                      selected: <PetSpecies>{_species},
                      onSelectionChanged: (selection) =>
                          _selectSpecies(selection.first),
                      showSelectedIcon: false,
                    ),
                    TextButton.icon(
                      onPressed: petVariantsForSpecies(_species).length > 1
                          ? _meetAnother
                          : null,
                      icon: const Icon(Icons.casino_outlined),
                      label: Text(loc.meetPet),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (!_isAdopting && preview.stage == CatStage.adult) ...<Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: _PetActionTile(
                    icon: Icons.storefront_outlined,
                    label: loc.shopShort,
                    onTap: _openShop,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _PetActionTile(
                    icon: Icons.checkroom_outlined,
                    label: loc.wardrobeShort,
                    onTap: _openInventory,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          TextField(
            controller: _nameController,
            decoration: InputDecoration(labelText: loc.catName),
          ),
          const SizedBox(height: 8),
          if (!_isAdopting && preview.stage == CatStage.young)
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              value: _dragonMode,
              onChanged: (value) => setState(() => _dragonMode = value),
              title: const Text('Dragon mode'),
              secondary: const Icon(Icons.auto_awesome_outlined),
            ),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            value: _purrEnabled,
            onChanged: (value) => setState(() => _purrEnabled = value),
            title: Text(happySoundTitle),
            secondary: const Icon(Icons.vibration),
          ),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            value: _meowEnabled,
            onChanged: (value) => setState(() => _meowEnabled = value),
            title: Text(reminderSoundTitle),
            secondary: const Icon(Icons.record_voice_over_outlined),
          ),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            value: _persistentMeowEnabled,
            onChanged: (value) =>
                setState(() => _persistentMeowEnabled = value),
            title: Text(
              _species == PetSpecies.cat
                  ? loc.catPersistentMeow
                  : loc.petPersistentReminder,
            ),
            secondary: const Icon(Icons.notification_important_outlined),
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Icon(Icons.health_and_safety_outlined),
                  const SizedBox(width: 12),
                  Expanded(child: Text(loc.catSafety)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: Icon(_isAdopting ? Icons.pets : Icons.save_outlined),
            label: Text(_isAdopting ? loc.adopt : loc.save),
          ),
          if (!_isAdopting) ...<Widget>[
            const SizedBox(height: 12),
            TextButton(
              onPressed: _saving ? null : _remove,
              child: Text(loc.catRemove),
            ),
          ],
        ],
      ),
    );
  }
}

class _PetActionTile extends StatelessWidget {
  const _PetActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: SizedBox(
        height: 82,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              icon,
              color: onTap == null ? Theme.of(context).disabledColor : null,
            ),
            const SizedBox(height: 6),
            Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    ),
  );
}

class CatAdoptionCard extends StatelessWidget {
  const CatAdoptionCard({super.key, required this.onAdopt});

  final VoidCallback onAdopt;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Card.filled(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onAdopt,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: <Widget>[
              const Icon(Icons.pets, size: 38),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      loc.adoptCat,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 3),
                    Text(loc.adoptCatBody),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
