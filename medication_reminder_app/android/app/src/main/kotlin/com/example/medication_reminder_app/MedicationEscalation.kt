package nl.rickgroot.medicationreminder

import android.app.AlarmManager
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.graphics.BitmapFactory
import android.media.AudioAttributes
import android.media.RingtoneManager
import android.net.Uri
import android.os.Build
import android.provider.Settings
import androidx.core.app.NotificationCompat
import org.json.JSONArray
import org.json.JSONObject
import kotlin.math.absoluteValue
import kotlin.random.Random

private const val STORE_NAME = "medication_escalations_v1"
private const val PLAN_PREFIX = "plan:"
private const val FIVE_MINUTES = 5 * 60 * 1000L
private const val TEN_MINUTES = 10 * 60 * 1000L
private const val BASE_CHANNEL = "medication_reminders_v1"
// Notification-channel audio attributes cannot be changed after creation.
// v2 prevents an update from inheriting an older notification-volume channel.
private const val BASE_ALARM_CHANNEL = "medication_alarms_v2"
private const val SOUND_VARIANT_COUNT = 20
private val ACCENTS = listOf(
    0xff00897b.toInt(),
    0xff7b1fa2.toInt(),
    0xffe65100.toInt(),
    0xff1565c0.toInt(),
    0xffc62828.toInt(),
    0xff558b2f.toInt(),
    0xffad1457.toInt(),
    0xff00695c.toInt(),
    0xfff9a825.toInt(),
    0xff283593.toInt(),
    0xff9e9d24.toInt(),
    0xffef6c00.toInt(),
    0xff6d4c41.toInt(),
    0xff512da8.toInt(),
    0xff0277bd.toInt(),
    0xffff8f00.toInt(),
    0xffd81b60.toInt(),
    0xff2e7d32.toInt(),
    0xff00838f.toInt(),
    0xff4527a0.toInt(),
    0xfff4511e.toInt(),
    0xff3949ab.toInt(),
    0xff00acc1.toInt(),
    0xff8e24aa.toInt(),
)

data class EscalationPlan(
    val token: String,
    val medicationId: Int,
    val baseAtMillis: Long,
    val baseNotificationId: Int,
    var nextAtMillis: Long,
    val title: String,
    val body: String,
    val escalatedBody: String,
    val medicationSuffix: String?,
    val openLabel: String,
    val snoozeLabel: String,
    val soundEnabled: Boolean,
    val notificationsOnly: Boolean,
    val persistentMeowEnabled: Boolean,
    val catName: String?,
    val speciesCode: String,
    val languageCode: String,
    val largeImagePath: String?,
    val accentedImagePaths: List<String>,
    val channelName: String,
    val catChannelName: String,
    val alarmChannelName: String,
    var started: Boolean = false,
    var noResponseCount: Int = 0,
    var snoozeCount: Int = 0,
    var snoozeWake: Boolean = false,
    var finished: Boolean = false,
    var lastSoundIndex: Int = -1,
    var lastThemeIndex: Int = -1,
    var lastMessageIndex: Int = -1,
) {
    fun toJson(): JSONObject = JSONObject().apply {
        put("token", token)
        put("medicationId", medicationId)
        put("baseAtMillis", baseAtMillis)
        put("baseNotificationId", baseNotificationId)
        put("triggerAtMillis", nextAtMillis)
        put("title", title)
        put("body", body)
        put("escalatedBody", escalatedBody)
        put("medicationSuffix", medicationSuffix)
        put("openLabel", openLabel)
        put("snoozeLabel", snoozeLabel)
        put("soundEnabled", soundEnabled)
        put("notificationsOnly", notificationsOnly)
        put("persistentMeowEnabled", persistentMeowEnabled)
        put("catName", catName)
        put("speciesCode", speciesCode)
        put("languageCode", languageCode)
        put("largeImagePath", largeImagePath)
        put("accentedImagePaths", JSONArray(accentedImagePaths))
        put("channelName", channelName)
        put("catChannelName", catChannelName)
        put("alarmChannelName", alarmChannelName)
        put("started", started)
        put("noResponseCount", noResponseCount)
        put("snoozeCount", snoozeCount)
        put("snoozeWake", snoozeWake)
        put("finished", finished)
        put("lastSoundIndex", lastSoundIndex)
        put("lastThemeIndex", lastThemeIndex)
        put("lastMessageIndex", lastMessageIndex)
    }

    companion object {
        fun fromJson(json: JSONObject): EscalationPlan {
            val paths = json.optJSONArray("accentedImagePaths") ?: JSONArray()
            return EscalationPlan(
                token = json.getString("token"),
                medicationId = json.getInt("medicationId"),
                baseAtMillis = json.optLong(
                    "baseAtMillis",
                    json.optLong("triggerAtMillis", System.currentTimeMillis()) - FIVE_MINUTES,
                ),
                baseNotificationId = json.optInt(
                    "baseNotificationId",
                    notificationId(json.getString("token")),
                ),
                nextAtMillis = json.optLong("triggerAtMillis", System.currentTimeMillis()),
                title = json.optString("title"),
                body = json.optString("body"),
                escalatedBody = json.optString("escalatedBody"),
                medicationSuffix = json.optString("medicationSuffix", "")
                    .takeUnless { it.isBlank() || it == "null" },
                openLabel = json.optString("openLabel"),
                snoozeLabel = json.optString("snoozeLabel"),
                soundEnabled = json.optBoolean("soundEnabled"),
                notificationsOnly = json.optBoolean("notificationsOnly"),
                persistentMeowEnabled = json.optBoolean("persistentMeowEnabled", false),
                catName = json.optString("catName")
                    .takeUnless { it.isBlank() || it == "null" },
                speciesCode = json.optString("speciesCode", "cat"),
                languageCode = json.optString("languageCode", "en"),
                largeImagePath = json.optString("largeImagePath")
                    .takeUnless { it.isBlank() || it == "null" },
                accentedImagePaths = List(paths.length()) { paths.optString(it) }
                    .filter { it.isNotBlank() },
                channelName = json.optString("channelName", "Medication reminders"),
                catChannelName = json.optString(
                    "catChannelName",
                    "Medication reminders with cat",
                ),
                alarmChannelName = json.optString(
                    "alarmChannelName",
                    "Medication alarms",
                ),
                started = json.optBoolean("started"),
                noResponseCount = json.optInt("noResponseCount"),
                snoozeCount = json.optInt("snoozeCount"),
                snoozeWake = json.optBoolean("snoozeWake"),
                finished = json.optBoolean("finished"),
                lastSoundIndex = json.optInt("lastSoundIndex", -1),
                lastThemeIndex = json.optInt("lastThemeIndex", -1),
                lastMessageIndex = json.optInt("lastMessageIndex", -1),
            )
        }
    }
}

