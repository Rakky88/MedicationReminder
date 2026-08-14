import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'app_localizations.dart';
import 'medication.dart';

enum AdherencePeriod { week, month, year, all }

class AdherenceChartScreen extends StatefulWidget {
  const AdherenceChartScreen({required this.logs, super.key});

  final List<DoseLog> logs;

  @override
  State<AdherenceChartScreen> createState() => _AdherenceChartScreenState();
}

class _AdherenceChartScreenState extends State<AdherenceChartScreen> {
  AdherencePeriod _period = AdherencePeriod.week;
  DateTime _reference = DateTime.now();

  void _move(int direction) {
    setState(() {
      _reference = switch (_period) {
        AdherencePeriod.week => _reference.add(Duration(days: 7 * direction)),
        AdherencePeriod.month => DateTime(
          _reference.year,
          _reference.month + direction,
          1,
        ),
        AdherencePeriod.year => DateTime(_reference.year + direction, 1, 1),
        AdherencePeriod.all => _reference,
      };
    });
  }

  Future<void> _selectReference() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _reference,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 366)),
    );
    if (selected != null && mounted) setState(() => _reference = selected);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final data = buildAdherenceBuckets(
      widget.logs,
      _period,
      _reference,
      locale: locale,
    );
    final taken = data.fold<int>(0, (total, item) => total + item.taken);
    final missed = data.fold<int>(0, (total, item) => total + item.missed);
    final total = taken + missed;
    final percentage = total == 0 ? 0 : (taken * 100 / total).round();

    return Scaffold(
      appBar: AppBar(title: Text(loc.historyGraph)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          SegmentedButton<AdherencePeriod>(
            showSelectedIcon: false,
            segments: <ButtonSegment<AdherencePeriod>>[
              ButtonSegment(
                value: AdherencePeriod.week,
                label: Text(loc.periodWeek),
              ),
              ButtonSegment(
                value: AdherencePeriod.month,
                label: Text(loc.periodMonth),
              ),
              ButtonSegment(
                value: AdherencePeriod.year,
                label: Text(loc.periodYear),
              ),
              ButtonSegment(
                value: AdherencePeriod.all,
                label: Text(loc.periodAll),
              ),
            ],
            selected: <AdherencePeriod>{_period},
            onSelectionChanged: (selection) {
              setState(() => _period = selection.single);
            },
          ),
          const SizedBox(height: 16),
          if (_period != AdherencePeriod.all)
            Row(
              children: <Widget>[
                IconButton(
                  onPressed: () => _move(-1),
                  tooltip: loc.previousPeriod,
                  icon: const Icon(Icons.chevron_left),
                ),
                Expanded(
                  child: TextButton.icon(
                    onPressed: _selectReference,
                    icon: const Icon(Icons.calendar_month_outlined),
                    label: Text(
                      _periodTitle(_period, _reference, locale),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => _move(1),
                  tooltip: loc.nextPeriod,
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Wrap(
                alignment: WrapAlignment.spaceAround,
                runSpacing: 12,
                spacing: 20,
                children: <Widget>[
                  _SummaryValue(
                    color: Colors.green.shade700,
                    value: loc.takenCount(taken),
                    icon: Icons.check_circle,
                  ),
                  _SummaryValue(
                    color: Theme.of(context).colorScheme.error,
                    value: loc.missedCount(missed),
                    icon: Icons.cancel,
                  ),
                  _SummaryValue(
                    color: Theme.of(context).colorScheme.primary,
                    value: loc.adherence(percentage.toString()),
                    icon: Icons.show_chart,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (total == 0)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 80),
              child: Column(
                children: <Widget>[
                  Icon(
                    Icons.bar_chart_outlined,
                    size: 64,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(height: 12),
                  Text(loc.noGraphData),
                ],
              ),
            )
          else
            _AdherenceBars(
              buckets: data,
              takenLabel: loc.taken,
              missedLabel: loc.skipped,
              takenCount: loc.takenCount,
              missedCount: loc.missedCount,
            ),
        ],
      ),
    );
  }
}

class AdherenceBucket {
  const AdherenceBucket({required this.label, this.taken = 0, this.missed = 0});

  final String label;
  final int taken;
  final int missed;
}

List<AdherenceBucket> buildAdherenceBuckets(
  List<DoseLog> logs,
  AdherencePeriod period,
  DateTime reference, {
  String? locale,
}) {
  final localReference = reference.toLocal();
  late DateTime start;
  late DateTime end;
  late List<DateTime> starts;
  late String Function(DateTime) label;

  switch (period) {
    case AdherencePeriod.week:
      final day = DateTime(
        localReference.year,
        localReference.month,
        localReference.day,
      );
      start = day.subtract(Duration(days: day.weekday - DateTime.monday));
      end = start.add(const Duration(days: 7));
      starts = List<DateTime>.generate(
        7,
        (index) => start.add(Duration(days: index)),
      );
      label = (value) => DateFormat.E(locale).format(value);
    case AdherencePeriod.month:
      start = DateTime(localReference.year, localReference.month, 1);
      end = DateTime(localReference.year, localReference.month + 1, 1);
      final days = end.difference(start).inDays;
      starts = List<DateTime>.generate(
        days,
        (index) => start.add(Duration(days: index)),
      );
      label = (value) => value.day.toString();
    case AdherencePeriod.year:
      start = DateTime(localReference.year, 1, 1);
      end = DateTime(localReference.year + 1, 1, 1);
      starts = List<DateTime>.generate(
        12,
        (index) => DateTime(localReference.year, index + 1, 1),
      );
      label = (value) => DateFormat.MMM(locale).format(value);
    case AdherencePeriod.all:
      final dated = logs.map((log) => log.scheduledAt).toList()..sort();
      if (dated.isEmpty) return const <AdherenceBucket>[];
      final firstYear = dated.first.year;
      final lastYear = dated.last.year;
      start = DateTime(firstYear, 1, 1);
      end = DateTime(lastYear + 1, 1, 1);
      starts = List<DateTime>.generate(
        lastYear - firstYear + 1,
        (index) => DateTime(firstYear + index, 1, 1),
      );
      label = (value) => value.year.toString();
  }

  final taken = List<int>.filled(starts.length, 0);
  final missed = List<int>.filled(starts.length, 0);
  for (final log in logs) {
    final time = log.scheduledAt;
    if (time.isBefore(start) || !time.isBefore(end)) continue;
    final index = switch (period) {
      AdherencePeriod.week || AdherencePeriod.month => DateTime(
        time.year,
        time.month,
        time.day,
      ).difference(start).inDays,
      AdherencePeriod.year => time.month - 1,
      AdherencePeriod.all => time.year - start.year,
    };
    if (index < 0 || index >= starts.length) continue;
    if (log.status == DoseStatus.taken) {
      taken[index]++;
    } else {
      missed[index]++;
    }
  }
  return List<AdherenceBucket>.generate(
    starts.length,
    (index) => AdherenceBucket(
      label: label(starts[index]),
      taken: taken[index],
      missed: missed[index],
    ),
  );
}

String _periodTitle(AdherencePeriod period, DateTime value, String locale) {
  return switch (period) {
    AdherencePeriod.week =>
      '${DateFormat.MMMd(locale).format(value.subtract(Duration(days: value.weekday - 1)))} – '
          '${DateFormat.MMMd(locale).format(value.add(Duration(days: 7 - value.weekday)))}',
    AdherencePeriod.month => DateFormat.yMMMM(locale).format(value),
    AdherencePeriod.year => value.year.toString(),
    AdherencePeriod.all => '',
  };
}

class _SummaryValue extends StatelessWidget {
  const _SummaryValue({
    required this.color,
    required this.value,
    required this.icon,
  });

  final Color color;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      Icon(icon, color: color),
      const SizedBox(width: 6),
      Text(
        value,
        style: TextStyle(color: color, fontWeight: FontWeight.w700),
      ),
    ],
  );
}

class _AdherenceBars extends StatelessWidget {
  const _AdherenceBars({
    required this.buckets,
    required this.takenLabel,
    required this.missedLabel,
    required this.takenCount,
    required this.missedCount,
  });

  final List<AdherenceBucket> buckets;
  final String takenLabel;
  final String missedLabel;
  final String Function(int) takenCount;
  final String Function(int) missedCount;

  @override
  Widget build(BuildContext context) {
    final maximum = buckets.fold<int>(
      1,
      (value, item) =>
          (item.taken + item.missed) > value ? item.taken + item.missed : value,
    );
    final error = Theme.of(context).colorScheme.error;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
        child: Column(
          children: <Widget>[
            Wrap(
              spacing: 20,
              children: <Widget>[
                _Legend(color: Colors.green.shade700, label: takenLabel),
                _Legend(color: error, label: missedLabel),
              ],
            ),
            const SizedBox(height: 20),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                height: 230,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: buckets.map((bucket) {
                    final total = bucket.taken + bucket.missed;
                    return SizedBox(
                      width: 48,
                      child: Column(
                        children: <Widget>[
                          Expanded(
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: Tooltip(
                                message:
                                    '${takenCount(bucket.taken)}\n${missedCount(bucket.missed)}',
                                child: Container(
                                  width: 27,
                                  height: total == 0
                                      ? 2
                                      : 174 * total / maximum,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(5),
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.surfaceContainerHighest,
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: total == 0
                                      ? null
                                      : Column(
                                          children: <Widget>[
                                            if (bucket.missed > 0)
                                              Expanded(
                                                flex: bucket.missed,
                                                child: ColoredBox(color: error),
                                              ),
                                            if (bucket.taken > 0)
                                              Expanded(
                                                flex: bucket.taken,
                                                child: ColoredBox(
                                                  color: Colors.green.shade700,
                                                ),
                                              ),
                                          ],
                                        ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            bucket.label,
                            maxLines: 1,
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(3),
        ),
      ),
      const SizedBox(width: 6),
      Text(label),
    ],
  );
}
