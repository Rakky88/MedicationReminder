import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'adherence_chart_screen.dart';
import 'app_localizations.dart';
import 'medication.dart';
import 'medication_repository.dart';

class LogScreen extends StatefulWidget {
  const LogScreen({super.key});

  @override
  State<LogScreen> createState() => _LogScreenState();
}

class _LogScreenState extends State<LogScreen> {
  late Future<List<DoseLog>> _logs;
  bool _clearing = false;

  @override
  void initState() {
    super.initState();
    _logs = MedicationRepository.instance.getDoseLogs();
  }

  Future<void> _refresh() async {
    final future = MedicationRepository.instance.getDoseLogs();
    if (mounted) setState(() => _logs = future);
    await future;
  }

  Future<void> _openGraph() async {
    try {
      final logs = await MedicationRepository.instance.getDoseLogs();
      if (!mounted) return;
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => AdherenceChartScreen(logs: logs),
        ),
      );
    } on Object {
      if (mounted) _showError();
    }
  }

  Future<void> _confirmClear() async {
    final loc = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.clearTitle),
        content: Text(loc.clearBody),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(loc.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(loc.clear),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _clearing = true);
    try {
      await MedicationRepository.instance.clearDoseLogs();
      await _refresh();
    } on Object {
      if (mounted) _showError();
    } finally {
      if (mounted) setState(() => _clearing = false);
    }
  }

  void _showError() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).loadError)),
      );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.history),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.bar_chart_outlined),
            onPressed: _openGraph,
            tooltip: loc.historyGraph,
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            onPressed: _clearing ? null : _confirmClear,
            tooltip: loc.clearHistory,
          ),
        ],
      ),
      body: FutureBuilder<List<DoseLog>>(
        future: _logs,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _ErrorView(message: loc.loadError, onRetry: _refresh);
          }
          final logs = snapshot.data ?? const <DoseLog>[];
          if (logs.isEmpty) return _EmptyHistory(onRefresh: _refresh);

          final groups = _groupByDay(logs);
          final entries = groups.entries.toList()
            ..sort((a, b) => b.key.compareTo(a.key));
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
              itemCount: entries.length,
              itemBuilder: (context, index) => _DayCard(
                day: entries[index].key,
                logs: entries[index].value,
                onDeleted: _refresh,
              ),
            ),
          );
        },
      ),
    );
  }
}

Map<DateTime, List<DoseLog>> _groupByDay(List<DoseLog> logs) {
  final groups = <DateTime, List<DoseLog>>{};
  for (final log in logs) {
    final time = log.scheduledAt;
    final day = DateTime(time.year, time.month, time.day);
    groups.putIfAbsent(day, () => <DoseLog>[]).add(log);
  }
  for (final values in groups.values) {
    values.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
  }
  return groups;
}

class _DayCard extends StatelessWidget {
  const _DayCard({
    required this.day,
    required this.logs,
    required this.onDeleted,
  });

  final DateTime day;
  final List<DoseLog> logs;
  final Future<void> Function() onDeleted;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final takenCount = logs
        .where((log) => log.status == DoseStatus.taken)
        .length;
    final missedCount = logs.length - takenCount;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  DateFormat.yMMMMEEEEd(locale).format(day),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: <Widget>[
                    _StatusChip(
                      color: Colors.green.shade700,
                      icon: Icons.check_circle,
                      label: loc.takenCount(takenCount),
                    ),
                    _StatusChip(
                      color: Theme.of(context).colorScheme.error,
                      icon: Icons.cancel,
                      label: loc.missedCount(missedCount),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ...logs.map((log) => _DoseLogTile(log: log, onDeleted: onDeleted)),
        ],
      ),
    );
  }
}

class _DoseLogTile extends StatelessWidget {
  const _DoseLogTile({required this.log, required this.onDeleted});

  final DoseLog log;
  final Future<void> Function() onDeleted;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final taken = log.status == DoseStatus.taken;
    final color = taken
        ? Colors.green.shade700
        : Theme.of(context).colorScheme.error;
    final time = DateFormat.Hm(
      Localizations.localeOf(context).toLanguageTag(),
    ).format(log.scheduledAt);
    return Dismissible(
      key: ValueKey(log.id),
      direction: DismissDirection.endToStart,
      background: ColoredBox(
        color: Theme.of(context).colorScheme.errorContainer,
        child: const Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: EdgeInsets.only(right: 24),
            child: Icon(Icons.delete_outline),
          ),
        ),
      ),
      confirmDismiss: (_) async {
        try {
          await MedicationRepository.instance.hideDoseLog(log.id);
          return true;
        } on Object {
          if (context.mounted) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(content: Text(loc.loadError)));
          }
          return false;
        }
      },
      onDismissed: (_) async {
        try {
          await onDeleted();
        } on Object {
          if (context.mounted) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(content: Text(loc.loadError)));
          }
        }
      },
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.12),
          foregroundColor: color,
          child: Icon(taken ? Icons.check : Icons.close),
        ),
        title: Text(log.medicationName),
        subtitle: Text(
          <String>[
            if (log.dosage.isNotEmpty) log.dosage,
            loc.scheduledAt(time),
          ].join(' · '),
        ),
        trailing: Text(
          taken ? loc.taken : loc.skipped,
          style: TextStyle(color: color, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.color,
    required this.icon,
    required this.label,
  });

  final Color color;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(color: color, fontWeight: FontWeight.w600),
        ),
      ],
    ),
  );
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory({required this.onRefresh});

  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: <Widget>[
          const SizedBox(height: 180),
          Icon(
            Icons.history,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 12),
          Center(child: Text(loc.noEntries)),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: onRetry, child: Text(loc.retry)),
          ],
        ),
      ),
    );
  }
}
