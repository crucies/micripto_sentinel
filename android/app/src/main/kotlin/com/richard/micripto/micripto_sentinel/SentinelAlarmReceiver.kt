package com.richard.micripto.micripto_sentinel

import android.app.AlarmManager
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import androidx.core.app.NotificationCompat
import org.json.JSONArray
import org.json.JSONObject
import java.net.HttpURLConnection
import java.net.URL
import java.util.Locale

class SentinelAlarmReceiver : BroadcastReceiver() {

    companion object {
        const val CHANNEL_ID = "sentinel_emergency_v4"
        const val NOTIFICATION_ID = 1001
        const val ACTION_SILENCE = "com.richard.micripto.ACTION_SILENCE"
        const val ACTION_SENTINEL_SCAN = "com.richard.micripto.ACTION_SENTINEL_SCAN"

        fun scheduleNextScan(context: Context, delaySeconds: Int = 60) {
            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as? AlarmManager ?: return
            val scanIntent = Intent(context, SentinelAlarmReceiver::class.java).apply {
                action = ACTION_SENTINEL_SCAN
            }
            val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            } else {
                PendingIntent.FLAG_UPDATE_CURRENT
            }
            val pendingIntent = PendingIntent.getBroadcast(context, 2005, scanIntent, flags)
            val triggerTime = System.currentTimeMillis() + (delaySeconds * 1000L)

            try {
                val clockInfo = AlarmManager.AlarmClockInfo(triggerTime, pendingIntent)
                alarmManager.setAlarmClock(clockInfo, pendingIntent)
            } catch (e: Exception) {
                try {
                    alarmManager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerTime, pendingIntent)
                } catch (_: Exception) {}
            }
        }

        fun stopScanning(context: Context) {
            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as? AlarmManager ?: return
            val scanIntent = Intent(context, SentinelAlarmReceiver::class.java).apply {
                action = ACTION_SENTINEL_SCAN
            }
            val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            } else {
                PendingIntent.FLAG_UPDATE_CURRENT
            }
            val pendingIntent = PendingIntent.getBroadcast(context, 2005, scanIntent, flags)
            alarmManager.cancel(pendingIntent)
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        // 1. Manejar acción rápida de silenciar desde la notificación
        if (intent.action == ACTION_SILENCE) {
            SentinelAudioManager.stop()
            val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
            nm?.cancel(NOTIFICATION_ID)
            FileLogger.logInfo(context, "🔕 [Receiver] Alarma silenciada desde la notificación")
            return
        }

        // 2. Manejar Escaneo Autónomo de Binance en Segundo Plano (Doze Mode)
        if (intent.action == ACTION_SENTINEL_SCAN) {
            Thread {
                try {
                    val prefs = context.getSharedPreferences("sentinel_orders_prefs", Context.MODE_PRIVATE)
                    val ordersJson = prefs.getString("cached_orders_json", null)
                    if (!ordersJson.isNullOrEmpty()) {
                        val jsonArray = JSONArray(ordersJson)
                        val url = URL("https://api.binance.com/api/v3/ticker/price")
                        val conn = url.openConnection() as HttpURLConnection
                        conn.connectTimeout = 4000
                        conn.readTimeout = 4000
                        conn.setRequestProperty("User-Agent", "Mozilla/5.0 MiCriptoSentinel/1.0")

                        if (conn.responseCode == 200) {
                            val resp = conn.inputStream.bufferedReader().readText()
                            val priceArray = JSONArray(resp)
                            val priceMap = mutableMapOf<String, Double>()
                            for (i in 0 until priceArray.length()) {
                                val obj = priceArray.getJSONObject(i)
                                priceMap[obj.getString("symbol")] = obj.getDouble("price")
                            }

                            for (i in 0 until jsonArray.length()) {
                                val order = jsonArray.getJSONObject(i)
                                val sym = order.getString("symbol")
                                val target = order.getDouble("targetPrice")
                                val side = order.optString("side", "SELL")
                                val curPrice = priceMap[sym] ?: continue
                                val triggeredKey = "triggered_" + order.optString("id", sym)
                                val alreadyTriggered = prefs.getBoolean(triggeredKey, false)

                                val isHit = if (side.equals("BUY", ignoreCase = true)) {
                                    curPrice <= target
                                } else {
                                    curPrice >= target
                                }

                                if (isHit && !alreadyTriggered) {
                                    prefs.edit().putBoolean(triggeredKey, true).apply()
                                    val dispSym = order.optString("displaySymbol", sym)
                                    FileLogger.logInfo(context, "🎯 ¡OBJETIVO ALCANZADO EN BINANCE! $dispSym tocó $$curPrice (Meta: $$target). DISPARANDO ALARMA...")

                                    val alarmIntent = Intent(context, SentinelAlarmReceiver::class.java).apply {
                                        putExtra("symbol", dispSym)
                                        putExtra("event_type", if (side.equals("BUY", ignoreCase = true)) "BUY_FILLED" else "TP_HIT")
                                        putExtra("price", String.format(Locale.US, "$%.4f", curPrice))
                                        putExtra("amount", "${order.optDouble("amountCoins")} (${order.optDouble("expectedReturnUsdt")} USDT)")
                                        putExtra("target_price", String.format(Locale.US, "$%.4f", target))
                                        putExtra("projected_profit", "+$${order.optDouble("projectedProfitUsdt")} USDT")
                                        putExtra("total_profit", "+$79.13 USDT")
                                        putExtra("liquid_cash", "$36.59 USDT")
                                    }
                                    context.sendBroadcast(alarmIntent)
                                    break
                                }
                            }
                        }
                    }
                } catch (e: Exception) {
                    FileLogger.logWarning(context, "⚠️ Error en escaneo nativo: ${e.message}")
                } finally {
                    // Reprogramar el siguiente escaneo exacto en 60s
                    scheduleNextScan(context, 60)
                }
            }.start()
            return
        }

        // 3. Disparo Real de Alarma (Alcanzó TP o Compra)
        val symbol = intent.getStringExtra("symbol") ?: "BINANCE SPOT"
        val eventType = intent.getStringExtra("event_type") ?: "BUY_FILLED"
        FileLogger.logInfo(context, "🚨 [Receiver] Disparo de alarma recibido: $symbol ($eventType)")

        // Audio Táctico Inmediato al 100%
        SentinelAudioManager.play(context)

        // Despertar pantalla de inmediato con WakeLock agresivo
        try {
            val pm = context.getSystemService(Context.POWER_SERVICE) as? PowerManager
            @Suppress("DEPRECATION")
            val wl = pm?.newWakeLock(
                PowerManager.SCREEN_BRIGHT_WAKE_LOCK or
                PowerManager.ACQUIRE_CAUSES_WAKEUP or
                PowerManager.ON_AFTER_RELEASE,
                "micripto:receiver_wakeup"
            )
            wl?.acquire(60000) // 1 minuto
            FileLogger.logInfo(context, "💡 [Receiver] WakeLock pantalla brillante adquirido con éxito (60s)")
        } catch (e: Exception) {
            FileLogger.logError(context, "❌ [Receiver] Error adquiriendo WakeLock", e)
        }

        // Preparar Intent para AlarmActivity
        val alarmIntent = Intent(context, AlarmActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                    Intent.FLAG_ACTIVITY_CLEAR_TOP or
                    Intent.FLAG_ACTIVITY_REORDER_TO_FRONT
            putExtras(intent)
        }

        val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        } else {
            PendingIntent.FLAG_UPDATE_CURRENT
        }
        val fullScreenPendingIntent = PendingIntent.getActivity(context, 1001, alarmIntent, flags)

        val silenceIntent = Intent(context, SentinelAlarmReceiver::class.java).apply {
            action = ACTION_SILENCE
        }
        val silencePendingIntent = PendingIntent.getBroadcast(context, 1002, silenceIntent, flags)

        // Crear Canal de Notificación de Máxima Prioridad (Canal V4 Limpio)
        val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "MiCripto Sentinel Alarmas Críticas",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Canal de alarmas críticas para ejecución de órdenes en Binance"
                enableLights(true)
                enableVibration(true)
                vibrationPattern = longArrayOf(0, 350, 150, 350, 150, 500)
                lockscreenVisibility = Notification.VISIBILITY_PUBLIC
                setBypassDnd(true)
            }
            notificationManager.createNotificationChannel(channel)
        }

        val title = when (eventType) {
            "TP_HIT" -> "🎯 ¡TAKE PROFIT EJECUTADO! ($symbol)"
            "S_PLUS_ALPHA" -> "⭐ OPORTUNIDAD RADAR S+ ($symbol)"
            else -> "🟢 COMPRA EN SUELO EJECUTADA ($symbol)"
        }

        val notificationBuilder = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(android.R.drawable.ic_dialog_alert)
            .setContentTitle(title)
            .setContentText("Toca para abrir la tarjeta táctica de Binance")
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setAutoCancel(true)
            .setOngoing(true)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setFullScreenIntent(fullScreenPendingIntent, true)
            .setContentIntent(fullScreenPendingIntent)
            .addAction(android.R.drawable.ic_lock_power_off, "🔕 SILENCIAR", silencePendingIntent)
            .addAction(android.R.drawable.ic_menu_view, "🚀 VER ORDEN", fullScreenPendingIntent)

        notificationManager.notify(NOTIFICATION_ID, notificationBuilder.build())
        FileLogger.logInfo(context, "📢 [Receiver] Notificación FullScreen enviada al sistema (ID: $NOTIFICATION_ID)")

        try {
            context.startActivity(alarmIntent)
            FileLogger.logInfo(context, "🚀 [Receiver] startActivity ejecutado hacia AlarmActivity")
        } catch (e: Exception) {
            FileLogger.logWarning(context, "⚠️ [Receiver] startActivity directo bloqueado por OS: ${e.message}")
        }
    }
}
