package com.richard.micripto.micripto_sentinel

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.SystemClock
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val CHANNEL = "com.richard.micripto/sentinel_alarm"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Suscripción automática a tópicos de alertas
        com.google.firebase.messaging.FirebaseMessaging.getInstance().subscribeToTopic("sentinel_alerts")

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "triggerImmediateAlarm" -> {
                    val args = call.arguments as? Map<String, Any?> ?: emptyMap()
                    launchAlarmActivity(args)
                    result.success(true)
                }
                "scheduleTestAlarm" -> {
                    val delaySeconds = call.argument<Int>("delaySeconds") ?: 5
                    val args = call.argument<Map<String, Any?>>("data") ?: emptyMap()
                    scheduleAlarm(delaySeconds, args)
                    result.success(true)
                }
                "openBinance" -> {
                    openBinanceApp()
                    result.success(true)
                }
                "getFcmToken" -> {
                    com.google.firebase.messaging.FirebaseMessaging.getInstance().token
                        .addOnCompleteListener { task ->
                            if (task.isSuccessful) {
                                result.success(task.result)
                            } else {
                                val prefs = getSharedPreferences(SentinelFirebaseService.PREFS_NAME, Context.MODE_PRIVATE)
                                val cached = prefs.getString(SentinelFirebaseService.KEY_FCM_TOKEN, null)
                                result.success(cached)
                            }
                        }
                }
                "getLogs" -> {
                    val logs = FileLogger.getLogs(this)
                    result.success(logs)
                }
                "clearLogs" -> {
                    FileLogger.clearLogs(this)
                    result.success(true)
                }
                "getSoundMode" -> {
                    val prefs = getSharedPreferences("sentinel_settings", Context.MODE_PRIVATE)
                    val mode = prefs.getString("sound_mode", "ALWAYS") ?: "ALWAYS"
                    result.success(mode)
                }
                "setSoundMode" -> {
                    val mode = call.argument<String>("mode") ?: "ALWAYS"
                    val prefs = getSharedPreferences("sentinel_settings", Context.MODE_PRIVATE)
                    prefs.edit().putString("sound_mode", mode).apply()
                    FileLogger.logInfo(this, "⚙️ Modo de Sonido actualizado a: $mode")
                    result.success(true)
                }
                "logEvent" -> {
                    val message = call.argument<String>("message") ?: ""
                    FileLogger.logInfo(this, "[UI] $message")
                    result.success(true)
                }
                "checkOverlayPermission" -> {
                    val canDraw = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        android.provider.Settings.canDrawOverlays(this)
                    } else {
                        true
                    }
                    result.success(canDraw)
                }
                "requestOverlayPermission" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && !android.provider.Settings.canDrawOverlays(this)) {
                        val intent = Intent(
                            android.provider.Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                            Uri.parse("package:$packageName")
                        )
                        startActivity(intent)
                    }
                    result.success(true)
                }
                "saveCachedOrders" -> {
                    val ordersJson = call.argument<String>("ordersJson") ?: "[]"
                    val prefs = getSharedPreferences("sentinel_orders_prefs", Context.MODE_PRIVATE)
                    prefs.edit().putString("cached_orders_json", ordersJson).apply()
                    FileLogger.logInfo(this, "💾 [Orders] Órdenes dinámicas guardadas en SharedPreferences nativo")
                    result.success(true)
                }
                "getCachedOrders" -> {
                    val prefs = getSharedPreferences("sentinel_orders_prefs", Context.MODE_PRIVATE)
                    val ordersJson = prefs.getString("cached_orders_json", null)
                    result.success(ordersJson)
                }
                "startNativeBackgroundScan" -> {
                    SentinelAlarmReceiver.scheduleNextScan(this, 10) // Primer escaneo en 10s
                    FileLogger.logInfo(this, "🟢 [Sentinel] Escaneo de fondo nativo activado 24/7")
                    result.success(true)
                }
                "stopNativeBackgroundScan" -> {
                    SentinelAlarmReceiver.stopScanning(this)
                    FileLogger.logInfo(this, "🛑 [Sentinel] Escaneo de fondo nativo pausado")
                    result.success(true)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun launchAlarmActivity(args: Map<String, Any?>) {
        val intent = Intent(this, AlarmActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra("event_type", args["eventType"]?.toString() ?: "BUY_FILLED")
            putExtra("symbol", args["symbol"]?.toString() ?: "SUI / USDT")
            putExtra("price", args["price"]?.toString() ?: "$1.0020")
            putExtra("amount", args["amount"]?.toString() ?: "149.7 SUI ($149.99 USDT)")
            putExtra("target_price", args["targetPrice"]?.toString() ?: "$1.0650")
            putExtra("projected_profit", args["projectedProfit"]?.toString() ?: "+$9.12 USDT (+6.08%)")
            putExtra("total_profit", args["totalProfit"]?.toString() ?: "+$41.56 USDT")
            putExtra("liquid_cash", args["liquidCash"]?.toString() ?: "$345.84 USDT")
        }
        startActivity(intent)
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            if (checkSelfPermission(android.Manifest.permission.POST_NOTIFICATIONS) != android.content.pm.PackageManager.PERMISSION_GRANTED) {
                requestPermissions(arrayOf(android.Manifest.permission.POST_NOTIFICATIONS), 101)
            }
        }
    }

    private fun scheduleAlarm(delaySeconds: Int, args: Map<String, Any?>) {
        val alarmManager = getSystemService(Context.ALARM_SERVICE) as? AlarmManager ?: return
        val intent = Intent(this, SentinelAlarmReceiver::class.java).apply {
            putExtra("event_type", args["eventType"]?.toString() ?: "BUY_FILLED")
            putExtra("symbol", args["symbol"]?.toString() ?: "SUI / USDT")
            putExtra("price", args["price"]?.toString() ?: "$1.0020")
            putExtra("amount", args["amount"]?.toString() ?: "149.7 SUI ($149.99 USDT)")
            putExtra("target_price", args["targetPrice"]?.toString() ?: "$1.0650")
            putExtra("projected_profit", args["projectedProfit"]?.toString() ?: "+$9.12 USDT (+6.08%)")
            putExtra("total_profit", args["totalProfit"]?.toString() ?: "+$41.56 USDT")
            putExtra("liquid_cash", args["liquidCash"]?.toString() ?: "$345.84 USDT")
        }

        val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        } else {
            PendingIntent.FLAG_UPDATE_CURRENT
        }

        val pendingIntent = PendingIntent.getBroadcast(this, 1001, intent, flags)
        val triggerEpoch = System.currentTimeMillis() + (delaySeconds * 1000L)

        try {
            val clockInfo = AlarmManager.AlarmClockInfo(triggerEpoch, pendingIntent)
            alarmManager.setAlarmClock(clockInfo, pendingIntent)
            FileLogger.logInfo(this, "⏰ [MainActivity] setAlarmClock programado hacia Receiver a las $triggerEpoch (en ${delaySeconds}s)")
        } catch (e: Exception) {
            FileLogger.logWarning(this, "⚠️ Fallback de setAlarmClock: ${e.message}")
            try {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    alarmManager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerEpoch, pendingIntent)
                } else {
                    alarmManager.setExact(AlarmManager.RTC_WAKEUP, triggerEpoch, pendingIntent)
                }
                FileLogger.logInfo(this, "⏰ [MainActivity] Fallback setExact programado a las $triggerEpoch")
            } catch (e2: Exception) {
                FileLogger.logError(this, "❌ Error programando alarma", e2)
            }
        }
    }

    private fun openBinanceApp() {
        try {
            val launchIntent = packageManager.getLaunchIntentForPackage("com.binance.dev")
            if (launchIntent != null) {
                startActivity(launchIntent)
            } else {
                val webIntent = Intent(Intent.ACTION_VIEW, Uri.parse("https://www.binance.com/"))
                startActivity(webIntent)
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }
}