object EscalationStore {
    fun replacePlans(
        context: Context,
        incoming: List<JSONObject>,
        activeMedicationIds: Set<Int>,
        resolvedDoseKeys: Set<String>,
    ): Boolean {
        val preferences = context.getSharedPreferences(STORE_NAME, Context.MODE_PRIVATE)
        val incomingTokens = incoming.map { it.getString("token") }.toSet()
        val now = System.currentTimeMillis()
        allPlans(context).forEach { existing ->
            val keepActive =
                existing.started &&
                !existing.finished &&
                existing.medicationId in activeMedicationIds
            val keepPersistent =
                existing.persistentMeowEnabled &&
                !existing.finished &&
                existing.baseAtMillis <= now &&
                existing.medicationId in activeMedicationIds
            val keepCurrent =
                existing.medicationId in activeMedicationIds &&
                existing.baseAtMillis <= now &&
                existing.baseAtMillis >= now - 24 * 60 * 60 * 1000L
            if (
                existing.token in resolvedDoseKeys ||
                (!keepActive && !keepPersistent && !keepCurrent &&
                    existing.token !in incomingTokens)
            ) {
                cancel(context, existing)
                preferences.edit().remove(PLAN_PREFIX + existing.token).apply()
            }
        }
        var everyAlarmScheduled = true
        incoming.forEach { json ->
            val incomingPlan = EscalationPlan.fromJson(json)
            val existing = load(context, incomingPlan.token)
            val existingIsCurrent =
                existing != null &&
                existing.baseAtMillis <= now &&
                existing.baseAtMillis >= now - 24 * 60 * 60 * 1000L
            if (existing?.started == true || existingIsCurrent) {
                // Opening the app after Android killed or force-stopped its
                // process must restore the current follow-up/snooze alarm.
                // Reusing the same PendingIntent replaces any alarm that is
                // still registered, while preserving all session counters.
                if (existing != null && !existing.finished) {
                    everyAlarmScheduled =
                        schedule(
                            context,
                            existing,
                            maxOf(existing.nextAtMillis, now + 10_000L),
                        ) && everyAlarmScheduled
                }
                return@forEach
            }
            save(context, incomingPlan)
            everyAlarmScheduled =
                schedule(context, incomingPlan, incomingPlan.nextAtMillis) &&
                scheduleBoundary(context, incomingPlan) &&
                everyAlarmScheduled
        }
        return everyAlarmScheduled
    }

    fun snooze(context: Context, token: String): Int {
        val plan = load(context, token) ?: return -1
        plan.started = true
        plan.snoozeCount += 1
        plan.noResponseCount = 0
        plan.snoozeWake = true
        plan.finished = false
        dismiss(context, plan)
        return if (schedule(context, plan, System.currentTimeMillis() + TEN_MINUTES)) {
            plan.snoozeCount
        } else {
            -1
        }
    }

    fun resolveMedication(context: Context, medicationId: Int) {
        val preferences = context.getSharedPreferences(STORE_NAME, Context.MODE_PRIVATE)
        allPlans(context).filter { it.medicationId == medicationId }.forEach { plan ->
            cancel(context, plan)
            dismiss(context, plan)
            preferences.edit().remove(PLAN_PREFIX + plan.token).apply()
        }
    }

    fun resolveDose(context: Context, token: String) {
        val plan = load(context, token) ?: return
        cancel(context, plan)
        dismiss(context, plan)
        context.getSharedPreferences(STORE_NAME, Context.MODE_PRIVATE)
            .edit()
            .remove(PLAN_PREFIX + token)
            .apply()
    }

    fun rescheduleAll(context: Context) {
        val now = System.currentTimeMillis()
        val plans = allPlans(context)
        plans.filter { it.baseAtMillis <= now }.maxByOrNull { it.baseAtMillis }?.let { latest ->
            expireBefore(context, latest.baseAtMillis, latest.token)
        }
        allPlans(context).filterNot { it.finished }.forEach { plan ->
            schedule(context, plan, maxOf(plan.nextAtMillis, now + 10_000L))
            scheduleBoundary(context, plan)
        }
    }

    fun expireBefore(context: Context, boundaryMillis: Long, currentToken: String) {
        val preferences = context.getSharedPreferences(STORE_NAME, Context.MODE_PRIVATE)
        allPlans(context)
            .filter { plan ->
                plan.token != currentToken &&
                    plan.baseAtMillis < boundaryMillis &&
                    !(plan.persistentMeowEnabled &&
                        !plan.finished &&
                        plan.baseAtMillis <= System.currentTimeMillis())
            }
            .forEach { plan ->
                cancel(context, plan)
                dismiss(context, plan)
                preferences.edit().remove(PLAN_PREFIX + plan.token).apply()
            }
    }

