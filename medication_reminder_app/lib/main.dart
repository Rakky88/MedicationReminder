import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';

import 'app_localizations.dart';
import 'app_branding.dart';
import 'about_screen.dart';
import 'cat.dart';
import 'pet_audio.dart';
import 'cat_home_card.dart';
import 'cat_repository.dart';
import 'cat_screen.dart';
import 'cat_shop.dart';
import 'log_screen.dart';
import 'medication.dart';
import 'medication_form_screen.dart';
import 'medication_repository.dart';
import 'medication_streak.dart';
import 'medication_streak_repository.dart';
import 'notification_service.dart';
import 'pet_costumes.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('Unhandled application error: $error\n$stack');
    return true;
  };
  ErrorWidget.builder = (_) => const _SafeErrorView();
  String? languageCode;
  try {
    languageCode = await MedicationRepository.instance.getPreferredLocale();
  } on Object catch (error, stack) {
    debugPrint('Could not load the preferred locale: $error\n$stack');
  }
  try {
    await NotificationService().init();
  } on Object catch (error, stack) {
    // Notification setup is recoverable and must never make local medication
    // data or the rest of the app inaccessible.
    debugPrint('Notification startup failed: $error\n$stack');
  }
  runApp(
    MedicationReminderApp(initialLocale: appLocaleFromStoredCode(languageCode)),
  );
}

class _SafeErrorView extends StatelessWidget {
  const _SafeErrorView();

