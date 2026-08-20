import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'cat.dart';
import 'cat_avatar.dart';
import 'cat_shop.dart';
import 'gradual_app_bar.dart';

// V15 verifies the real layering problem: every head/neck wearable on every
// full-body outfit, for all eleven adult pets. One page contains all pets for
// one outfit/wearable pair, so a selected issue always identifies the exact
// three-part combination that needs a source-local correction.
final _auditOutfits = catShopCatalog
    .where((item) => item.category == CatAccessoryCategory.outfit)
    .toList(growable: false);

final _auditWearables = catShopCatalog
    .where(
      (item) =>
          item.category == CatAccessoryCategory.hat ||
          item.category == CatAccessoryCategory.glasses ||
          item.category == CatAccessoryCategory.neckwear,
    )
    .toList(growable: false);

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const _AccessoryAuditApp());
}

class _AccessoryAuditApp extends StatelessWidget {
  const _AccessoryAuditApp();

  @override
  Widget build(BuildContext context) => const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: _AccessoryAuditScreen(),
  );
}

class _AccessoryAuditScreen extends StatefulWidget {
  const _AccessoryAuditScreen();

  @override
  State<_AccessoryAuditScreen> createState() => _AccessoryAuditScreenState();
}

class _AccessoryAuditScreenState extends State<_AccessoryAuditScreen> {
  static const _preferencesKey = 'accessory_visual_audit_v15_outfit_layers';
  static const _exportFileName = 'accessory_visual_audit_v15_outfit_layers.txt';

  final Set<String> _issues = <String>{};
  int _page = 0;
  bool _loaded = false;

  int get _combinationPages => _auditOutfits.length * _auditWearables.length;
  bool get _summaryPage => _page == _combinationPages;
  int get _outfitIndex => _page ~/ _auditWearables.length;
  int get _wearableIndex => _page % _auditWearables.length;
  CatShopItem get _outfit => _auditOutfits[_outfitIndex];
  CatShopItem get _wearable => _auditWearables[_wearableIndex];

  @override
  void initState() {
    super.initState();
    unawaited(_loadIssues());
  }

  Future<void> _loadIssues() async {
    final preferences = await SharedPreferences.getInstance();
    final stored =
        preferences.getStringList(_preferencesKey) ?? const <String>[];
    if (!mounted) return;
    setState(() {
      _issues.addAll(stored);
      _loaded = true;
    });
  }

  String _issueKey(PetVariant variant) =>
      '${_outfit.id}|${_wearable.id}|${variant.name}';

  void _toggleIssue(PetVariant variant) {
    final key = _issueKey(variant);
    setState(
      () => _issues.contains(key) ? _issues.remove(key) : _issues.add(key),
    );
    unawaited(_persistIssues());
  }

  void _toggleWholePage() {
    final keys = PetVariant.values.map(_issueKey).toSet();
    final allSelected = _issues.containsAll(keys);
    setState(
      () => allSelected ? _issues.removeAll(keys) : _issues.addAll(keys),
    );
    unawaited(_persistIssues());
  }

  void _selectOutfit(String? id) {
    final index = _auditOutfits.indexWhere((item) => item.id == id);
    if (index < 0) return;
    setState(() => _page = index * _auditWearables.length + _wearableIndex);
  }

  void _selectWearable(String? id) {
    final index = _auditWearables.indexWhere((item) => item.id == id);
    if (index < 0) return;
    setState(() => _page = _outfitIndex * _auditWearables.length + index);
  }

  Future<void> _persistIssues() async {
    final sorted = _issues.toList()..sort();
    final preferences = await SharedPreferences.getInstance();
    await preferences.setStringList(_preferencesKey, sorted);
    try {
      final directory = await getExternalStorageDirectory();
      if (directory != null) {
        await File('${directory.path}/$_exportFileName').writeAsString(
          sorted.isEmpty
              ? 'Geen visuele problemen geselecteerd.'
              : sorted.join('\n'),
          flush: true,
        );
      }
    } on Object {
      // The in-app summary and clipboard remain available if export is blocked.
    }
  }