    fun load(context: Context, token: String): EscalationPlan? {
        val value = context.getSharedPreferences(STORE_NAME, Context.MODE_PRIVATE)
            .getString(PLAN_PREFIX + token, null) ?: return null
        return runCatching { EscalationPlan.fromJson(JSONObject(value)) }.getOrNull()
    }

    fun schedule(context: Context, plan: EscalationPlan, atMillis: Long): Boolean {
        plan.nextAtMillis = atMillis
        plan.finished = false
        save(context, plan)
        val manager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val operation = alarmIntent(context, plan.token)
        return scheduleAlarm(manager, atMillis, operation)
    }

    private fun scheduleBoundary(context: Context, plan: EscalationPlan): Boolean {
        if (plan.baseAtMillis <= System.currentTimeMillis()) return true
        val manager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val operation = boundaryIntent(context, plan.token)
        return scheduleAlarm(manager, plan.baseAtMillis, operation)
    }

    private fun scheduleAlarm(
        manager: AlarmManager,
        atMillis: Long,
        operation: PendingIntent,
    ): Boolean {
        return try {
            val exactAllowed =
                Build.VERSION.SDK_INT < Build.VERSION_CODES.S || manager.canScheduleExactAlarms()
            when {
                !exactAllowed -> false
                Build.VERSION.SDK_INT >= Build.VERSION_CODES.M ->
                    manager.setExactAndAllowWhileIdle(
                        AlarmManager.RTC_WAKEUP,
                        atMillis,
                        operation,
                    ).let { true }
                else -> manager.setExact(
                    AlarmManager.RTC_WAKEUP,
                    atMillis,
                    operation,
                ).let { true }
            }
        } catch (_: IllegalStateException) {
            // Some vendors enforce a lower per-app alarm cap. The base dose
            // notification remains scheduled; report the failed follow-up to
            // Flutter so the UI never presents a partial plan as reliable.
            false
        } catch (_: SecurityException) {
            // Exact-alarm access can change while the app is not running.
            false
        }
    }

    fun finish(context: Context, plan: EscalationPlan) {
        plan.finished = true
        save(context, plan)
        val manager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        manager.cancel(alarmIntent(context, plan.token))
        manager.cancel(boundaryIntent(context, plan.token))
    }

    fun save(context: Context, plan: EscalationPlan) {
        context.getSharedPreferences(STORE_NAME, Context.MODE_PRIVATE)
            .edit()
            .putString(PLAN_PREFIX + plan.token, plan.toJson().toString())
            .apply()
    }

    private fun allPlans(context: Context): List<EscalationPlan> =
        context.getSharedPreferences(STORE_NAME, Context.MODE_PRIVATE)
            .all
            .filterKeys { it.startsWith(PLAN_PREFIX) }
            .values
            .mapNotNull { value ->
                runCatching { EscalationPlan.fromJson(JSONObject(value as String)) }.getOrNull()
            }

    private fun cancel(context: Context, plan: EscalationPlan) {
        val manager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        manager.cancel(alarmIntent(context, plan.token))
        manager.cancel(boundaryIntent(context, plan.token))
    }

    private fun alarmIntent(context: Context, token: String): PendingIntent =
        PendingIntent.getBroadcast(
            context,
            requestCode(token),
            Intent(context, MedicationEscalationReceiver::class.java).apply {
                action = "medication.escalation.$token"
                putExtra(MainActivity.EXTRA_DOSE_KEY, token)
            },
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

    private fun boundaryIntent(context: Context, token: String): PendingIntent =
        PendingIntent.getBroadcast(
            context,
            requestCode(token + ":boundary"),
            Intent(context, MedicationAlarmBoundaryReceiver::class.java).apply {
                action = "medication.boundary.$token"
                putExtra(MainActivity.EXTRA_DOSE_KEY, token)
            },
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

    private fun dismiss(context: Context, plan: EscalationPlan) {
        val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        manager.cancel(notificationId(plan.token))
        manager.cancel(plan.baseNotificationId)
    }
}

class MedicationAlarmBoundaryReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val token = intent.getStringExtra(MainActivity.EXTRA_DOSE_KEY) ?: return
        val plan = EscalationStore.load(context, token) ?: return
        EscalationStore.expireBefore(context, plan.baseAtMillis, plan.token)
    }
}

class MedicationEscalationReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val token = intent.getStringExtra(MainActivity.EXTRA_DOSE_KEY) ?: return
        val plan = EscalationStore.load(context, token) ?: return
        plan.started = true
        val isSnoozeWake = plan.snoozeWake
        if (isSnoozeWake) {
            plan.snoozeWake = false
        } else {
            plan.noResponseCount += 1
        }
        showNotification(
            context,
            plan,
            useAlarmAudio = isSnoozeWake && !plan.notificationsOnly,
        )
        val reachedLimit = plan.noResponseCount >= 3
        if (plan.persistentMeowEnabled || !reachedLimit) {
            EscalationStore.schedule(context, plan, System.currentTimeMillis() + FIVE_MINUTES)
        } else {
            // Keep the third notification visible and retain the plan so its
            // Snooze action can still start a fresh ten-minute alarm. Marking
            // it finished prevents boot/update receivers from adding a fourth.
            EscalationStore.finish(context, plan)
        }
    }
}

class MedicationSnoozeReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val token = intent.getStringExtra(MainActivity.EXTRA_DOSE_KEY) ?: return
        EscalationStore.snooze(context, token)
    }
}

class MedicationEscalationBootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        runCatching { EscalationStore.rescheduleAll(context) }
    }
}

