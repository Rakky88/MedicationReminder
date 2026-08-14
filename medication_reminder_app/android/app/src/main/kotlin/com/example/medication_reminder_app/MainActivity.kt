package nl.rickgroot.medicationreminder

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import org.json.JSONObject

class MainActivity : FlutterActivity() {
    private var channel: MethodChannel? = null
    private var pendingLaunchAction: Map<String, Any?>? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        pendingLaunchAction = actionFromIntent(intent)
        channel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            ESCALATION_CHANNEL,
        ).also { methodChannel ->
            methodChannel.setMethodCallHandler { call, result ->
                when (call.method) {
                    "replacePlans" -> {
                        val arguments = call.arguments as? Map<*, *>
                        val plans = (arguments?.get("plans") as? List<*>)
                            ?.mapNotNull { it as? Map<*, *> }
                            ?.map { JSONObject(it) }
                            ?: emptyList()
                        val medicationIds = (arguments?.get("activeMedicationIds") as? List<*>)
                            ?.mapNotNull { (it as? Number)?.toInt() }
                            ?.toSet()
                            ?: emptySet()
                        EscalationStore.replacePlans(this, plans, medicationIds)
                        result.success(null)
                    }

                    "snoozeEscalation" -> {
                        val doseKey = call.argument<String>("doseKey")
                        result.success(
                            if (doseKey == null) -1
                            else EscalationStore.snooze(this, doseKey),
                        )
                    }

                    "resolveMedication" -> {
                        val medicationId = call.argument<Number>("medicationId")?.toInt()
                        if (medicationId != null) {
                            EscalationStore.resolveMedication(this, medicationId)
                        }
                        result.success(null)
                    }

                    "resolveDose" -> {
                        val doseKey = call.argument<String>("doseKey")
                        if (doseKey != null) EscalationStore.resolveDose(this, doseKey)
                        result.success(null)
                    }

                    "takeLaunchAction" -> {
                        result.success(pendingLaunchAction)
                        pendingLaunchAction = null
                    }

                    "getLocalTimeZone" -> result.success(java.util.TimeZone.getDefault().id)

                    else -> result.notImplemented()
                }
            }
        }
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            APP_LINKS_CHANNEL,
        ).setMethodCallHandler { call, result ->
            if (call.method != "openUrl") {
                result.notImplemented()
                return@setMethodCallHandler
            }
            val value = call.argument<String>("url")
            val uri = value?.let(android.net.Uri::parse)
            if (uri == null || uri.scheme != "https" || uri.host.isNullOrBlank()) {
                result.success(false)
                return@setMethodCallHandler
            }
            try {
                startActivity(Intent(Intent.ACTION_VIEW, uri))
                result.success(true)
            } catch (_: android.content.ActivityNotFoundException) {
                result.success(false)
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        val action = actionFromIntent(intent) ?: return
        channel?.invokeMethod("notificationOpened", action)
    }

    private fun actionFromIntent(source: Intent?): Map<String, Any?>? {
        val sourceIntent = source ?: return null
        val medicationId = sourceIntent.getIntExtra(EXTRA_MEDICATION_ID, -1)
        if (medicationId < 0) return null
        sourceIntent.removeExtra(EXTRA_MEDICATION_ID)
        val doseKey = sourceIntent.getStringExtra(EXTRA_DOSE_KEY)
        sourceIntent.removeExtra(EXTRA_DOSE_KEY)
        return mapOf("medicationId" to medicationId, "doseKey" to doseKey)
    }

    companion object {
        const val ESCALATION_CHANNEL = "medication_reminder/escalation"
        const val APP_LINKS_CHANNEL = "medication_reminder/app_links"
        const val EXTRA_MEDICATION_ID = "medication_id"
        const val EXTRA_DOSE_KEY = "dose_key"
    }
}
