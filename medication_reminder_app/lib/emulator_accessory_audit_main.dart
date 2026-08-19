import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'cat.dart';
import 'cat_avatar.dart';
import 'cat_shop.dart';

// V14 contains only the two cat glasses selected in the completed V13 review.
// Every other combination remains approved and stays out of this last check.
const _reviewTargets = <String, Set<PetVariant>>{
  'glasses_round': <PetVariant>{PetVariant.catTuxedo, PetVariant.catGray},
};

final _auditCatalog = catShopCatalog
    .where((item) => _reviewTargets.containsKey(item.id))
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
  static const _preferencesKey = 'accessory_visual_audit_v14_fixed_recheck';
  static const _exportFileName = 'accessory_visual_audit_v14_fixed_recheck.txt';

  final Set<String> _issues = <String>{};
  int _page = 0;
  bool _loaded = false;

  bool get _hasDragonPage => _reviewTargets.containsKey('dragon_mode');
  int get _totalPages => _auditCatalog.length + (_hasDragonPage ? 1 : 0) + 1;
  bool get _dragonPage => _hasDragonPage && _page == _auditCatalog.length;
  bool get _summaryPage => _page == _totalPages - 1;
  String get _pageId => _dragonPage ? 'dragon_mode' : _auditCatalog[_page].id;
  List<PetVariant> get _pageVariants => PetVariant.values
      .where(_reviewTargets[_pageId]!.contains)
      .toList(growable: false);

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

  String _issueKey(PetVariant variant) => '$_pageId|${variant.name}';

  void _toggleIssue(PetVariant variant) {
    final key = _issueKey(variant);
    setState(
      () => _issues.contains(key) ? _issues.remove(key) : _issues.add(key),
    );
    unawaited(_persistIssues());
  }

  void _toggleWholePage() {
    final keys = _pageVariants.map(_issueKey).toSet();
    final allSelected = _issues.containsAll(keys);
    setState(
      () => allSelected ? _issues.removeAll(keys) : _issues.addAll(keys),
    );
    unawaited(_persistIssues());
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
    final item = _page < _auditCatalog.length ? _auditCatalog[_page] : null;
    final title = _summaryPage
        ? 'Resultaten'
        : _dragonPage
        ? 'dragon_mode'
        : '${item!.id} (${item.category.name})';
    return Scaffold(
      appBar: AppBar(
        title: Text('${_page + 1}/$_totalPages $title'),
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
          if (!_summaryPage)
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 2, 8, 0),
              child: Text(
                'V14 eindcontrole: tik alleen als de reparatie nog niet goed is. '
                'Rood = geselecteerd. Totaal: ${_issues.length}',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          Expanded(
            child: _summaryPage
                ? _AuditSummary(issues: _issues, onCopy: _copyResults)
                : GridView.count(
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(6),
                    crossAxisCount: 3,
                    childAspectRatio: .76,
                    mainAxisSpacing: 3,
                    crossAxisSpacing: 3,
                    children: _pageVariants
                        .map(
                          (variant) => _PetAuditTile(
                            variant: variant,
                            item: item,
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
                    onPressed: _page == _totalPages - 1
                        ? _copyResults
                        : () => setState(() => _page++),
                    child: Text(
                      _page == _totalPages - 1 ? 'KOPIEER LIJST' : 'VOLGENDE',
                    ),
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

class _PetAuditTile extends StatelessWidget {
  const _PetAuditTile({
    required this.variant,
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final PetVariant variant;
  final CatShopItem? item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final equippedItem = item;
    final profile = CatProfile(
      name: variant.name,
      variant: variant,
      adoptedAt: DateTime(2026, 1, 1),
      feedCount: equippedItem == null ? 14 : 60,
      dragonMode: equippedItem == null,
      ownedAccessoryIds: equippedItem == null
          ? const <String>{}
          : <String>{equippedItem.id},
      equippedAccessories: equippedItem == null
          ? const <String, String>{}
          : <String, String>{equippedItem.category.name: equippedItem.id},
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
            title: Text(issue.replaceFirst('|', ' — ')),
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