private fun showNotification(
    context: Context,
    plan: EscalationPlan,
    useAlarmAudio: Boolean = false,
) {
    val notificationManager =
        context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
    val soundNames = reminderSounds(plan.speciesCode)
    val soundChannels = if (useAlarmAudio) {
        alarmSoundChannels(plan.speciesCode)
    } else {
        reminderSoundChannels(plan.speciesCode)
    }
    val soundIndex = nextDifferentIndex(soundNames.size, plan.lastSoundIndex)
    plan.lastSoundIndex = soundIndex
    createChannels(
        context,
        notificationManager,
        plan,
        soundIndex,
        soundNames,
        soundChannels,
        useAlarmAudio,
    )
    val colorIndex = nextDifferentThemeIndex(ACCENTS.size, plan.lastThemeIndex)
    plan.lastThemeIndex = colorIndex
    val notificationId = notificationId(plan.token)
    val openIntent = Intent(context, MainActivity::class.java).apply {
        flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
        action = "medication.open.${plan.token}.${System.currentTimeMillis()}"
        putExtra(MainActivity.EXTRA_MEDICATION_ID, plan.medicationId)
        putExtra(MainActivity.EXTRA_DOSE_KEY, plan.token)
    }
    val openPendingIntent = PendingIntent.getActivity(
        context,
        requestCode(plan.token + ":open"),
        openIntent,
        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
    )
    val snoozePendingIntent = PendingIntent.getBroadcast(
        context,
        requestCode(plan.token + ":snooze"),
        Intent(context, MedicationSnoozeReceiver::class.java).apply {
            action = "medication.snooze.${plan.token}"
            putExtra(MainActivity.EXTRA_DOSE_KEY, plan.token)
        },
        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
    )
    val channel = if (plan.soundEnabled) {
        soundChannels[soundIndex]
    } else if (useAlarmAudio) {
        BASE_ALARM_CHANNEL
    } else {
        BASE_CHANNEL
    }
    val reachedRepeatLimit =
        plan.persistentMeowEnabled &&
        plan.noResponseCount >= 3
    val followUpBody = if (reachedRepeatLimit) {
        plan.escalatedBody
    } else {
        plan.body
    }
    val catMessage = plan.catName?.let { catName ->
        val messageIndex = nextDifferentIndex(500, plan.lastMessageIndex)
        plan.lastMessageIndex = messageIndex
        petReminderMessage(catName, plan.languageCode, plan.speciesCode, messageIndex)
    }
    val primaryBody = if (catMessage == null) {
        followUpBody
    } else if (reachedRepeatLimit) {
        persistentPetReminderMessage(
            catName = plan.catName.orEmpty(),
            languageCode = plan.languageCode,
            speciesCode = plan.speciesCode,
        )
    } else {
        catMessage
    }
    val body = fitNotificationText(
        listOfNotNull(primaryBody.takeIf { it.isNotBlank() }, plan.medicationSuffix)
            .joinToString(" "),
    )
    val smallIcon = context.resources.getIdentifier(
        "ic_stat_medication",
        "drawable",
        context.packageName,
    ).takeIf { it != 0 } ?: context.applicationInfo.icon
    val builder = NotificationCompat.Builder(context, channel)
        .setSmallIcon(smallIcon)
        .setContentTitle(plan.title)
        .setContentText(body)
        .setColor(ACCENTS[colorIndex])
        .setColorized(true)
        .setPriority(NotificationCompat.PRIORITY_HIGH)
        .setCategory(
            if (useAlarmAudio) NotificationCompat.CATEGORY_ALARM
            else NotificationCompat.CATEGORY_REMINDER,
        )
        .setVisibility(NotificationCompat.VISIBILITY_PRIVATE)
        .setAutoCancel(true)
        .setContentIntent(openPendingIntent)

    plan.largeImagePath?.let { path ->
        BitmapFactory.decodeFile(path)?.let(builder::setLargeIcon)
    }
    plan.accentedImagePaths.getOrNull(colorIndex)?.let { path ->
        BitmapFactory.decodeFile(path)?.let { picture ->
            builder.setStyle(
                NotificationCompat.BigPictureStyle()
                    .bigPicture(picture)
                    .bigLargeIcon(null as android.graphics.Bitmap?),
            )
        }
    }
    val openAction = NotificationCompat.Action(0, plan.openLabel, openPendingIntent)
    val snoozeAction = NotificationCompat.Action(0, plan.snoozeLabel, snoozePendingIntent)
    builder.addAction(snoozeAction).addAction(openAction)
    notificationManager.notify(notificationId, builder.build())
}

private fun createChannels(
    context: Context,
    manager: NotificationManager,
    plan: EscalationPlan,
    soundIndex: Int,
    soundNames: List<String>,
    soundChannels: List<String>,
    useAlarmAudio: Boolean,
) {
    if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
    val baseChannel = if (useAlarmAudio) BASE_ALARM_CHANNEL else BASE_CHANNEL
    if (manager.getNotificationChannel(baseChannel) == null) {
        val channel = NotificationChannel(
            baseChannel,
            if (useAlarmAudio) plan.alarmChannelName else plan.channelName,
            NotificationManager.IMPORTANCE_HIGH,
        )
        val attributes = AudioAttributes.Builder()
            .setUsage(
                if (useAlarmAudio) AudioAttributes.USAGE_ALARM
                else AudioAttributes.USAGE_NOTIFICATION,
            )
            .build()
        val defaultSound = if (useAlarmAudio) {
            Settings.System.DEFAULT_ALARM_ALERT_URI
        } else {
            RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)
        }
        channel.setSound(defaultSound, attributes)
        manager.createNotificationChannel(
            channel,
        )
    }
    val channelId = soundChannels[soundIndex]
    if (manager.getNotificationChannel(channelId) == null) {
        val soundUri = Uri.parse(
            "android.resource://${context.packageName}/raw/${soundNames[soundIndex]}",
        )
        val attributes = AudioAttributes.Builder()
            .setUsage(
                if (useAlarmAudio) AudioAttributes.USAGE_ALARM
                else AudioAttributes.USAGE_NOTIFICATION,
            )
            .build()
        manager.createNotificationChannel(
            NotificationChannel(
                channelId,
                if (useAlarmAudio) plan.alarmChannelName else plan.catChannelName,
                NotificationManager.IMPORTANCE_HIGH,
            ).apply { setSound(soundUri, attributes) },
        )
    }
}

