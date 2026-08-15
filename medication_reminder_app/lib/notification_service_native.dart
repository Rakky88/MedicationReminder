import 'dart:async';
import 'dart:convert';
import 'dart:io' show Directory, File, Platform;
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart' show Color;
import 'package:flutter/services.dart' show MethodChannel, rootBundle;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:path_provider/path_provider.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'async_operation_queue.dart';
import 'medication.dart';
import 'cat.dart';
import 'cat_notification_messages.dart';
import 'notification_models.dart';
import 'pet_sound_catalog.dart';
import 'time_zone_fallback.dart';

class NotificationService {
  NotificationService._internal();

  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() => _instance;

  static const openAction = 'open_app';
  static const snoozeAction = 'snooze';
  static const _categoryId = 'medication_reminder';
  static const _channelId = 'medication_reminders_v1';
  static const _androidRollingWeeks = 26;
  // Each dated dose uses one plugin alarm plus a follow-up and boundary alarm
  // in the native escalation layer. Keep enough room below Android's common
  // limit of 500 alarms per app for snoozes and OS bookkeeping.
  static const _maxAndroidScheduledDoseOccurrences = 144;
  static const _accents = <Color>[
    Color(0xFF00897B),
    Color(0xFF7B1FA2),
    Color(0xFFE65100),
    Color(0xFF1565C0),
    Color(0xFFC62828),
    Color(0xFF558B2F),
    Color(0xFFAD1457),
    Color(0xFF00695C),
    Color(0xFFF9A825),
    Color(0xFF283593),
    Color(0xFF9E9D24),
    Color(0xFFEF6C00),
    Color(0xFF6D4C41),
    Color(0xFF512DA8),
    Color(0xFF0277BD),
    Color(0xFFFF8F00),
    Color(0xFFD81B60),
    Color(0xFF2E7D32),
    Color(0xFF00838F),
    Color(0xFF4527A0),
    Color(0xFFF4511E),
    Color(0xFF3949AB),
    Color(0xFF00ACC1),
    Color(0xFF8E24AA),
  ];

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static const MethodChannel _escalationChannel = MethodChannel(
    'medication_reminder/escalation',
  );
  final math.Random _random = math.Random.secure();
  final StreamController<NotificationActionEvent> _actionController =
      StreamController<NotificationActionEvent>.broadcast();
  final AsyncOperationQueue _syncQueue = AsyncOperationQueue();

  NotificationActionEvent? _initialAction;
  _NotificationAppearance? _lastAppearance;
  int? _lastCatMessageIndex;
  int? _lastImmediateNotificationId;
  String? _lastImageSignature;
  _NotificationImages? _cachedNotificationImages;
  bool _initialized = false;

  bool get isSupported => Platform.isAndroid || Platform.isIOS;
  Stream<NotificationActionEvent> get actions => _actionController.stream;

  static DarwinNotificationCategory _darwinCategory({
    required String languageCode,
    required String openLabel,
    required String snoozeLabel,
  }) {
    final open = DarwinNotificationAction.plain(
      openAction,
      openLabel,
      options: <DarwinNotificationActionOption>{
        DarwinNotificationActionOption.foreground,
      },
    );
    final snooze = DarwinNotificationAction.plain(
      snoozeAction,
      snoozeLabel,
      options: <DarwinNotificationActionOption>{
        DarwinNotificationActionOption.foreground,
      },
    );
    return DarwinNotificationCategory(
      '${_categoryId}_${languageCode}_snooze_first',
      actions: <DarwinNotificationAction>[snooze, open],
    );
  }

  Future<void> init() async {
    if (!isSupported || _initialized) return;

    tz_data.initializeTimeZones();
    await refreshTimeZone();

    const android = AndroidInitializationSettings('ic_stat_medication');
    final darwin = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
      notificationCategories: <DarwinNotificationCategory>[
        _darwinCategory(
          languageCode: 'nl',
          openLabel: 'App openen',
          snoozeLabel: '10 min uitstellen',
        ),
        _darwinCategory(
          languageCode: 'en',
          openLabel: 'Open app',
          snoozeLabel: 'Snooze 10 min',
        ),
      ],
    );

    await _plugin.initialize(
      settings: InitializationSettings(android: android, iOS: darwin),
      onDidReceiveNotificationResponse: _handleResponse,
    );
    if (Platform.isAndroid) {
      _escalationChannel.setMethodCallHandler((call) async {
        if (call.method != 'notificationOpened') return;
        final arguments = Map<Object?, Object?>.from(
          call.arguments as Map<Object?, Object?>? ??
              const <Object?, Object?>{},
        );
        final medicationId = arguments['medicationId'];
        if (medicationId is! int) return;
        _actionController.add(
          NotificationActionEvent(
            medicationId: medicationId,
            actionId: openAction,
            doseKey: arguments['doseKey'] as String?,
          ),
        );
      });
      final launchAction = await _escalationChannel
          .invokeMapMethod<String, Object?>('takeLaunchAction');
      final medicationId = launchAction?['medicationId'];
      if (medicationId is int) {
        _initialAction = NotificationActionEvent(
          medicationId: medicationId,
          actionId: openAction,
          doseKey: launchAction?['doseKey'] as String?,
        );
      }
    }
    _initialized = true;