  @override
  Widget build(BuildContext context) {
    final languageCode = PlatformDispatcher.instance.locale.languageCode;
    final (title, body) = switch (languageCode) {
      'nl' => (
        'Er ging iets mis',
        'Sluit de app volledig en open hem opnieuw. Je opgeslagen voortgang blijft bewaard.',
      ),
      'de' => (
        'Etwas ist schiefgegangen',
        'Schließe die App vollständig und öffne sie erneut. Dein gespeicherter Fortschritt bleibt erhalten.',
      ),
      'fr' => (
        'Une erreur s’est produite',
        'Fermez complètement l’application, puis rouvrez-la. Votre progression enregistrée sera conservée.',
      ),
      'es' => (
        'Algo ha salido mal',
        'Cierra la app por completo y vuelve a abrirla. Tu progreso guardado se conservará.',
      ),
      _ => (
        'Something went wrong',
        'Close the app completely and open it again. Your saved progress remains stored.',
      ),
    };
    return Material(
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Icon(Icons.error_outline, size: 52),
                const SizedBox(height: 16),
                Text(title, style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 8),
                Text(body, textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MedicationReminderApp extends StatefulWidget {
  const MedicationReminderApp({super.key, this.initialLocale});

  final Locale? initialLocale;

  @override
  State<MedicationReminderApp> createState() => _MedicationReminderAppState();
}

class _MedicationReminderAppState extends State<MedicationReminderApp> {
  late Locale _locale = appLocaleFromStoredCode(
    widget.initialLocale?.languageCode,
  );

  Future<void> _setLocale(Locale locale) async {
    await MedicationRepository.instance.setPreferredLocale(locale.languageCode);
    if (!mounted) return;
    setState(() => _locale = locale);
    final medications = await MedicationRepository.instance.getMedications();
    final logs = await MedicationRepository.instance.getDoseLogs(
      includeHidden: true,
    );
    final cat = await CatRepository.instance.getProfile();
    try {
      await NotificationService().syncReminders(
        medications,
        _notificationCopy(locale.languageCode, cat),
        mascot: _mascot(cat),
        resolvedDoseKeys: logs
            .map((log) => log.doseKey)
            .whereType<String>()
            .toSet(),
      );
    } on Object catch (error, stack) {
      debugPrint('Could not update reminder language: $error\n$stack');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Medication Reminder',
      debugShowCheckedModeBanner: false,
      locale: _locale,
      supportedLocales: supportedAppLocales,
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        AppLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00796B),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        inputDecorationTheme: const InputDecorationTheme(filled: true),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4DB6AC),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: HomeScreen(onLocaleChanged: _setLocale),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.onLocaleChanged});

  final Future<void> Function(Locale) onLocaleChanged;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final _repository = MedicationRepository.instance;
  final _notifications = NotificationService();
  late Future<List<Medication>> _medications;
  StreamSubscription<NotificationActionEvent>? _actionSubscription;
  Timer? _catTimer;
  Timer? _activityTimer;
  CatProfile? _cat;
  List<DoseLog> _doseLogs = const <DoseLog>[];
  MedicationStreakState _medicationStreak = MedicationStreakState.empty;
  CatActivity _catActivity = CatActivity.normal;
  String? _lastMeowDoseKey;
  int? _highlightedMedicationId;
  String? _activePlayMomentKey;
  double _appBarScrollProgress = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _medications = _repository.getMedications();
    _actionSubscription = _notifications.actions.listen(
      (event) => unawaited(_handleNotificationActionSafely(event)),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_refreshAndSyncSilently(showDataError: true));
      final event = _notifications.takeInitialAction();
      if (event != null) unawaited(_handleNotificationActionSafely(event));
    });
    _catTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => unawaited(_refreshCatAndDueSilently()),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _actionSubscription?.cancel();
    _catTimer?.cancel();
    _activityTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_resumeSafely());
    }
  }

  Future<void> _resumeSafely() async {
    try {
      await _notifications.refreshTimeZone();
      if (mounted) await _refreshAndSyncSilently(showDataError: true);
    } on Object catch (error, stack) {
      debugPrint('Could not refresh after app resume: $error\n$stack');
    }
  }

  Future<void> _refreshAndSyncSilently({bool showDataError = false}) async {
    await _refreshCatAndDueSilently(showError: showDataError);
    if (mounted) await _syncReminders(showError: false);
  }

  Future<void> _refreshCatAndDueSilently({bool showError = false}) async {
    try {
      await _refreshCatAndDue();
    } on Object catch (error, stack) {
      debugPrint('Could not refresh medication and pet state: $error\n$stack');
      if (showError && mounted) {
        _showMessage(AppLocalizations.of(context).loadError);
      }
    }
  }

  Future<void> _refresh() async {
    final future = _repository.getMedications();
    if (mounted) {
      setState(() {
        _medications = future;
      });
    }
    final medications = await future;
    await _refreshCatAndDue(medications: medications);
  }

  NotificationCopy _copy(AppLocalizations loc) => NotificationCopy(
    title: loc.title,
    body: loc.reminderBody,
    languageCode: loc.locale.languageCode,
    openAction: loc.notificationOpen,
    snoozeAction: loc.notificationSnooze,
    catBody: _cat?.species == PetSpecies.cat
        ? loc.catNotificationBody(_cat?.name ?? '')
        : loc.reminderBody,
    followUpBody: loc.reminderFollowUpBody,
    escalatedBody: _cat?.species != PetSpecies.cat
        ? loc.reminderEscalatedNoCatBody
        : loc.reminderEscalatedBody,
  );

  NotificationMascot? get _catMascot => _mascot(_cat);

  Future<void> _refreshCatAndDue({List<Medication>? medications}) async {
    final currentMedications =
        medications ?? await _repository.getMedications();
    final logs = await _repository.reconcileMissedDoses(currentMedications);
    MedicationStreakState? medicationStreak;
    try {
      medicationStreak = await MedicationStreakRepository.instance.synchronize(
        medications: currentMedications,
        logs: logs,
      );
    } on Object catch (error, stack) {
      // Streak progress is derived data. A damaged streak record must not make
      // medication, history, reminders, or the pet unavailable.
      debugPrint('Could not refresh medication streak: $error\n$stack');
    }
    var profile = await CatRepository.instance.reconcileDoseLogs(logs);
    if (profile?.stage == CatStage.adult) {
      profile = await CatRepository.instance.ensurePlaySchedule();
    }
    if (!mounted) return;
    setState(() {
      _cat = profile;
      _doseLogs = logs;
      if (medicationStreak != null) _medicationStreak = medicationStreak;
      _activePlayMomentKey = profile == null
          ? null
          : CatRepository.currentPlayMomentKey(profile);
    });
    await _updateDueActivity(currentMedications, logs, profile);
  }

  Future<void> _updateDueActivity(
    List<Medication> medications,
    List<DoseLog> logs,
    CatProfile? profile,
  ) async {
    final now = DateTime.now();
    ({Medication medication, MedicationDoseSlot slot})? due;
    final candidates = <({Medication medication, MedicationDoseSlot slot})>[];
    for (final medication in medications.where((item) => item.enabled)) {
      final start =
          medication.createdAt?.isAfter(
                now.subtract(const Duration(days: 8)),
              ) ==
              true
          ? medication.createdAt!
          : now.subtract(const Duration(days: 8));
      for (final slot in medication.occurrencesBetween(start, now)) {
        candidates.add((medication: medication, slot: slot));
      }
    }
    candidates.sort((a, b) => b.slot.scheduledAt.compareTo(a.slot.scheduledAt));
    for (final candidate in candidates) {
      if (!logs.any((log) => log.doseKey == candidate.slot.key)) {
        due = candidate;
        break;
      }
    }
    if (!mounted) return;
    setState(() {
      if (due != null) {
        _highlightedMedicationId = due.medication.id;
      } else {
        _highlightedMedicationId = null;
      }
      if (profile != null && _catActivity != CatActivity.purring) {
        _catActivity = due == null ? CatActivity.normal : CatActivity.doseDue;
      }
    });
    if (due != null &&
        profile != null &&
        profile.hungrySoundEnabled &&
        due.slot.key != _lastMeowDoseKey) {
      _lastMeowDoseKey = due.slot.key;
      unawaited(PetAudio.instance.hungry(profile));
    }
  }

  Future<bool> _syncReminders({bool showError = true}) async {
    try {
      final medications = await _repository.getMedications();
      final logs = await _repository.getDoseLogs(includeHidden: true);
      if (!mounted) return false;
      await _notifications.syncReminders(
        medications,
        _copy(AppLocalizations.of(context)),
        mascot: _catMascot,
        resolvedDoseKeys: logs
            .map((log) => log.doseKey)
            .whereType<String>()
            .toSet(),
      );
      return true;
    } on Object catch (error, stack) {
      debugPrint('Could not synchronize reminders: $error\n$stack');
      if (showError && mounted) {
        _showMessage(AppLocalizations.of(context).notificationError);
      }
      return false;
    }
  }

  Future<void> _openMedicationForm([Medication? medication]) async {
    final result = await Navigator.of(context).push<Medication>(
      MaterialPageRoute<Medication>(
        builder: (_) => MedicationFormScreen(medication: medication),
      ),
    );
    if (result == null || !mounted) return;

    // Persist the form before Android can take the user to a system settings
    // screen. If the process is killed there, their changes are still safe and
    // startup reconciliation will schedule the enabled reminder later.
    var saved = await _repository.saveMedication(result);
    if (result.enabled) {
      final allowed = await _notifications.requestPermissions();
      if (!allowed) {
        saved = await _repository.saveMedication(
          saved.copyWith(enabled: false),
        );
        if (mounted) {
          _showMessage(AppLocalizations.of(context).notificationDenied);
        }
      }
    }
    await _refresh();
    await _syncReminders();
  }

  Future<void> _openCatScreen() async {
    final result = await Navigator.of(context).push<CatScreenResult>(
      MaterialPageRoute<CatScreenResult>(
        builder: (_) => CatScreen(profile: _cat),
      ),
    );
    if (!mounted) return;
    final persisted = await CatRepository.instance.getProfile();
    if (!mounted) return;
    setState(() {
      _cat = result?.removed == true ? null : persisted;
      _catActivity = CatActivity.normal;
    });
    await _syncReminders(showError: false);
    await _refreshCatAndDue();
  }

  Future<void> _openAbout() async {
    await Navigator.of(
      context,
    ).push<void>(MaterialPageRoute<void>(builder: (_) => const AboutScreen()));
    if (!mounted) return;
    await _refreshCatAndDue();
    await _syncReminders(showError: false);
  }

  Future<void> _interactWithCat() async {
    final cat = _cat;
    if (cat == null) return;
    if (_catActivity == CatActivity.doseDue || cat.hungerPoints > 0) {
      await PetAudio.instance.hungry(cat);
    } else {
      await PetAudio.instance.happy(cat);
    }
  }

  Future<void> _playWithCat() async {
    final key = _activePlayMomentKey;
    final cat = _cat;
    if (key == null || cat == null) return;
    final result = await CatRepository.instance.playWithCat(momentKey: key);
    if (!mounted || result?.rewarded != true) {
      if (mounted) setState(() => _activePlayMomentKey = null);
      return;
    }
    setState(() {
      _cat = result!.profile;
      _activePlayMomentKey = null;
      _catActivity = CatActivity.purring;
    });
    _activityTimer?.cancel();
    _activityTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) setState(() => _catActivity = CatActivity.normal);
    });
    unawaited(PetAudio.instance.happy(result!.profile));
    final loc = AppLocalizations.of(context);
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.pets, size: 42),
        title: Text(loc.catPlayedTitle),
        content: Text(loc.catPlayedBody(result.profile.name)),
        actions: <Widget>[
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleMedication(Medication medication, bool enabled) async {
    var nextEnabled = enabled;
    if (enabled && !await _notifications.requestPermissions()) {
      nextEnabled = false;
      if (mounted) {
        _showMessage(AppLocalizations.of(context).notificationDenied);
      }
    }
    await _repository.saveMedication(medication.copyWith(enabled: nextEnabled));
    await _refresh();
    await _syncReminders();
  }

  Future<void> _deleteMedication(Medication medication) async {
    final loc = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.deleteTitle),
        content: Text(loc.deleteBody),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(loc.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(loc.delete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _repository.deleteMedication(medication.id);
    await _refresh();
    await _syncReminders();
  }

  Future<void> _recordDose(
    Medication medication,
    DoseStatus status, {
    String? doseKey,
  }) async {
    final loc = AppLocalizations.of(context);
    final log = await _repository.recordDose(
      medication,
      status,
      doseKey: doseKey,
    );
    if (!mounted) return;
    if (log == null) {
      _showMessage(loc.duplicate);
      return;
    }
    CatDoseResult? catResult;
    MedicationStreakState? medicationStreak;
    try {
      final allMedications = await _repository.getMedications();
      catResult = await CatRepository.instance.applyDose(
        medication,
        log,
        allMedications: allMedications,
      );
    } on Object catch (error, stack) {
      // The canonical dose log is already safe. Pet reconciliation repairs its
      // derived state on the next refresh if this optional update fails.
      debugPrint('Could not update pet after dose: $error\n$stack');
    }
    try {
      final allMedications = await _repository.getMedications();
      final allLogs = await _repository.getDoseLogs(includeHidden: true);
      medicationStreak = await MedicationStreakRepository.instance.synchronize(
        medications: allMedications,
        logs: allLogs,
      );
    } on Object catch (error, stack) {
      debugPrint('Could not update medication streak: $error\n$stack');
    }
    try {
      if (log.doseKey case final doseKey?) {
        await _notifications.resolveDose(doseKey);
      } else {
        await _notifications.resolveMedication(medication.id);
      }
    } on Object catch (error, stack) {
      // The full reminder sync below also resolves this logged dose.
      debugPrint('Could not immediately resolve dose reminder: $error\n$stack');
    }
    if (!mounted) return;
    setState(() {
      _highlightedMedicationId = null;
      _doseLogs = <DoseLog>[log, ..._doseLogs];
      if (medicationStreak != null) _medicationStreak = medicationStreak;
    });
    final updatedCat = catResult;
    if (updatedCat != null) {
      setState(() {
        _cat = updatedCat.profile;
        _catActivity = updatedCat.fed
            ? CatActivity.purring
            : CatActivity.normal;
      });
      if (updatedCat.fed) {
        _activityTimer?.cancel();
        _activityTimer = Timer(const Duration(seconds: 5), () {
          if (mounted) setState(() => _catActivity = CatActivity.normal);
        });
        unawaited(PetAudio.instance.happy(updatedCat.profile));
      }
    }
    unawaited(_syncReminders(showError: false));
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          catResult?.fed == true
              ? '${catResult!.profile.species == PetSpecies.cat ? loc.catFed(catResult.profile.name) : loc.petFed(catResult.profile.name)}'
                    '${catResult.earnedHappyPoints > 0 ? '  ${loc.happyPointsEarned(_formatPoints(catResult.earnedHappyPoints))}' : ''}'
              : status == DoseStatus.taken
              ? loc.recorded
              : loc.skippedRecorded,
        ),
        action: SnackBarAction(
          label: loc.undo,
          onPressed: () => _startUserAction(() async {
            // Undo derived pet state first. If deleting the canonical log then
            // fails, normal reconciliation can safely add that reward back.
            final profile = await CatRepository.instance.undoDose(log);
            await _repository.deleteDoseLog(log.id);
            MedicationStreakState? medicationStreak;
            try {
              final allMedications = await _repository.getMedications();
              final allLogs = await _repository.getDoseLogs(
                includeHidden: true,
              );
              medicationStreak = await MedicationStreakRepository.instance
                  .synchronize(
                    medications: allMedications,
                    logs: allLogs,
                    invalidatedDays: <String>{
                      medicationStreakDayKey(log.scheduledAt),
                    },
                  );
            } on Object catch (error, stack) {
              debugPrint(
                'Could not update medication streak after undo: '
                '$error\n$stack',
              );
            }
            if (!mounted) return;
            setState(() {
              _cat = profile;
              _catActivity = CatActivity.normal;
              _doseLogs = _doseLogs.where((item) => item.id != log.id).toList();
              if (medicationStreak != null) {
                _medicationStreak = medicationStreak;
              }
            });
            await _syncReminders(showError: false);
          }),
        ),
      ),
    );
  }

  Future<void> _confirmDoseMissed(
    Medication medication, {
    String? doseKey,
  }) async {
    final loc = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(
          Icons.cancel_outlined,
          color: Theme.of(context).colorScheme.error,
        ),
        title: Text(loc.missedConfirmTitle),
        content: Text(loc.missedConfirmBody),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(loc.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(loc.missedConfirmAction),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await _recordDose(medication, DoseStatus.skipped, doseKey: doseKey);
    }
  }

  Future<void> _snooze(Medication medication, {String? doseKey}) async {
    final loc = AppLocalizations.of(context);
    try {
      final snoozeCount = doseKey == null
          ? 0
          : await _notifications.snoozeEscalation(doseKey);
      if (snoozeCount < 0) {
        await _notifications.snoozeMedication(
          medication,
          _copy(loc),
          mascot: _catMascot,
          doseKey: doseKey,
        );
      }
      if (mounted) _showMessage(loc.snoozed);
    } on Object {
      if (mounted) _showMessage(loc.notificationError);
    }
  }

  Future<void> _handleNotificationAction(NotificationActionEvent event) async {
    final medications = await _repository.getMedications();
    final matches = medications.where((item) => item.id == event.medicationId);
    if (matches.isEmpty || !mounted) return;
    final medication = matches.first;
    if (event.actionId == NotificationService.snoozeAction) {
      await _snooze(medication, doseKey: event.doseKey);
    } else if (mounted) {
      setState(() {
        _highlightedMedicationId = medication.id;
        if (_cat != null) _catActivity = CatActivity.doseDue;
      });
    }
  }

  Future<void> _handleNotificationActionSafely(
    NotificationActionEvent event,
  ) async {
    try {
      await _handleNotificationAction(event);
    } on Object catch (error, stack) {
      debugPrint('Could not process notification action: $error\n$stack');
      if (mounted) _showMessage(AppLocalizations.of(context).loadError);
    }
  }

  Future<void> _testNotification() async {
    final loc = AppLocalizations.of(context);
    if (!_notifications.isSupported) {
      _showMessage(loc.unsupportedNotifications);
      return;
    }
    if (!await _notifications.requestPermissions()) {
      if (mounted) _showMessage(loc.notificationDenied);
      return;
    }
    try {
      await _notifications.showNotificationNow(
        copy: _copy(loc),
        mascot: _catMascot,
        previewSoundInApp: true,
      );
      if (_cat case final pet?) await PetAudio.instance.hungry(pet);
      if (mounted) _showMessage(loc.notificationSent);
    } on Object {
      if (mounted) _showMessage(loc.notificationError);
    }
  }

  Future<void> _changeLocale(String languageCode) async {
    try {
      await widget.onLocaleChanged(Locale(languageCode));
    } on Object catch (error, stack) {
      debugPrint('Could not change language: $error\n$stack');
      if (mounted) _showMessage(AppLocalizations.of(context).loadError);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _startUserAction(Future<void> Function() action) {
    unawaited(_runUserAction(action));
  }

  bool _handleHomeScroll(ScrollNotification notification) {
    if (notification.depth != 0 || notification.metrics.axis != Axis.vertical) {
      return false;
    }
    final linearProgress = (notification.metrics.pixels / 80)
        .clamp(0.0, 1.0)
        .toDouble();
    final progress = Curves.easeInOutCubic.transform(linearProgress);
    if ((progress - _appBarScrollProgress).abs() > 0.001 && mounted) {
      setState(() => _appBarScrollProgress = progress);
    }
    return false;
  }

  Future<void> _runUserAction(Future<void> Function() action) async {
    try {
      await action();
    } on Object catch (error, stack) {
      debugPrint('User action failed: $error\n$stack');
      if (mounted) _showMessage(AppLocalizations.of(context).loadError);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final appBarColor = ElevationOverlay.applySurfaceTint(
      theme.colorScheme.surface,
      theme.colorScheme.surfaceTint,
      3 * _appBarScrollProgress,
    );
    return Scaffold(
      appBar: AppBar(
        backgroundColor: appBarColor,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0.8 * _appBarScrollProgress,
        shadowColor: theme.shadowColor.withValues(
          alpha: 0.16 * _appBarScrollProgress,
        ),
        titleSpacing: 12,
        title: Row(
          children: <Widget>[
            AppLogoMark(
              size: 38,
              imageKey: const Key('home-brand-logo'),
              semanticLabel: loc.title,
            ),
            const SizedBox(width: 9),
            Expanded(
              child: FittedBox(
                alignment: Alignment.centerLeft,
                fit: BoxFit.scaleDown,
                child: AppWordmark(
                  title: loc.title,
                  textKey: const Key('home-brand-title'),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.7,
                    height: 1,
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: <Widget>[
          IconButton(
            onPressed: () => _startUserAction(_openAbout),
            tooltip: loc.aboutApp,
            icon: const Icon(Icons.info_outline),
          ),
          IconButton(
            tooltip: loc.history,
            icon: const Icon(Icons.history),
            onPressed: () => Navigator.of(context).push<void>(
              MaterialPageRoute<void>(builder: (_) => const LogScreen()),
            ),
          ),
          PopupMenuButton<String>(
            tooltip: loc.language,
            onSelected: (value) {
              if (value == 'test') {
                unawaited(_testNotification());
              } else {
                unawaited(_changeLocale(value));
              }
            },
            itemBuilder: (_) => <PopupMenuEntry<String>>[
              const PopupMenuItem(value: 'en', child: Text('English')),
              const PopupMenuItem(value: 'nl', child: Text('Nederlands')),
              const PopupMenuItem(value: 'de', child: Text('Deutsch')),
              const PopupMenuItem(value: 'fr', child: Text('Français')),
              const PopupMenuItem(value: 'es', child: Text('Español')),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'test',
                child: Row(
                  children: <Widget>[
                    const Icon(Icons.notifications_active_outlined),
                    const SizedBox(width: 12),
                    Text(loc.testNotification),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: FutureBuilder<List<Medication>>(
        future: _medications,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _HomeError(onRetry: _refresh);
          }
          final medications = snapshot.data ?? const <Medication>[];
          return NotificationListener<ScrollNotification>(
            onNotification: _handleHomeScroll,
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                children: <Widget>[
                  if (_cat == null)
                    CatAdoptionCard(
                      onAdopt: () => _startUserAction(_openCatScreen),
                    )
                  else
                    CatHomeCard(
                      profile: _cat!,
                      activity: _catActivity,
                      currentMedicationStreak: _medicationStreak.current,
                      bestMedicationStreak: _medicationStreak.best,
                      onTap: () => _startUserAction(_interactWithCat),
                      onSettings: () => _startUserAction(_openCatScreen),
                    ),
                  const SizedBox(height: 12),
                  if (medications.isEmpty)
                    _EmptyState(
                      onAdd: () => _startUserAction(_openMedicationForm),
                    )
                  else ...<Widget>[
                    _NextReminderCard(medications: medications),
                    const SizedBox(height: 12),
                    for (final medication in medications)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _MedicationCard(
                          medication: medication,
                          highlighted:
                              medication.id == _highlightedMedicationId,
                          onEdit: () => _startUserAction(
                            () => _openMedicationForm(medication),
                          ),
                          onDelete: () => _startUserAction(
                            () => _deleteMedication(medication),
                          ),
                          onToggle: (value) => _startUserAction(
                            () => _toggleMedication(medication, value),
                          ),
                          doseActions: _doseActionsFor(medication),
                          onTaken: (action) => _startUserAction(
                            () => _recordDose(
                              medication,
                              DoseStatus.taken,
                              doseKey: action.slot.key,
                            ),
                          ),
                          onSkipped: (action) => _startUserAction(
                            () => _confirmDoseMissed(
                              medication,
                              doseKey: action.slot.key,
                            ),
                          ),
                          onSnooze: (action) => _startUserAction(
                            () => _snooze(medication, doseKey: action.slot.key),
                          ),
                        ),
                      ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          if (_activePlayMomentKey != null && _cat != null) ...<Widget>[
            _PulsingPlayAction(
              label: loc.catWantsToPlay,
              tooltip: loc.catPlayTooltip(_cat!.name),
              onPressed: () => _startUserAction(_playWithCat),
            ),
            const SizedBox(height: 12),
          ],
          FloatingActionButton.extended(
            heroTag: 'add-medication',
            onPressed: () => _startUserAction(_openMedicationForm),
            icon: const Icon(Icons.add),
            label: Text(loc.addMedication),
          ),
        ],
      ),
    );
  }

  List<MedicationDoseAction> _doseActionsFor(Medication medication) {
    return medication.actionableDoseSlots(
      now: DateTime.now(),
      completedKeys: _doseLogs
          .map((log) => log.doseKey)
          .whereType<String>()
          .toSet(),
    );
  }
}

class _PulsingPlayAction extends StatefulWidget {
  const _PulsingPlayAction({
    required this.label,
    required this.tooltip,
    required this.onPressed,
  });

  final String label;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  State<_PulsingPlayAction> createState() => _PulsingPlayActionState();
}

class _PulsingPlayActionState extends State<_PulsingPlayAction>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  )..repeat(reverse: true);
  late final Animation<double> _scale = Tween<double>(
    begin: .94,
    end: 1.07,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Material(
          color: colors.tertiaryContainer,
          elevation: 5,
          borderRadius: BorderRadius.circular(999),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Text(
              widget.label,
              style: TextStyle(
                color: colors.onTertiaryContainer,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        ScaleTransition(
          scale: _scale,
          child: FloatingActionButton.large(
            heroTag: 'cat-play',
            tooltip: widget.tooltip,
            backgroundColor: colors.tertiary,
            foregroundColor: colors.onTertiary,
            onPressed: widget.onPressed,
            child: const Stack(
              alignment: Alignment.center,
              children: <Widget>[
                Icon(Icons.sports_esports, size: 38),
                Positioned(right: 0, top: 0, child: Icon(Icons.pets, size: 18)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _NextReminderCard extends StatelessWidget {
  const _NextReminderCard({required this.medications});

  final List<Medication> medications;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    Medication? nextMedication;
    DateTime? nextDate;
    for (final medication in medications) {
      final candidate = medication.nextOccurrence();
      if (candidate != null &&
          (nextDate == null || candidate.isBefore(nextDate))) {
        nextMedication = medication;
        nextDate = candidate;
      }
    }
    final locale = Localizations.localeOf(context).toLanguageTag();
    return Card.filled(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: <Widget>[
            const Icon(Icons.alarm, size: 34),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    loc.nextDose,
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 4),
                  if (nextMedication == null || nextDate == null)
                    Text(loc.noUpcoming)
                  else ...<Widget>[
                    Text(
                      nextMedication.name,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Text(DateFormat.MMMEd(locale).add_Hm().format(nextDate)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MedicationCard extends StatelessWidget {
  const _MedicationCard({
    required this.medication,
    required this.onEdit,
    required this.onDelete,
    required this.onToggle,
    required this.onTaken,
    required this.onSkipped,
    required this.onSnooze,
    required this.doseActions,
    this.highlighted = false,
  });

  final Medication medication;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ValueChanged<bool> onToggle;
  final ValueChanged<MedicationDoseAction> onTaken;
  final ValueChanged<MedicationDoseAction> onSkipped;
  final ValueChanged<MedicationDoseAction> onSnooze;
  final List<MedicationDoseAction> doseActions;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final material = MaterialLocalizations.of(context);
    final timeLabels = medication.times
        .map((value) {
          final parts = value.split(':');
          return material.formatTimeOfDay(
            TimeOfDay(
              hour: int.tryParse(parts.first) ?? 0,
              minute: parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0,
            ),
          );
        })
        .join(' · ');
    final days = medication.weekdays.length == 7
        ? loc.allDays
        : medication.weekdays.map(loc.weekdayShort).join(', ');

    return Card(
      color: highlighted
          ? Theme.of(context).colorScheme.primaryContainer
          : null,
      shape: highlighted
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: Theme.of(context).colorScheme.primary,
                width: 2,
              ),
            )
          : null,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 12, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        medication.name,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      if (medication.dosage.isNotEmpty) Text(medication.dosage),
                    ],
                  ),
                ),
                Switch(value: medication.enabled, onChanged: onToggle),
                PopupMenuButton<String>(
                  onSelected: (value) =>
                      value == 'edit' ? onEdit() : onDelete(),
                  itemBuilder: (_) => <PopupMenuEntry<String>>[
                    PopupMenuItem(value: 'edit', child: Text(loc.edit)),
                    PopupMenuItem(value: 'delete', child: Text(loc.delete)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                const Icon(Icons.schedule, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text(timeLabels)),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: <Widget>[
                const Icon(Icons.calendar_today_outlined, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text(days)),
              ],
            ),
            for (final action in doseActions) ...<Widget>[
              const SizedBox(height: 16),
              _DoseActionBlock(
                action: action,
                onTaken: () => onTaken(action),
                onSkipped: () => onSkipped(action),
                onSnooze: () => onSnooze(action),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DoseActionBlock extends StatelessWidget {
  const _DoseActionBlock({
    required this.action,
    required this.onTaken,
    required this.onSkipped,
    required this.onSnooze,
  });

  final MedicationDoseAction action;
  final VoidCallback onTaken;
  final VoidCallback onSkipped;
  final VoidCallback onSnooze;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final time = MaterialLocalizations.of(
      context,
    ).formatTimeOfDay(TimeOfDay.fromDateTime(action.slot.scheduledAt));
    final label = action.isEarly ? loc.earlyDoseAt(time) : loc.doseDueAt(time);
    final error = Theme.of(context).colorScheme.error;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.primaryContainer.withValues(alpha: .7),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(label, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            Row(
              children: <Widget>[
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(56),
                    ),
                    onPressed: onTaken,
                    icon: const Icon(Icons.check_circle_outline),
                    label: Text(loc.taken, textAlign: TextAlign.center),
                  ),
                ),
                if (!action.isEarly) ...<Widget>[
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: error,
                        foregroundColor: Theme.of(context).colorScheme.onError,
                        minimumSize: const Size.fromHeight(56),
                      ),
                      onPressed: onSkipped,
                      icon: const Icon(Icons.cancel_outlined),
                      label: Text(
                        loc.skipped,
                        maxLines: 2,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            if (!action.isEarly) ...<Widget>[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: onSnooze,
                icon: const Icon(Icons.snooze),
                label: Text(loc.snooze),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.medication_outlined,
              size: 88,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 20),
            Text(
              loc.emptyTitle,
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(loc.emptyBody, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: Text(loc.addFirst),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeError extends StatelessWidget {
  const _HomeError({required this.onRetry});

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
            Text(loc.loadError, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: onRetry, child: Text(loc.retry)),
          ],
        ),
      ),
    );
  }
}

NotificationCopy _notificationCopy(String languageCode, [CatProfile? pet]) {
  final locale = appLocaleFromStoredCode(languageCode);
  final loc = AppLocalizations(locale);
  final hasCat = pet?.species == PetSpecies.cat;
  return NotificationCopy(
    title: loc.title,
    body: loc.reminderBody,
    languageCode: locale.languageCode,
    openAction: loc.notificationOpen,
    snoozeAction: loc.notificationSnooze,
    catBody: hasCat ? loc.catNotificationBody(pet!.name) : loc.reminderBody,
    followUpBody: loc.reminderFollowUpBody,
    escalatedBody: hasCat
        ? loc.reminderEscalatedBody
        : loc.reminderEscalatedNoCatBody,
  );
}

NotificationMascot? _mascot(CatProfile? cat) => cat == null
    ? null
    : NotificationMascot(
        name: cat.name,
        assetPath: showsDragonModeCostume(cat)
            ? dragonModeFittedAssetPath(cat.variant)
            : petBodyAssetPath(cat),
        soundEnabled: cat.hungrySoundEnabled,
        persistentMeowEnabled: cat.persistentMeowEnabled,
        species: cat.species,
        hungerPoints: cat.hungerPoints,
        accessories: <NotificationMascotAccessory>[
          ...equippedPetOverlayItems(cat).map((item) {
            final transform = item.adaptiveTransform(cat.variant);
            return NotificationMascotAccessory(
              path: item.fittedAssetPath(cat.variant),
              scale: transform.scale,
              scaleX: transform.scaleX,
              scaleY: transform.scaleY,
              dx: transform.dx,
              dy: transform.dy,
              isToy: item.category == CatAccessoryCategory.toy,
            );
          }),
        ],
      );

String _formatPoints(double value) => value == value.roundToDouble()
    ? value.toInt().toString()
    : value.toStringAsFixed(1);