private fun reminderSoundStem(speciesCode: String): String = when (speciesCode) {
    "dog" -> "dog_bark"
    "chicken" -> "chicken_crow"
    else -> "cat_meow"
}

private fun reminderSounds(speciesCode: String): List<String> {
    val stem = reminderSoundStem(speciesCode)
    return List(SOUND_VARIANT_COUNT) { index ->
        "${stem}_${(index + 1).toString().padStart(2, '0')}"
    }
}

private fun reminderSoundChannels(speciesCode: String): List<String> {
    val species = when (speciesCode) {
        "dog" -> "dog"
        "chicken" -> "chicken"
        else -> "cat"
    }
    val version = if (species == "cat" || species == "chicken") "v3" else "v2"
    return List(SOUND_VARIANT_COUNT) { index ->
        "medication_${species}_voice_${(index + 1).toString().padStart(2, '0')}_${version}"
    }
}

private fun alarmSoundChannels(speciesCode: String): List<String> {
    val species = when (speciesCode) {
        "dog" -> "dog"
        "chicken" -> "chicken"
        else -> "cat"
    }
    val version = if (species == "chicken") "v3" else "v2"
    return List(SOUND_VARIANT_COUNT) { index ->
        "medication_${species}_alarm_voice_${(index + 1).toString().padStart(2, '0')}_${version}"
    }
}

private fun petReminderMessage(
    rawName: String,
    languageCode: String,
    speciesCode: String,
    index: Int,
): String {
    val name = if (rawName.length <= 12) rawName else rawName.take(11) + "…"
    val normalized = index.mod(500)
    val cat = speciesCode == "cat"
    val special = when (languageCode) {
        "nl" -> if (cat) listOf(
            "Donna kijkt jaloers. $name: medicatietijd!", "Donna wil aandacht. $name zegt: dosis!",
            "$name helpt. Donna kijkt jaloers: dosis!", "dimi jaagt $name bijna weg. Eerst je dosis!",
            "$name waakt. dimi kijkt jaloers: dosis!", "dimi moppert op $name. Medicatietijd!",
        ) else listOf(
            "$name vraagt aandacht: medicatietijd!", "$name staat klaar: je dosis wacht.",
            "$name helpt: tijd voor je dosis!", "$name geeft een seintje: dosis!",
            "$name wacht. Open de app!", "$name zegt: zorg goed voor jezelf!",
        )
        "de" -> if (cat) listOf(
            "Donna schaut neidisch. $name sagt: Zeit für die Dosis!", "Donna möchte Aufmerksamkeit. $name sagt: Dosis!",
            "$name hilft. Donna schaut neidisch: Zeit für die Dosis!", "dimi verjagt $name vielleicht. Erst die Dosis!",
            "$name passt auf. dimi schaut neidisch: Zeit für die Dosis!", "dimi brummt $name an. Medikamentenzeit!",
        ) else listOf(
            "$name möchte Aufmerksamkeit: Medikamentenzeit!", "$name ist bereit: Deine Dosis ist fällig.",
            "$name erinnert dich: Zeit für die Dosis!", "$name gibt ein Zeichen: Zeit für die Dosis!",
            "$name wartet. Öffne die App!", "$name sagt: Pass gut auf dich auf!",
        )
        "fr" -> if (cat) listOf(
            "Donna est jalouse. $name dit : c’est l’heure de la dose !", "Donna veut de l’attention. $name dit : la dose !",
            "$name vous aide. Donna est jalouse : c’est l’heure de la dose !", "dimi pourrait chasser $name. La dose d’abord !",
            "$name monte la garde. dimi est jalouse : c’est l’heure de la dose !", "dimi grogne contre $name. C’est l’heure du médicament !",
        ) else listOf(
            "$name veut votre attention : c’est l’heure du médicament !", "$name est prêt : votre dose est prévue.",
            "$name vous rappelle : c’est l’heure de la dose !", "$name vous fait signe : c’est l’heure de la dose !",
            "$name attend. Ouvrez l’app !", "$name dit : prenez soin de vous !",
        )
        "es" -> if (cat) listOf(
            "Donna mira con celos. $name dice: ¡hora de la dosis!", "Donna quiere atención. $name dice: ¡la dosis!",
            "$name ayuda. Donna mira con celos: ¡hora de la dosis!", "dimi podría echar a $name. ¡Primero la dosis!",
            "$name vigila. dimi mira con celos: ¡hora de la dosis!", "dimi gruñe a $name. ¡Hora del medicamento!",
        ) else listOf(
            "$name quiere atención: ¡hora del medicamento!", "$name está listo: tu dosis está pendiente.",
            "$name te recuerda: ¡hora de la dosis!", "$name te hace una señal: ¡hora de la dosis!",
            "$name espera. ¡Abre la app!", "$name dice: ¡cuídate mucho!",
        )
        else -> if (cat) listOf(
            "Donna looks jealous. $name says: dose time!", "Donna wants attention. $name says: dose!",
            "$name helps. Donna looks jealous: dose time!", "dimi may chase $name away. Dose first!",
            "$name guards. dimi looks jealous: dose time!", "dimi grumbles at $name. Medication time!",
        ) else listOf(
            "$name wants attention: medication time!", "$name is ready: your dose is due.",
            "$name reminds you: dose time!", "$name gives a signal: dose time!",
            "$name waits. Open the app!", "$name says: take care of yourself!",
        )
    }
    if (normalized < special.size) return special[normalized]
    val openings = when (languageCode) {
        "nl" -> SHORT_DUTCH_OPENINGS
        "de" -> SHORT_GERMAN_OPENINGS
        "fr" -> SHORT_FRENCH_OPENINGS
        "es" -> SHORT_SPANISH_OPENINGS
        else -> SHORT_ENGLISH_OPENINGS
    }
    val endings = when (languageCode) {
        "nl" -> SHORT_DUTCH_ENDINGS
        "de" -> SHORT_GERMAN_ENDINGS
        "fr" -> SHORT_FRENCH_ENDINGS
        "es" -> SHORT_SPANISH_ENDINGS
        else -> SHORT_ENGLISH_ENDINGS
    }
    val sound = when (speciesCode) {
        "dog" -> when (languageCode) { "nl" -> "blaft"; "de" -> "bellt"; "fr" -> "aboie"; "es" -> "ladra"; else -> "barks" }
        "chicken" -> when (languageCode) { "nl" -> "tokt"; "de" -> "gackert"; "fr" -> "caquette"; "es" -> "cacarea"; else -> "clucks" }
        else -> when (languageCode) { "nl" -> "miauwt"; "de" -> "miaut"; "fr" -> "miaule"; "es" -> "maúlla"; else -> "meows" }
    }
    val value = normalized - special.size
    return "$name ${openings[value / endings.size].replace("{sound}", sound)} " +
        endings[value % endings.size]
}