    final launchDetails = await _plugin.getNotificationAppLaunchDetails();
    final response = launchDetails?.notificationResponse;
    if (launchDetails?.didNotificationLaunchApp == true && response != null) {
      _initialAction ??= _eventFromResponse(response);
    }
  }

  Future<void> refreshTimeZone() async {
    if (!isSupported) return;
    try {
      final zone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(zone.identifier));
      return;
    } on Object {
      if (Platform.isAndroid) {
        try {
          final identifier = await _escalationChannel.invokeMethod<String>(
            'getLocalTimeZone',
          );
          if (identifier != null && identifier.isNotEmpty) {
            tz.setLocalLocation(tz.getLocation(identifier));
            return;
          }
        } on Object {
          // Use the device offset below if neither Android time-zone lookup works.
        }
      }
      final now = DateTime.now();
      tz.setLocalLocation(
        fixedOffsetTimeZoneLocation(
          offset: now.timeZoneOffset,
          abbreviation: now.timeZoneName,
        ),
      );
    }
  }

  Future<bool> requestPermissions() async {
    if (!isSupported) return false;
    await init();
    if (Platform.isAndroid) {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      final result = await android?.requestNotificationsPermission();
      if (result == false) return false;
      await android?.requestExactAlarmsPermission();
      return true;
    }
    final result = await _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
    return result ?? false;
  }

  Future<void> syncReminders(
    List<Medication> medications,
    NotificationCopy copy, {
    NotificationMascot? mascot,
    Set<String> resolvedDoseKeys = const <String>{},
  }) => _syncQueue.run(
    () => _syncRemindersNow(
      medications,
      copy,
      mascot: mascot,
      resolvedDoseKeys: resolvedDoseKeys,
    ),
  );

  Future<void> _syncRemindersNow(
    List<Medication> medications,
    NotificationCopy copy, {
    NotificationMascot? mascot,
    Set<String> resolvedDoseKeys = const <String>{},
  }) async {
    if (!isSupported) return;
    await init();
    try {
      await _clearPendingReminderPlans();
      await refreshTimeZone();
      final images = await _prepareNotificationImages(mascot);
      final slots = _reminderSlots(medications);
      if (Platform.isAndroid) {
        await _scheduleVariedAndroidReminders(
          slots,
          copy,
          mascot: mascot,
          images: images,
          resolvedDoseKeys: resolvedDoseKeys,
        );
      } else {
        await _scheduleRollingIosReminders(
          slots,
          copy,
          mascot: mascot,
          images: images,
          resolvedDoseKeys: resolvedDoseKeys,
        );
      }
    } on Object {
      // A platform can fail after only part of a schedule was accepted (for
      // example at a vendor alarm limit). Do not leave that partial schedule
      // active while the UI reports that scheduling failed.
      try {
        await _clearPendingReminderPlans();
      } on Object {
        // Preserve the original scheduling error for the caller.
      }
      rethrow;
    }
  }

  Future<void> _clearPendingReminderPlans() async {
    await _plugin.cancelAllPendingNotifications();
    if (Platform.isAndroid) {
      // Native follow-up alarms are separate from the notifications plugin.
      await _replaceEscalationPlans(
        const <Map<String, Object?>>[],
        const <int>[],
      );
    }
  }

  Future<void> snoozeMedication(
    Medication medication,
    NotificationCopy copy, {
    Duration delay = const Duration(minutes: 10),
    NotificationMascot? mascot,
    String? doseKey,
  }) async {
    if (!isSupported) return;
    await init();
    final images = await _prepareNotificationImages(mascot);
    final body = _notificationBody(copy, medication, mascot);
    final scheduleMode = await _androidScheduleMode();
    await _plugin.zonedSchedule(
      id: medication.id * 1000 + 999,
      title: copy.title,
      body: body,
      scheduledDate: tz.TZDateTime.now(tz.local).add(delay),
      notificationDetails: _details(
        copy,
        mascot: mascot,
        images: images,
        appearance: _newAppearance(),
        summaryText: body,
      ),
      androidScheduleMode: scheduleMode,
      payload: _payload(medication.id, doseKey),
    );
  }

  Future<void> showNotificationNow({
    required NotificationCopy copy,
    NotificationMascot? mascot,
    bool previewSoundInApp = false,
  }) async {
    if (!isSupported) return;
    await init();
    final images = await _prepareNotificationImages(mascot);
    final body = mascot == null ? copy.body : _newCatBody(copy, mascot);
    final previousId = _lastImmediateNotificationId;
    if (previousId != null) await _plugin.cancel(id: previousId);
    final notificationId = 900000000 + _random.nextInt(999999);
    _lastImmediateNotificationId = notificationId;
    await _plugin.show(
      id: notificationId,
      title: copy.title,
      body: body,
      notificationDetails: _details(
        copy,
        mascot: mascot,
        images: images,
        appearance: _newAppearance(),
        summaryText: body,
        allowMascotSound: !previewSoundInApp,
      ),
    );
  }

  NotificationActionEvent? takeInitialAction() {
    final event = _initialAction;
    _initialAction = null;
    return event;
  }

  Future<int> snoozeEscalation(String doseKey) async {
    if (!Platform.isAndroid) return -1;
    await init();
    return await _escalationChannel.invokeMethod<int>(
          'snoozeEscalation',
          <String, Object?>{'doseKey': doseKey},
        ) ??
        -1;
  }

  Future<void> resolveMedication(int medicationId) async {
    if (!Platform.isAndroid) return;
    await init();
    await _escalationChannel.invokeMethod<void>(
      'resolveMedication',
      <String, Object?>{'medicationId': medicationId},
    );
  }

  Future<void> resolveDose(String doseKey) async {
    if (!isSupported) return;
    await init();
    await _plugin.cancel(id: _doseNotificationId(doseKey));
    if (!Platform.isAndroid) return;
    await _escalationChannel.invokeMethod<void>(
      'resolveDose',
      <String, Object?>{'doseKey': doseKey},
    );
  }

  NotificationDetails _details(
    NotificationCopy copy, {
    NotificationMascot? mascot,
    _NotificationImages? images,
    required _NotificationAppearance appearance,
    String? summaryText,
    bool allowMascotSound = true,
  }) {
    final largeBitmap = images == null
        ? null
        : FilePathAndroidBitmap(images.transparentPath);
    final picturePath = images?.accentedPaths[appearance.accentIndex];
    final pictureBitmap = picturePath == null
        ? null
        : FilePathAndroidBitmap(picturePath);
    final accent = _accents[appearance.accentIndex];
    final hasMascotSound = allowMascotSound && mascot?.soundEnabled == true;
    final soundNames = _soundNamesFor(mascot?.species ?? PetSpecies.cat);
    final channelIds = _channelIdsFor(mascot?.species ?? PetSpecies.cat);
    final soundIndex = appearance.soundIndex % soundNames.length;
    final openButton = AndroidNotificationAction(
      openAction,
      copy.openAction,
      showsUserInterface: true,
    );
    final snoozeButton = AndroidNotificationAction(
      snoozeAction,
      copy.snoozeAction,
      showsUserInterface: true,
    );
    final dutch = copy.languageCode == 'nl';
    return NotificationDetails(
      android: AndroidNotificationDetails(
        hasMascotSound ? channelIds[soundIndex] : _channelId,
        hasMascotSound
            ? (dutch
                  ? 'Medicatieherinneringen met huisdier'
                  : 'Medication reminders with pet')
            : (dutch ? 'Medicatieherinneringen' : 'Medication reminders'),
        channelDescription: hasMascotSound
            ? (dutch
                  ? 'Herinneringen met het geluid van je geadopteerde huisdier'
                  : 'Reminders with the sound of your adopted pet')
            : (dutch
                  ? 'Herinneringen voor geplande medicatie'
                  : 'Reminders for scheduled medication'),
        importance: Importance.high,
        priority: Priority.high,
        category: AndroidNotificationCategory.reminder,
        visibility: NotificationVisibility.private,
        color: accent,
        colorized: true,
        largeIcon: largeBitmap,
        sound: hasMascotSound
            ? RawResourceAndroidNotificationSound(soundNames[soundIndex])
            : null,
        styleInformation: pictureBitmap == null
            ? null
            : BigPictureStyleInformation(
                pictureBitmap,
                largeIcon: largeBitmap,
                contentTitle: copy.title,
                summaryText:
                    summaryText ?? (mascot == null ? copy.body : copy.catBody),
                showBigPictureWhenCollapsed: true,
              ),
        actions: <AndroidNotificationAction>[snoozeButton, openButton],
      ),
      iOS: DarwinNotificationDetails(
        categoryIdentifier: '${_categoryId}_${copy.languageCode}_snooze_first',
        threadIdentifier: _categoryId,
        attachments: images == null
            ? null
            : <DarwinNotificationAttachment>[
                DarwinNotificationAttachment(images.transparentPath),
              ],
      ),
    );
  }

  List<String> _channelIdsFor(PetSpecies species) =>
      PetSoundCatalog.reminderChannelIds(species);

  List<String> _soundNamesFor(PetSpecies species) =>
      PetSoundCatalog.reminderSoundNames(species);

  List<_ReminderSlot> _reminderSlots(List<Medication> medications) {
    final slots = <_ReminderSlot>[];
    for (final medication in medications.where((item) => item.enabled)) {
      for (
        var timeIndex = 0;
        timeIndex < medication.times.length;
        timeIndex++
      ) {
        final parts = medication.times[timeIndex].split(':');
        if (parts.length != 2) continue;
        final hour = int.tryParse(parts[0]);
        final minute = int.tryParse(parts[1]);
        if (hour == null ||
            hour < 0 ||
            hour > 23 ||
            minute == null ||
            minute < 0 ||
            minute > 59) {
          continue;
        }
        for (final weekday in medication.weekdays) {
          if (weekday < DateTime.monday || weekday > DateTime.sunday) continue;
          slots.add(
            _ReminderSlot(
              medication: medication,
              weekday: weekday,
              hour: hour,
              minute: minute,
            ),
          );
        }
      }
    }
    return slots;
  }

  Future<void> _scheduleVariedAndroidReminders(
    List<_ReminderSlot> slots,
    NotificationCopy copy, {
    NotificationMascot? mascot,
    _NotificationImages? images,
    Set<String> resolvedDoseKeys = const <String>{},
  }) async {
    if (slots.isEmpty) {
      await _replaceEscalationPlans(
        const <Map<String, Object?>>[],
        const <int>[],
      );
      return;
    }
    final scheduleMode = await _androidScheduleMode();
    final rollingWeeks = math.max(
      1,
      math.min(
        _androidRollingWeeks,
        _maxAndroidScheduledDoseOccurrences ~/ slots.length,
      ),
    );
    final plannedByDoseKey = <String, _PlannedReminder>{};
    for (final slot in slots) {
      final first = _nextWeekday(slot.weekday, slot.hour, slot.minute);
      for (var week = 0; week < rollingWeeks; week++) {
        final reminder = _PlannedReminder(
          slot: slot,
          scheduledAt: _addCalendarDays(first, week * 7),
        );
        plannedByDoseKey.putIfAbsent(
          _doseKey(reminder.slot, reminder.scheduledAt),
          () => reminder,
        );
      }
    }
    final planned = plannedByDoseKey.values.toList();
    planned.removeWhere(
      (reminder) => !shouldScheduleDoseNotification(
        doseKey: _doseKey(reminder.slot, reminder.scheduledAt),
        resolvedDoseKeys: resolvedDoseKeys,
      ),
    );
    planned.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    if (planned.length > _maxAndroidScheduledDoseOccurrences) {
      planned.removeRange(_maxAndroidScheduledDoseOccurrences, planned.length);
    }

    final escalationPlans = <Map<String, Object?>>[];
    _NotificationAppearance? previous;
    for (var index = 0; index < planned.length; index++) {
      final reminder = planned[index];
      final appearance = _newAppearance(previous: previous);
      previous = appearance;
      final doseKey = _doseKey(reminder.slot, reminder.scheduledAt);
      final body = _notificationBody(copy, reminder.slot.medication, mascot);
      await _plugin.zonedSchedule(
        id: _doseNotificationId(doseKey),
        title: copy.title,
        body: body,
        scheduledDate: reminder.scheduledAt,
        notificationDetails: _details(
          copy,
          mascot: mascot,
          images: images,
          appearance: appearance,
          summaryText: body,
        ),
        androidScheduleMode: scheduleMode,
        payload: _payload(reminder.slot.medication.id, doseKey),
      );
      escalationPlans.add(<String, Object?>{
        'token': doseKey,
        'medicationId': reminder.slot.medication.id,
        'baseAtMillis': reminder.scheduledAt.millisecondsSinceEpoch,
        'baseNotificationId': _doseNotificationId(doseKey),
        'triggerAtMillis': reminder.scheduledAt
            .add(const Duration(minutes: 5))
            .millisecondsSinceEpoch,
        'title': copy.title,
        'body': fitNotificationText(copy.followUpBody),
        'escalatedBody': fitNotificationText(copy.escalatedBody),
        'medicationSuffix': notificationMedicationSuffix(
          medication: reminder.slot.medication,
          languageCode: copy.languageCode,
        ),
        'openLabel': copy.openAction,
        'snoozeLabel': copy.snoozeAction,
        'soundEnabled': mascot?.soundEnabled == true,
        'persistentMeowEnabled': mascot?.persistentMeowEnabled ?? true,
        'catName': mascot?.name,
        'speciesCode': mascot?.species.name ?? 'cat',
        'languageCode': copy.languageCode,
        'lastMessageIndex': mascot == null ? -1 : _lastCatMessageIndex ?? -1,
        'largeImagePath': images?.transparentPath,
        'accentedImagePaths': images?.accentedPaths ?? const <String>[],
        'channelName': copy.languageCode == 'nl'
            ? 'Medicatieherinneringen'
            : 'Medication reminders',
        'catChannelName': copy.languageCode == 'nl'
            ? 'Medicatieherinneringen met huisdier'
            : 'Medication reminders with pet',
      });
    }

    // Do not add weekly repeating fallbacks here. Android normalizes their
    // first trigger to the next matching weekday, even when a later start date
    // is supplied. Combining those repeats with dated occurrences therefore
    // produces two notifications for one dose. App startup/resume and every
    // medication change replenish this rolling, date-specific schedule.
    await _replaceEscalationPlans(
      escalationPlans,
      slots.map((slot) => slot.medication.id).toSet().toList(),
    );
  }

  Future<void> _scheduleRollingIosReminders(
    List<_ReminderSlot> slots,
    NotificationCopy copy, {
    NotificationMascot? mascot,
    _NotificationImages? images,
    Set<String> resolvedDoseKeys = const <String>{},
  }) async {
    final scheduleMode = await _androidScheduleMode();
    const iosPendingLimit = 64;
    final weeksToPlan = math.min(
      104,
      math.max(8, (iosPendingLimit ~/ math.max(1, slots.length)) + 2),
    );
    final planned = <_PlannedReminder>[];
    for (final slot in slots) {
      final first = _nextWeekday(slot.weekday, slot.hour, slot.minute);
      for (var week = 0; week < weeksToPlan; week++) {
        final scheduledAt = _addCalendarDays(first, week * 7);
        if (!shouldScheduleDoseNotification(
          doseKey: _doseKey(slot, scheduledAt),
          resolvedDoseKeys: resolvedDoseKeys,
        )) {
          continue;
        }
        planned.add(_PlannedReminder(slot: slot, scheduledAt: scheduledAt));
      }
    }
    planned.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    _NotificationAppearance? previous;
    for (
      var index = 0;
      index < planned.length && index < iosPendingLimit;
      index++
    ) {
      final reminder = planned[index];
      final slot = reminder.slot;
      final appearance = _newAppearance(previous: previous);
      previous = appearance;
      final body = _notificationBody(copy, slot.medication, mascot);
      final doseKey = _doseKey(slot, reminder.scheduledAt);
      await _plugin.zonedSchedule(
        id: _doseNotificationId(doseKey),
        title: copy.title,
        body: body,
        scheduledDate: reminder.scheduledAt,
        notificationDetails: _details(
          copy,
          mascot: mascot,
          images: images,
          appearance: appearance,
          summaryText: body,
        ),
        androidScheduleMode: scheduleMode,
        payload: _payload(slot.medication.id, doseKey),
      );
    }
  }

  Future<AndroidScheduleMode> _androidScheduleMode() async {
    if (!Platform.isAndroid) return AndroidScheduleMode.exactAllowWhileIdle;
    final canScheduleExactly = await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.canScheduleExactNotifications();
    return canScheduleExactly == true
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;
  }

  String _notificationBody(
    NotificationCopy copy,
    Medication medication,
    NotificationMascot? mascot,
  ) => _withMedicationName(
    mascot == null ? copy.body : _newCatBody(copy, mascot),
    medication,
    copy.languageCode,
  );

  String _newCatBody(NotificationCopy copy, NotificationMascot mascot) {
    final index = _nextDifferentIndex(
      CatNotificationMessages.count,
      _lastCatMessageIndex,
    );
    _lastCatMessageIndex = index;
    return CatNotificationMessages.messageAt(
      index: index,
      catName: mascot.name,
      languageCode: copy.languageCode,
      species: mascot.species,
    );
  }

  String _withMedicationName(
    String body,
    Medication medication,
    String languageCode,
  ) => medicationNotificationBody(
    body: body,
    medication: medication,
    languageCode: languageCode,
  );

  _NotificationAppearance _newAppearance({_NotificationAppearance? previous}) {
    final comparison = previous ?? _lastAppearance;
    final appearance = _NotificationAppearance(
      accentIndex: _nextDifferentThemeIndex(comparison?.accentIndex),
      soundIndex: _nextDifferentIndex(
        PetSoundCatalog.variantCount,
        comparison?.soundIndex,
      ),
    );
    _lastAppearance = appearance;
    return appearance;
  }

  int _nextDifferentIndex(int length, int? previous) {
    if (length <= 1) return 0;
    if (previous == null) return _random.nextInt(length);
    var next = _random.nextInt(length - 1);
    if (next >= previous) next++;
    return next;
  }

  int _nextDifferentThemeIndex(int? previous) {
    if (previous == null) return _random.nextInt(_accents.length);
    final choices = List<int>.generate(_accents.length, (index) => index)
        .where(
          (index) =>
              index != previous &&
              index % 8 != previous % 8 &&
              index % 4 != previous % 4,
        )
        .toList();
    return choices[_random.nextInt(choices.length)];
  }

  Future<_NotificationImages?> _prepareNotificationImages(
    NotificationMascot? mascot,
  ) async {
    try {
      final signature = mascot == null
          ? 'generic'
          : '${mascot.assetPath}|${mascot.hungerPoints}|'
                '${mascot.resolvedAccessories.map((item) => '${item.path}:'
                    '${item.scale}:${item.dx}:${item.dy}:${item.isToy}').join('|')}';
      final cached = _cachedNotificationImages;
      if (_lastImageSignature == signature &&
          cached != null &&
          File(cached.transparentPath).existsSync() &&
          cached.accentedPaths.every((path) => File(path).existsSync())) {
        return cached;
      }
      final Directory directory = await getApplicationSupportDirectory();
      final fileName =
          mascot?.assetPath.split('/').last ?? 'generic_reminder.png';
      final file = File('${directory.path}/notification_$fileName');
      ui.Image? base;
      final accessories =
          <({NotificationMascotAccessory item, ui.Image image})>[];
      const size = 512;
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      if (mascot == null) {
        _drawGenericReminderSymbol(canvas, size.toDouble());
      } else {
        base = await _loadAssetImage(mascot.assetPath);
        for (final item in mascot.resolvedAccessories) {
          accessories.add((
            item: item,
            image: await _loadAssetImage(item.path),
          ));
        }
        final hunger = mascot.hungerPoints.clamp(0, 5);
        final scaleX = 1 - hunger * .055;
        final scaleY = 1 - hunger * .01;
        final catDestination = ui.Rect.fromCenter(
          center: const ui.Offset(size / 2, size / 2),
          width: size * scaleX,
          height: size * scaleY,
        );
        final catPaint = ui.Paint()
          ..colorFilter = ui.ColorFilter.matrix(
            _saturationMatrix(1 - hunger * .12),
          );
        _drawImageFit(canvas, base, catDestination, catPaint);
        for (final accessory in accessories.where(
          (entry) => !entry.item.isToy,
        )) {
          _drawImageFit(
            canvas,
            accessory.image,
            _accessoryDestination(catDestination, accessory.item),
            catPaint,
          );
        }
        if (hunger >= 2) _drawHungryRibs(canvas, size.toDouble(), hunger / 5);
        for (final accessory in accessories.where(
          (entry) => entry.item.isToy,
        )) {
          _drawImageFit(
            canvas,
            accessory.image,
            _accessoryDestination(
              const ui.Rect.fromLTWH(0, 0, 512, 512),
              accessory.item,
            ),
            ui.Paint(),
          );
        }
      }
      final sourceImage = await recorder.endRecording().toImage(size, size);
      final sourceData = await sourceImage.toByteData(
        format: ui.ImageByteFormat.png,
      );
      if (sourceData == null) return null;
      final sourceBytes = sourceData.buffer.asUint8List();
      await file.writeAsBytes(sourceBytes, flush: true);
      final accentedPaths = <String>[];
      for (var index = 0; index < _accents.length; index++) {
        final recorder = ui.PictureRecorder();
        final canvas = ui.Canvas(recorder);
        const pictureWidth = 1024.0;
        const pictureHeight = 512.0;
        _drawNotificationTheme(
          canvas,
          index,
          const ui.Size(pictureWidth, pictureHeight),
        );
        final catSize = 420.0 + (index % 4) * 20;
        final catLeft = (pictureWidth - catSize) / 2;
        final catRect = ui.Rect.fromLTWH(
          catLeft,
          (pictureHeight - catSize) / 2,
          catSize,
          catSize,
        );
        final framePaint = ui.Paint()
          ..color = const ui.Color(0xFFFFFFFF).withValues(alpha: .30);
        if (index.isEven) {
          canvas.drawRRect(
            ui.RRect.fromRectAndRadius(
              catRect.inflate(12),
              ui.Radius.circular(index % 4 == 0 ? 42 : 110),
            ),
            framePaint,
          );
        } else {
          canvas.drawCircle(catRect.center, catSize * .52, framePaint);
        }
        _drawImageFit(canvas, sourceImage, catRect, ui.Paint());
        final rendered = await recorder.endRecording().toImage(
          pictureWidth.toInt(),
          pictureHeight.toInt(),
        );
        final png = await rendered.toByteData(format: ui.ImageByteFormat.png);
        final accentedFile = File(
          '${directory.path}/notification_color_${index}_$fileName',
        );
        await accentedFile.writeAsBytes(
          png?.buffer.asUint8List() ?? sourceBytes,
          flush: true,
        );
        accentedPaths.add(accentedFile.path);
        rendered.dispose();
      }
      base?.dispose();
      for (final accessory in accessories) {
        accessory.image.dispose();
      }
      sourceImage.dispose();
      final result = _NotificationImages(
        transparentPath: file.path,
        accentedPaths: accentedPaths,
      );
      _lastImageSignature = signature;
      _cachedNotificationImages = result;
      return result;
    } on Object {
      return null;
    }
  }

  ui.Rect _accessoryDestination(
    ui.Rect canvasRect,
    NotificationMascotAccessory accessory,
  ) => ui.Rect.fromCenter(
    center: canvasRect.center.translate(
      canvasRect.width * accessory.dx,
      canvasRect.height * accessory.dy,
    ),
    width: canvasRect.width * accessory.scale,
    height: canvasRect.height * accessory.scale,
  );

  void _drawGenericReminderSymbol(ui.Canvas canvas, double size) {
    final center = ui.Offset(size / 2, size / 2);
    canvas.drawCircle(
      center,
      size * .38,
      ui.Paint()..color = const ui.Color(0xEEFFFFFF),
    );
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(-math.pi / 4);
    final capsule = ui.RRect.fromRectAndRadius(
      ui.Rect.fromCenter(
        center: ui.Offset.zero,
        width: size * .48,
        height: size * .20,
      ),
      ui.Radius.circular(size * .10),
    );
    canvas.drawRRect(capsule, ui.Paint()..color = const ui.Color(0xFF00796B));
    canvas.save();
    canvas.clipRect(ui.Rect.fromLTWH(0, -size * .11, size * .26, size * .22));
    canvas.drawRRect(capsule, ui.Paint()..color = const ui.Color(0xFFFFB300));
    canvas.restore();
    canvas.drawLine(
      ui.Offset.zero,
      ui.Offset(0, size * .10),
      ui.Paint()
        ..color = const ui.Color(0xAAFFFFFF)
        ..strokeWidth = size * .018,
    );
    canvas.restore();
  }

  void _drawNotificationTheme(ui.Canvas canvas, int index, ui.Size size) {
    final accent = _accents[index];
    final partner = _accents[(index + 7) % _accents.length];
    final light = ui.Color.lerp(accent, const ui.Color(0xFFFFFFFF), .68)!;
    final dark = ui.Color.lerp(partner, const ui.Color(0xFF101018), .18)!;
    final backgroundPaint = ui.Paint()
      ..shader = ui.Gradient.linear(
        ui.Offset.zero,
        ui.Offset(size.width, size.height),
        index.isEven ? <ui.Color>[light, dark] : <ui.Color>[dark, light],
      );
    canvas.drawRect(ui.Offset.zero & size, backgroundPaint);

    final pale = const ui.Color(0xFFFFFFFF).withValues(alpha: .30);
    final strong = ui.Color(accent.toARGB32()).withValues(alpha: .58);
    switch (index % 8) {
      case 0:
        final paint = ui.Paint()..color = pale;
        for (var x = -size.height; x < size.width; x += 130) {
          final path = ui.Path()
            ..moveTo(x, 0)
            ..lineTo(x + 74, 0)
            ..lineTo(x + size.height + 74, size.height)
            ..lineTo(x + size.height, size.height)
            ..close();
          canvas.drawPath(path, paint);
        }
      case 1:
        final paint = ui.Paint()..color = pale;
        const cell = 92.0;
        for (var row = 0; row < 6; row++) {
          for (var column = 0; column < 12; column++) {
            if ((row + column).isEven) {
              canvas.drawRect(
                ui.Rect.fromLTWH(column * cell, row * cell, cell, cell),
                paint,
              );
            }
          }
        }
      case 2:
        final paint = ui.Paint()..color = pale;
        for (var row = 0; row < 5; row++) {
          for (var column = 0; column < 10; column++) {
            final offset = row.isEven ? 0.0 : 48.0;
            canvas.drawCircle(
              ui.Offset(45 + column * 105 + offset, 45 + row * 112),
              20.0 + (index % 3) * 7,
              paint,
            );
          }
        }
      case 3:
        final paint = ui.Paint()
          ..color = pale
          ..style = ui.PaintingStyle.stroke
          ..strokeWidth = 24;
        final center = ui.Offset(size.width * .5, size.height * .5);
        for (var radius = 75.0; radius < 620; radius += 92) {
          canvas.drawCircle(center, radius, paint);
        }
      case 4:
        final paint = ui.Paint()..color = strong;
        canvas.drawRect(
          ui.Rect.fromLTWH(0, 0, size.width * .36, size.height),
          paint,
        );
        canvas.drawRect(
          ui.Rect.fromLTWH(size.width * .72, 0, size.width * .28, size.height),
          ui.Paint()..color = pale,
        );
      case 5:
        final paint = ui.Paint()
          ..color = pale
          ..style = ui.PaintingStyle.stroke
          ..strokeWidth = 34;
        for (var y = -40.0; y < size.height + 80; y += 105) {
          final path = ui.Path()..moveTo(0, y);
          for (var x = 0.0; x <= size.width; x += 80) {
            path.lineTo(x, y + ((x ~/ 80).isEven ? 36 : -36));
          }
          canvas.drawPath(path, paint);
        }
      case 6:
        final center = ui.Offset(size.width / 2, size.height / 2);
        final paint = ui.Paint()..color = pale;
        for (var ray = 0; ray < 16; ray += 2) {
          final start = ray * math.pi / 8;
          final path = ui.Path()
            ..moveTo(center.dx, center.dy)
            ..lineTo(
              center.dx + math.cos(start) * size.width,
              center.dy + math.sin(start) * size.width,
            )
            ..lineTo(
              center.dx + math.cos(start + math.pi / 8) * size.width,
              center.dy + math.sin(start + math.pi / 8) * size.width,
            )
            ..close();
          canvas.drawPath(path, paint);
        }
      case 7:
        final random = math.Random(4000 + index);
        for (var item = 0; item < 55; item++) {
          final center = ui.Offset(
            random.nextDouble() * size.width,
            random.nextDouble() * size.height,
          );
          final paint = ui.Paint()..color = item.isEven ? pale : strong;
          canvas.save();
          canvas.translate(center.dx, center.dy);
          canvas.rotate(random.nextDouble() * math.pi);
          canvas.drawRRect(
            ui.RRect.fromRectAndRadius(
              ui.Rect.fromCenter(
                center: ui.Offset.zero,
                width: 18 + random.nextDouble() * 38,
                height: 8 + random.nextDouble() * 18,
              ),
              const ui.Radius.circular(5),
            ),
            paint,
          );
          canvas.restore();
        }
    }
  }

  Future<ui.Image> _loadAssetImage(String assetPath) async {
    final data = await rootBundle.load(assetPath);
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    codec.dispose();
    return frame.image;
  }

  void _drawImageFit(
    ui.Canvas canvas,
    ui.Image image,
    ui.Rect destination,
    ui.Paint paint,
  ) {
    canvas.drawImageRect(
      image,
      ui.Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      destination,
      paint,
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

  void _drawHungryRibs(ui.Canvas canvas, double size, double strength) {
    final paint = ui.Paint()
      ..color = const ui.Color(
        0xFFEF6C00,
      ).withValues(alpha: .22 + strength * .35)
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = size * .009
      ..strokeCap = ui.StrokeCap.round;
    for (var index = 0; index < 3; index++) {
      final top = size * (.53 + index * .055);
      canvas.drawArc(
        ui.Rect.fromLTRB(size * .29, top, size * .51, top + size * .09),
        3.55,
        1.25,
        false,
        paint,
      );
      canvas.drawArc(
        ui.Rect.fromLTRB(size * .49, top, size * .71, top + size * .09),
        5.76,
        1.25,
        false,
        paint,
      );
    }
  }

  String _payload(int medicationId, String? doseKey) => jsonEncode(
    <String, Object?>{'medicationId': medicationId, 'doseKey': doseKey},
  );

  String _doseKey(_ReminderSlot slot, DateTime scheduledAt) {
    final month = scheduledAt.month.toString().padLeft(2, '0');
    final day = scheduledAt.day.toString().padLeft(2, '0');
    final hour = slot.hour.toString().padLeft(2, '0');
    final minute = slot.minute.toString().padLeft(2, '0');
    return '${slot.medication.id}:${scheduledAt.year}-$month-$day:$hour:$minute';
  }

  int _doseNotificationId(String doseKey) {
    var hash = 0x811C9DC5;
    for (final value in doseKey.codeUnits) {
      hash = ((hash ^ value) * 0x01000193) & 0x7FFFFFFF;
    }
    return 1000000 + (hash % 800000000);
  }

  Future<void> _replaceEscalationPlans(
    List<Map<String, Object?>> plans,
    List<int> activeMedicationIds,
  ) async {
    if (!Platform.isAndroid) return;
    await _escalationChannel.invokeMethod<void>(
      'replacePlans',
      <String, Object?>{
        'plans': plans,
        'activeMedicationIds': activeMedicationIds,
      },
    );
  }

  tz.TZDateTime _nextWeekday(int weekday, int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var candidate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    while (candidate.weekday != weekday || !candidate.isAfter(now)) {
      candidate = tz.TZDateTime(
        tz.local,
        candidate.year,
        candidate.month,
        candidate.day + 1,
        hour,
        minute,
      );
    }
    return candidate;
  }

  tz.TZDateTime _addCalendarDays(tz.TZDateTime value, int days) {
    return tz.TZDateTime(
      tz.local,
      value.year,
      value.month,
      value.day + days,
      value.hour,
      value.minute,
    );
  }

  void _handleResponse(NotificationResponse response) {
    final event = _eventFromResponse(response);
    if (event != null) _actionController.add(event);
  }

  NotificationActionEvent? _eventFromResponse(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null) return null;
    int? medicationId;
    String? doseKey;
    try {
      final decoded = jsonDecode(payload) as Map<String, dynamic>;
      medicationId = (decoded['medicationId'] as num?)?.toInt();
      doseKey = decoded['doseKey'] as String?;
    } on Object {
      if (payload.startsWith('medication:')) {
        medicationId = int.tryParse(payload.substring('medication:'.length));
      }
    }
    if (medicationId == null) return null;
    return NotificationActionEvent(
      medicationId: medicationId,
      actionId: response.actionId?.isNotEmpty == true
          ? response.actionId!
          : openAction,
      doseKey: doseKey,
    );
  }
}

class _ReminderSlot {
  const _ReminderSlot({
    required this.medication,
    required this.weekday,
    required this.hour,
    required this.minute,
  });

  final Medication medication;
  final int weekday;
  final int hour;
  final int minute;
}

class _PlannedReminder {
  const _PlannedReminder({required this.slot, required this.scheduledAt});

  final _ReminderSlot slot;
  final tz.TZDateTime scheduledAt;
}

class _NotificationAppearance {
  const _NotificationAppearance({
    required this.accentIndex,
    required this.soundIndex,
  });

  final int accentIndex;
  final int soundIndex;
}

class _NotificationImages {
  const _NotificationImages({
    required this.transparentPath,
    required this.accentedPaths,
  });

  final String transparentPath;
  final List<String> accentedPaths;
}