  Future<void> _copyResults() async {
    final sorted = _issues.toList()..sort();
    final result = sorted.isEmpty
        ? 'Geen visuele problemen geselecteerd.'
        : sorted.join('\n');
    await Clipboard.setData(ClipboardData(text: result));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Controlelijst gekopieerd.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: GradualAppBar(
        title: Text(
          _summaryPage
              ? 'Resultaten'
              : '${_page + 1}/$_combinationPages outfitcontrole',
        ),
        actions: <Widget>[
          if (!_summaryPage)
            IconButton(
              onPressed: _toggleWholePage,
              tooltip: 'Hele pagina fout/goed',
              icon: const Icon(Icons.playlist_add_check_circle_outlined),
            ),
        ],
      ),
      body: Column(
        children: <Widget>[
          if (!_summaryPage) ...<Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 3, 8, 0),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: _AuditSelector(
                      label: 'Outfit',
                      value: _outfit.id,
                      items: _auditOutfits,
                      onChanged: _selectOutfit,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _AuditSelector(
                      label: 'Bril / hoed / strik',
                      value: _wearable.id,
                      items: _auditWearables,
                      onChanged: _selectWearable,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 2, 8, 0),
              child: Text(
                'Tik alleen op een dier als deze combinatie niet goed zit. '
                'Rood = fout · geselecteerd: ${_issues.length}',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
          Expanded(
            child: _summaryPage
                ? _AuditSummary(issues: _issues, onCopy: _copyResults)
                : GridView.count(
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(6),
                    crossAxisCount: 3,
                    childAspectRatio: .78,
                    mainAxisSpacing: 3,
                    crossAxisSpacing: 3,
                    children: PetVariant.values
                        .map(
                          (variant) => _PetAuditTile(
                            variant: variant,
                            outfit: _outfit,
                            wearable: _wearable,
                            selected: _issues.contains(_issueKey(variant)),
                            onTap: () => _toggleIssue(variant),
                          ),
                        )
                        .toList(growable: false),
                  ),
          ),
          SafeArea(
            top: false,
            child: Row(
              children: <Widget>[
                Expanded(
                  child: FilledButton.tonal(
                    onPressed: _page == 0
                        ? null
                        : () => setState(() => _page--),
                    child: const Text('VORIGE'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    onPressed: _summaryPage
                        ? _copyResults
                        : () => setState(() => _page++),
                    child: Text(_summaryPage ? 'KOPIEER LIJST' : 'VOLGENDE'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AuditSelector extends StatelessWidget {
  const _AuditSelector({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<CatShopItem> items;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) => DropdownButtonFormField<String>(
    initialValue: value,
    isExpanded: true,
    decoration: InputDecoration(
      labelText: label,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    ),
    items: items
        .map(
          (item) => DropdownMenuItem<String>(
            value: item.id,
            child: Text(
              item.localizedName('nl'),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        )
        .toList(growable: false),
    onChanged: onChanged,
  );
}

class _PetAuditTile extends StatelessWidget {
  const _PetAuditTile({
    required this.variant,
    required this.outfit,
    required this.wearable,
    required this.selected,
    required this.onTap,
  });

  final PetVariant variant;
  final CatShopItem outfit;
  final CatShopItem wearable;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final profile = CatProfile(
      name: variant.name,
      variant: variant,
      adoptedAt: DateTime(2026, 1, 1),
      feedCount: 60,
      ownedAccessoryIds: <String>{outfit.id, wearable.id},
      equippedAccessories: <String, String>{
        CatAccessoryCategory.outfit.name: outfit.id,
        wearable.category.name: wearable.id,
      },
    );
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            DecoratedBox(
              decoration: BoxDecoration(
                color: selected
                    ? const Color(0xFFFFE5E5)
                    : const Color(0xFFF1F4F8),
                border: Border.all(
                  color: selected
                      ? const Color(0xFFC62828)
                      : const Color(0xFFCCD5E0),
                  width: selected ? 3 : 1,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: <Widget>[
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(2),
                      child: CatAvatar(
                        profile: profile,
                        showHungerBadge: false,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(2, 0, 2, 3),
                    child: Text(
                      variant.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 9),
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              const Positioned(
                top: 3,
                right: 3,
                child: Icon(Icons.report, color: Color(0xFFC62828), size: 22),
              ),
          ],
        ),
      ),
    );
  }
}

class _AuditSummary extends StatelessWidget {
  const _AuditSummary({required this.issues, required this.onCopy});

  final Set<String> issues;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final sorted = issues.toList()..sort();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        Text(
          sorted.isEmpty
              ? 'Geen problemen geselecteerd.'
              : '${sorted.length} combinaties geselecteerd:',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        for (final issue in sorted)
          ListTile(
            dense: true,
            leading: const Icon(
              Icons.report_outlined,
              color: Color(0xFFC62828),
            ),
            title: Text(issue.replaceAll('|', ' — ')),
          ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: onCopy,
          icon: const Icon(Icons.copy),
          label: const Text('KOPIEER CONTROLELIJST'),
        ),
      ],
    );
  }
}