private fun persistentPetReminderMessage(
    catName: String,
    languageCode: String,
    speciesCode: String,
): String {
    val name = if (catName.length <= 12) catName else catName.take(11) + "…"
    val keepsCalling = when (speciesCode) {
        "dog" -> when (languageCode) { "nl" -> "blijft blaffen"; "de" -> "bellt weiter"; "fr" -> "continue d’aboyer"; "es" -> "sigue ladrando"; else -> "keeps barking" }
        "chicken" -> when (languageCode) { "nl" -> "blijft tokken"; "de" -> "gackert weiter"; "fr" -> "continue de caqueter"; "es" -> "sigue cacareando"; else -> "keeps clucking" }
        else -> when (languageCode) { "nl" -> "blijft miauwen"; "de" -> "miaut weiter"; "fr" -> "continue de miauler"; "es" -> "sigue maullando"; else -> "keeps meowing" }
    }
    return when (languageCode) {
        "nl" -> "$name $keepsCalling: open of stel uit."
        "de" -> "$name $keepsCalling: öffnen oder verschieben."
        "fr" -> "$name $keepsCalling : ouvrez ou reportez."
        "es" -> "$name $keepsCalling: abre o pospón."
        else -> "$name $keepsCalling: open or snooze."
    }
}

private fun fitNotificationText(value: String, maxCharacters: Int = 82): String {
    val normalized = value.replace(Regex("\\s+"), " ").trim()
    if (normalized.length <= maxCharacters) return normalized
    if (maxCharacters <= 1) return "…".take(maxCharacters)
    val candidate = normalized.take(maxCharacters - 1)
    val lastSpace = candidate.lastIndexOf(' ')
    val cut = if (lastSpace >= (maxCharacters * .65).toInt()) {
        candidate.take(lastSpace)
    } else {
        candidate
    }
    return cut.trimEnd() + "…"
}

private val SHORT_DUTCH_OPENINGS = listOf(
    "tikt op de klok:", "staat paraat:", "{sound} vriendelijk:",
    "kijkt je aan:", "doet een rondje:", "{sound} dichtbij:",
    "zet het alarm aan:", "heeft nieuws:", "komt melden:",
    "is je dosiscoach:", "springt op:", "heeft een update:",
    "staat trots:", "opent de planner:", "pauzeert de siësta:",
    "wijst naar de klok:", "test de microfoon:", "neemt de wacht:",
    "tikt het alarm aan:",
)

private val SHORT_DUTCH_ENDINGS = listOf(
    "tijd voor je medicatie!", "je dosis wacht.", "je medicatiemoment is er.",
    "open de app.", "je medicatie wacht.",
    "de klok zegt: dosis.", "je dosis staat klaar.",
    "zorg goed voor jezelf.", "je dosis is er.",
    "een belangrijk seintje.", "de dosisronde begint.",
    "bekijk de app.", "je hulpteam is er.",
    "medicatietijd bevestigd.", "precies op tijd.",
    "geen paniek, alleen je dosis.", "tijd voor je routine.",
    "je herinnering is er.", "de medicatieklok gaat.", "een dosis-seintje.",
    "geef je dosis een moment.", "het team stemt: dosis.",
    "bekijk wat klaarstaat.", "het protocol zegt: dosis.",
    "rond dit af in de app.", "je dosis zegt hallo.",
)

private val SHORT_ENGLISH_OPENINGS = listOf(
    "taps the watch:", "stands ready:", "{sound} gently:",
    "looks at you:", "takes a quick lap:", "{sound} nearby:",
    "starts reminder mode:", "has news:", "reports in:",
    "is your dose coach:", "jumps up:", "has an update:",
    "stands proudly:", "opens the planner:", "pauses the nap:",
    "points at the clock:", "tests the microphone:", "takes reminder duty:",
    "taps the alarm:",
)

private val SHORT_ENGLISH_ENDINGS = listOf(
    "medication time!", "your dose is waiting.", "your dose time is here.",
    "open the app.", "your medication waits.",
    "the clock says: dose.", "your dose is ready.",
    "take care of yourself.", "your dose is due.",
    "a helpful little nudge.", "the dose round begins.",
    "check the app.", "your helper is here.",
    "dose time confirmed.", "right on schedule.",
    "no panic, just your dose.", "time for your routine.",
    "your reminder is here.", "the medication clock rings.", "a nudge for your dose.",
    "give your dose a moment.", "the team votes: dose.",
    "check today’s dose.", "protocol says: dose time.",
    "finish it in the app.", "your dose says hello.",
)

