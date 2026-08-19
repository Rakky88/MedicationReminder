import 'package:flutter/material.dart';

import 'app_localizations.dart';
import 'gradual_app_bar.dart';
import 'medication.dart';

class MedicationFormScreen extends StatefulWidget {
  const MedicationFormScreen({super.key, this.medication});

  final Medication? medication;

  @override
  State<MedicationFormScreen> createState() => _MedicationFormScreenState();
}

class _MedicationFormScreenState extends State<MedicationFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _dosageController;
  late List<String> _times;
  late Set<int> _weekdays;
  late bool _enabled;
  late bool _notificationsOnly;
  late bool _showNameInNotifications;
  late Set<String> _allowBeforeDueTimes;

  @override
  void initState() {
    super.initState();
    final medication = widget.medication;
    _nameController = TextEditingController(text: medication?.name ?? '');
    _dosageController = TextEditingController(text: medication?.dosage ?? '');
    _times = List<String>.from(medication?.times ?? const <String>['08:00']);
    _weekdays = Set<int>.from(
      medication?.weekdays ??
          const <int>[
            DateTime.monday,
            DateTime.tuesday,
            DateTime.wednesday,
            DateTime.thursday,
            DateTime.friday,
            DateTime.saturday,
            DateTime.sunday,
          ],
    );
    _enabled = medication?.enabled ?? true;
    _notificationsOnly = medication?.notificationsOnly ?? false;
    _showNameInNotifications = medication?.showNameInNotifications ?? false;
    _allowBeforeDueTimes = Set<String>.from(
      medication?.allowBeforeDueTimes ?? const <String>{},
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    super.dispose();
  }

  Future<void> _addTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 8, minute: 0),
    );
    if (picked == null || !mounted) return;
    final value = _encodeTime(picked);
    if (_times.contains(value)) return;
    setState(() {
      _times.add(value);
      _times.sort();
    });
  }

  Future<void> _editTime(String currentValue) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _decodeTime(currentValue),
    );
    if (picked == null || !mounted) return;
    final newValue = _encodeTime(picked);
    if (newValue == currentValue || _times.contains(newValue)) return;

    setState(() {
      final allowBeforeDue = _allowBeforeDueTimes.remove(currentValue);
      final index = _times.indexOf(currentValue);
      if (index < 0) return;
      _times[index] = newValue;
      _times.sort();
      if (allowBeforeDue) _allowBeforeDueTimes.add(newValue);
    });
  }

  void _save() {
    final loc = AppLocalizations.of(context);
    if (!_formKey.currentState!.validate()) return;
    if (_times.isEmpty) {
      _showValidation(loc.timeRequired);
      return;
    }
    if (_weekdays.isEmpty) {
      _showValidation(loc.dayRequired);
      return;
    }
    Navigator.of(context).pop(
      Medication(
        id: widget.medication?.id ?? 0,
        name: _nameController.text.trim(),
        dosage: _dosageController.text.trim(),
        times: List<String>.from(_times)..sort(),
        weekdays: _weekdays.toList()..sort(),
        enabled: _enabled,
        notificationsOnly: _notificationsOnly,
        showNameInNotifications: _showNameInNotifications,
        allowBeforeDueTimes: _allowBeforeDueTimes,
        createdAt: widget.medication?.createdAt,
        scheduleStartedAt:
            widget.medication?.scheduleStartedAt ?? const <String, DateTime>{},
      ),
    );
  }

  void _showValidation(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _encodeTime(TimeOfDay time) =>
      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

  TimeOfDay _decodeTime(String value) {
    final parts = value.split(':');
    return TimeOfDay(
      hour: int.tryParse(parts.first) ?? 0,
      minute: parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0,
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      appBar: GradualAppBar(
        title: Text(
          widget.medication == null ? loc.addMedication : loc.editMedication,
        ),
        actions: <Widget>[TextButton(onPressed: _save, child: Text(loc.save))],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: <Widget>[
              TextFormField(
                controller: _nameController,
                autofocus: widget.medication == null,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: loc.name,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.medication_outlined),
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? loc.nameRequired
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _dosageController,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: loc.dosage,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.notes_outlined),
                ),
              ),
              const SizedBox(height: 24),
              Text(loc.times, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              for (final value in _times)
                Card.outlined(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
                    child: Row(
                      children: <Widget>[
                        const Icon(Icons.schedule, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                MaterialLocalizations.of(
                                  context,
                                ).formatTimeOfDay(_decodeTime(value)),
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              Text(
                                loc.allowEarlyDose,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        Switch.adaptive(
                          value: _allowBeforeDueTimes.contains(value),
                          onChanged: (enabled) => setState(() {
                            if (enabled) {
                              _allowBeforeDueTimes.add(value);
                            } else {
                              _allowBeforeDueTimes.remove(value);
                            }
                          }),
                        ),
                        IconButton(
                          key: ValueKey<String>('edit-time-$value'),
                          tooltip: loc.edit,
                          onPressed: () => _editTime(value),
                          icon: const Icon(Icons.edit_outlined),
                        ),
                        IconButton(
                          tooltip: loc.delete,
                          onPressed: () => setState(() {
                            _times.remove(value);
                            _allowBeforeDueTimes.remove(value);
                          }),
                          icon: const Icon(Icons.delete_outline),
                        ),
                      ],
                    ),
                  ),
                ),
              Align(
                alignment: Alignment.centerLeft,
                child: ActionChip(
                  avatar: const Icon(Icons.add, size: 18),
                  label: Text(loc.addTime),
                  onPressed: _addTime,
                ),
              ),
              const SizedBox(height: 24),
              Text(loc.days, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: <Widget>[
                  for (var day = DateTime.monday; day <= DateTime.sunday; day++)
                    FilterChip(
                      label: Text(loc.weekdayShort(day)),
                      selected: _weekdays.contains(day),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _weekdays.add(day);
                          } else {
                            _weekdays.remove(day);
                          }
                        });
                      },
                    ),
                ],
              ),
              const SizedBox(height: 16),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: Text(loc.notificationsOnly),
                value: _notificationsOnly,
                onChanged: (value) =>
                    setState(() => _notificationsOnly = value),
              ),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: Text(loc.showMedicationName),
                secondary: Icon(
                  _showNameInNotifications
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
                value: _showNameInNotifications,
                onChanged: (value) =>
                    setState(() => _showNameInNotifications = value),
              ),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save_outlined),
                label: Text(loc.save),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