private val SHORT_GERMAN_OPENINGS = listOf(
    "tippt auf die Uhr:", "steht bereit:", "{sound} sanft:",
    "schaut dich an:", "dreht eine schnelle Runde:", "{sound} in deiner Nähe:",
    "startet die Erinnerung:", "hat Neuigkeiten:", "meldet sich:",
    "ist dein Dosis-Coach:", "springt auf:", "hat ein Update:",
    "steht stolz da:", "öffnet den Planer:", "unterbricht das Nickerchen:",
    "zeigt auf die Uhr:", "testet das Mikrofon:", "übernimmt die Erinnerung:",
    "tippt den Alarm an:",
)

private val SHORT_GERMAN_ENDINGS = listOf(
    "Medikamentenzeit!", "deine Dosis wartet.", "die Zeit für deine Dosis ist da.",
    "öffne die App.", "dein Medikament wartet.", "die Uhr sagt: Dosis.",
    "deine Dosis ist bereit.", "pass gut auf dich auf.", "deine Dosis ist fällig.",
    "ein kleiner hilfreicher Hinweis.", "die Dosisrunde beginnt.", "schau in die App.",
    "dein Helfer ist da.", "Dosiszeit bestätigt.", "genau nach Plan.",
    "keine Panik, nur deine Dosis.", "Zeit für deine Routine.", "deine Erinnerung ist da.",
    "die Medikamentenuhr klingelt.", "ein Hinweis für deine Dosis.",
    "nimm dir einen Moment für deine Dosis.", "das Team stimmt für die Dosis.",
    "prüfe die heutige Dosis.", "das Protokoll sagt: Dosiszeit.",
    "schließe es in der App ab.", "deine Dosis sagt Hallo.",
)

private val SHORT_FRENCH_OPENINGS = listOf(
    "tapote la montre :", "se tient prêt :", "{sound} doucement :",
    "vous regarde :", "fait un petit tour :", "{sound} tout près :",
    "active le mode rappel :", "a une nouvelle :", "vient faire son rapport :",
    "est votre coach de dose :", "se lève d’un bond :", "a une mise à jour :",
    "se tient fièrement :", "ouvre le planning :", "interrompt la sieste :",
    "montre l’horloge :", "teste le microphone :", "prend son tour de rappel :",
    "tapote l’alarme :",
)

private val SHORT_FRENCH_ENDINGS = listOf(
    "c’est l’heure du médicament !", "votre dose vous attend.", "l’heure de votre dose est arrivée.",
    "ouvrez l’app.", "votre médicament vous attend.", "l’horloge dit : la dose.",
    "votre dose est prête.", "prenez soin de vous.", "votre dose est prévue.",
    "un petit rappel utile.", "la tournée des doses commence.", "consultez l’app.",
    "votre assistant est là.", "heure de la dose confirmée.", "pile à l’heure.",
    "pas de panique, juste votre dose.", "c’est l’heure de votre routine.", "votre rappel est arrivé.",
    "l’horloge du médicament sonne.", "un petit rappel pour votre dose.",
    "accordez un moment à votre dose.", "l’équipe vote : la dose.",
    "vérifiez la dose du jour.", "le protocole dit : heure de la dose.",
    "terminez dans l’app.", "votre dose vous dit bonjour.",
)

private val SHORT_SPANISH_OPENINGS = listOf(
    "toca el reloj:", "está listo:", "{sound} suavemente:",
    "te mira:", "da una vuelta rápida:", "{sound} cerca:",
    "activa el modo recordatorio:", "tiene noticias:", "se presenta:",
    "es tu guía de dosis:", "se levanta de un salto:", "tiene una novedad:",
    "se pone con orgullo:", "abre el planificador:", "interrumpe la siesta:",
    "señala el reloj:", "prueba el micrófono:", "se encarga del recordatorio:",
    "toca la alarma:",
)

private val SHORT_SPANISH_ENDINGS = listOf(
    "¡hora del medicamento!", "tu dosis está esperando.", "ha llegado la hora de tu dosis.",
    "abre la app.", "tu medicamento espera.", "el reloj dice: dosis.",
    "tu dosis está lista.", "cuídate mucho.", "tu dosis está pendiente.",
    "un pequeño aviso útil.", "empieza la ronda de dosis.", "consulta la app.",
    "tu ayudante está aquí.", "hora de la dosis confirmada.", "justo a tiempo.",
    "sin pánico, solo tu dosis.", "hora de tu rutina.", "tu recordatorio está aquí.",
    "suena el reloj del medicamento.", "un aviso para tu dosis.",
    "dedica un momento a tu dosis.", "el equipo vota: dosis.",
    "comprueba la dosis de hoy.", "el protocolo dice: hora de la dosis.",
    "termínalo en la app.", "tu dosis dice hola.",
)

private fun catReminderMessage(name: String, languageCode: String, index: Int): String {
    val normalized = index.mod(500)
    val dutch = languageCode == "nl"
    val special = if (dutch) {
        listOf(
            "$name miauwt extra hard; Donna is duidelijk jaloers op alle aandacht voor je medicatiemoment.",
            "Donna kijkt een tikje jaloers toe terwijl $name je eraan herinnert dat het medicatietijd is.",
            "$name staat klaar voor je dosis, en Donna vraagt zich jaloers af waar haar applaus blijft.",
            "dimi wil $name bijna wegjagen uit jaloezie, maar eerst is het tijd voor je medicatie.",
            "$name bewaakt je medicatiemoment terwijl dimi jaloers plannen maakt om de kat weg te jagen.",
            "Volgens $name probeert dimi uit jaloezie de kat weg te jagen; laat je dosis niet wachten.",
        )
    } else {
        listOf(
            "$name meows extra loudly; Donna is clearly jealous of all the attention around medication time.",
            "Donna watches a little jealously while $name reminds you that it is medication time.",
            "$name is ready for your dose, while Donna jealously wonders where her applause went.",
            "dimi is jealous enough to chase $name away, but first it is time for your medication.",
            "$name guards medication time while dimi jealously plans to chase the cat away.",
            "According to $name, dimi wants to chase the cat away out of jealousy; do not keep your dose waiting.",
        )
    }
    if (normalized < special.size) return special[normalized]
    val openings = if (dutch) DUTCH_CAT_OPENINGS else ENGLISH_CAT_OPENINGS
    val endings = if (dutch) DUTCH_CAT_ENDINGS else ENGLISH_CAT_ENDINGS
    val value = normalized - special.size
    return "$name ${openings[value / endings.size]} ${endings[value % endings.size]}"
}

private val DUTCH_CAT_OPENINGS = listOf(
    "tikt denkbeeldig op een horloge:",
    "staat bij het denkbeeldige medicijnkastje klaar:",
    "heeft de officiële miauwbel geluid:",
    "kijkt je uiterst betekenisvol aan:",
    "loopt een ererondje en verkondigt:",
    "stuurt vanaf de vensterbank een dringende miauw:",
    "heeft de snorharen op herinneringsstand gezet:",
    "doet alsof de voerbak een luidspreker is:",
    "komt met fluwelen pootjes nieuws brengen:",
    "heeft vandaag de rol van medicatiecoach:",
    "maakt een sprongetje van belangrijkheid:",
    "presenteert het kattennieuws van de dag:",
    "staat met opgeheven staart paraat:",
    "heeft een piepkleine agenda geopend:",
    "onderbreekt de kattensiësta voor één bericht:",
    "kijkt alsof dit op de kattenkalender stond:",
    "heeft de miauwmicrofoon getest en zegt:",
    "neemt de herinneringsdienst bijzonder serieus:",
    "heeft een poot op de denkbeeldige alarmknop:",
)

private val DUTCH_CAT_ENDINGS = listOf(
    "tijd voor je medicatie!",
    "je dosis wacht geduldig op je.",
    "dit is je vriendelijke medicatiemoment.",
    "even naar de app voor je geplande inname.",
    "je medicijnmoment wil graag aandacht.",
    "miauw betekent vandaag: medicatietijd.",
    "de klok zegt dosis, de kat zegt miauw.",
    "tijd om goed voor jezelf te zorgen.",
    "je geplande inname staat voor de deur.",
    "een kleine herinnering met grote snorharen.",
    "de dosisronde van vandaag begint nu.",
    "open de app en bekijk je medicatiemoment.",
    "je gezondheidsteam op vier poten meldt zich.",
    "de kattendienst heeft medicatietijd bevestigd.",
    "deze miauw is officieel medisch gepland.",
    "geen paniek, alleen een belangrijke dosis.",
    "het is tijd voor de volgende goede gewoonte.",
    "je herinnering komt vandaag met extra kattenkracht.",
    "de medicatieklok heeft zojuist gemiauwd.",
    "een pootvriendelijk seintje voor je dosis.",
    "je geplande medicatie verdient nu een momentje.",
    "de snorharencommissie stemt voor innametijd.",
    "controleer in de app wat er voor nu gepland staat.",
    "het kattenprotocol zegt: medicatiemoment.",
    "maak van deze herinnering een afgeronde taak.",
    "je dosis heeft een miauwende woordvoerder gestuurd.",
)

private val ENGLISH_CAT_OPENINGS = listOf(
    "taps an imaginary watch:",
    "is waiting by the imaginary medicine cabinet:",
    "has rung the official meow bell:",
    "gives you an extremely meaningful look:",
    "takes a victory lap and announces:",
    "sends an urgent meow from the windowsill:",
    "has set those whiskers to reminder mode:",
    "pretends the food bowl is a loudspeaker:",
    "brings news on velvet paws:",
    "is serving as your medication coach today:",
    "does a tiny jump of importance:",
    "presents today’s cat news:",
    "stands ready with tail held high:",
    "has opened a very small planner:",
    "interrupts the catnap for one message:",
    "looks as if this was on the cat calendar:",
    "tested the meow microphone and says:",
    "takes reminder duty very seriously:",
    "has one paw on the imaginary alarm button:",
)

private val ENGLISH_CAT_ENDINGS = listOf(
    "it is time for your medication!",
    "your dose is patiently waiting for you.",
    "this is your friendly medication moment.",
    "open the app for your scheduled dose.",
    "your medication moment would like some attention.",
    "today, meow means medication time.",
    "the clock says dose and the cat says meow.",
    "it is time to take good care of yourself.",
    "your scheduled dose is at the door.",
    "a small reminder with very big whiskers.",
    "today’s dose round begins now.",
    "open the app and check your medication moment.",
    "your four-pawed health team is reporting for duty.",
    "the cat service has confirmed medication time.",
    "this meow is officially medically scheduled.",
    "no panic, just an important dose.",
    "it is time for the next good habit.",
    "your reminder comes with extra cat power today.",
    "the medication clock just meowed.",
    "a paw-friendly signal for your dose.",
    "your scheduled medication deserves a moment now.",
    "the whisker committee votes for dose time.",
    "check the app to see what is scheduled now.",
    "cat protocol says: medication moment.",
    "turn this reminder into a completed task.",
    "your dose sent a meowing spokesperson.",
)

private fun requestCode(value: String): Int = value.hashCode().absoluteValue
private fun notificationId(token: String): Int =
    (token.hashCode() xor 0x4d454f57).absoluteValue
private fun nextDifferentIndex(length: Int, previous: Int): Int {
    if (length <= 1) return 0
    if (previous < 0) return Random.nextInt(length)
    var next = Random.nextInt(length - 1)
    if (next >= previous) next += 1
    return next
}

private fun nextDifferentThemeIndex(length: Int, previous: Int): Int {
    if (previous < 0) return Random.nextInt(length)
    val choices = (0 until length).filter { index ->
        index != previous && index % 8 != previous % 8 && index % 4 != previous % 4
    }
    return choices.random()
}
