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
                    var alarmFiredInCycle = false

                    if (!ordersJson.isNullOrEmpty()) {
                        val jsonArray = JSONArray(ordersJson)
                        val url = URL("https://api.binance.com/api/v3/ticker/price")
                        val conn = url.openConnection() as HttpURLConnection
                        conn.connectTimeout = 4000
                        conn.readTimeout = 4000
                        conn.setRequestProperty("User-Agent", "Mozilla/5.0 MiCriptoSentinel/1.7")

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
                                        putExtra("total_profit", "+$84.33 USDT")
                                        putExtra("liquid_cash", "$0.91 USDT")
                                    }
                                    context.sendBroadcast(alarmIntent)
                                    alarmFiredInCycle = true
                                    break
                                }
                            }
                        }
                    }

                    // 2B. Escaneo Smart Engine 2.2 (S+ >= 90%) cada 3 minutos (cada 3er ciclo de 60s) directo en Doze Mode
                    val scanCounter = prefs.getInt("splus_scan_counter", 0) + 1
                    prefs.edit().putInt("splus_scan_counter", scanCounter).apply()
                    if (!alarmFiredInCycle && scanCounter % 3 == 0) {
                        scanSmartEngineSPlus1H(context, prefs)
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

    /**
     * Escáner Nativo Smart Engine 2.2 (100% Paridad con smcEngine.ts de la Web) en Segundo Plano (Doze Mode)
     * Evalúa cada 3 minutos la estructura 1H de las 10 monedas institucionales directo contra Binance.
     */
    private fun scanSmartEngineSPlus1H(context: Context, prefs: android.content.SharedPreferences) {
        val watchedSymbols = listOf(
            "RENDERUSDT", "SUIUSDT", "NEARUSDT", "PENDLEUSDT", "XRPUSDT",
            "ONDOUSDT", "TAOUSDT", "ALGOUSDT", "HBARUSDT", "XLMUSDT"
        )
        val nowMs = System.currentTimeMillis()

        for (sym in watchedSymbols) {
            try {
                // Cooldown de 4 horas por moneda para evitar alarmas repetidas en la misma barrida
                val lastTrigMs = prefs.getLong("splus_last_trig_$sym", 0L)
                if (nowMs - lastTrigMs < 4 * 3600 * 1000L) continue

                val url = URL("https://api.binance.com/api/v3/klines?symbol=$sym&interval=1h&limit=180")
                val conn = url.openConnection() as HttpURLConnection
                conn.connectTimeout = 3500
                conn.readTimeout = 3500
                conn.setRequestProperty("User-Agent", "Mozilla/5.0 MiCriptoSentinel/1.8")

                if (conn.responseCode != 200) continue
                val raw = JSONArray(conn.inputStream.bufferedReader().readText())
                val len = raw.length()
                if (len < 60) continue

                val opens = DoubleArray(len)
                val highs = DoubleArray(len)
                val lows = DoubleArray(len)
                val closes = DoubleArray(len)
                for (i in 0 until len) {
                    val k = raw.getJSONArray(i)
                    opens[i] = k.getString(1).toDouble()
                    highs[i] = k.getString(2).toDouble()
                    lows[i] = k.getString(3).toDouble()
                    closes[i] = k.getString(4).toDouble()
                }

                // Calcular RSI(14)
                val rsi = DoubleArray(len) { 50.0 }
                var gains = 0.0
                var losses = 0.0
                for (i in 1..14) {
                    val diff = closes[i] - closes[i - 1]
                    if (diff >= 0) gains += diff else losses -= diff
                }
                var avgGain = gains / 14.0
                var avgLoss = losses / 14.0
                rsi[14] = if (avgLoss == 0.0) 100.0 else 100.0 - (100.0 / (1.0 + (avgGain / avgLoss)))
                for (i in 15 until len) {
                    val diff = closes[i] - closes[i - 1]
                    val g = if (diff >= 0) diff else 0.0
                    val l = if (diff < 0) -diff else 0.0
                    avgGain = ((avgGain * 13.0) + g) / 14.0
                    avgLoss = ((avgLoss * 13.0) + l) / 14.0
                    rsi[i] = if (avgLoss == 0.0) 100.0 else 100.0 - (100.0 / (1.0 + (avgGain / avgLoss)))
                }

                // 1. Identify Swing Lows (lookback = 4) y evaluar ÚNICAMENTE el primer barrido (2do toque SFP real, igual que smcEngine.ts)
                val lookback = 4
                var sPlusTriggered = false
                var floorPrice = 0.0
                var drop48hPct = 0.0
                var sweepClosePrice = closes[len - 1]

                for (i in lookback until len - lookback) {
                    var isLow = true
                    for (j in (i - lookback)..(i + lookback)) {
                        if (j == i) continue
                        if (lows[j] <= lows[i]) {
                            isLow = false
                            break
                        }
                    }
                    if (!isLow) continue

                    val swPrice = lows[i]
                    var swept = false
                    var sweptIdx = -1

                    for (k in (i + 1) until len) {
                        if (k <= i + 4) {
                            if (lows[k] < swPrice * 0.997) break
                            continue
                        }
                        if (k - i > 180) break

                        if (lows[k] < swPrice) {
                            if (closes[k] > swPrice) {
                                swept = true
                                sweptIdx = k
                            }
                            break // Crítico: se detiene en el PRIMER toque debajo de swPrice
                        }
                    }

                    if (!swept || sweptIdx < 48) continue
                    val candleAge = len - 1 - sweptIdx
                    if (candleAge > 2) continue // Solo barridas frescas vigentes ahora

                    var high48h = 0.0
                    for (m in kotlin.math.max(0, sweptIdx - 48) until sweptIdx) {
                        if (highs[m] > high48h) high48h = highs[m]
                    }
                    val dropPct = if (high48h > 0) ((high48h - lows[sweptIdx]) / high48h) * 100.0 else 0.0
                    if (dropPct < 3.5) continue

                    // CHoCH Envolvente Inmediato estricto (closes[sweptIdx] > highs[sweptIdx - 1])
                    val immediateChoch = closes[sweptIdx] > highs[sweptIdx - 1] && closes[sweptIdx] > opens[sweptIdx]
                    val rsiDiv = (rsi[sweptIdx] > rsi[i] + 1.5 && rsi[i] < 46.0) || (rsi[sweptIdx] < 48.0)

                    // Verificar drift <= 1.0%
                    val driftPct = ((closes[len - 1] - closes[sweptIdx]) / closes[sweptIdx]) * 100.0
                    if (immediateChoch && rsiDiv && driftPct <= 1.0) {
                        sPlusTriggered = true
                        floorPrice = swPrice
                        drop48hPct = dropPct
                        sweepClosePrice = closes[sweptIdx]
                        break
                    }
                }

                if (sPlusTriggered) {
                    prefs.edit().putLong("splus_last_trig_$sym", nowMs).apply()
                    val dispSym = sym.replace("USDT", "")
                    val tp1 = sweepClosePrice * 1.030
                    val tp2 = sweepClosePrice * 1.055
                    val slTrig = sweepClosePrice * 0.972
                    val slLim = slTrig * 0.9985

                    FileLogger.logInfo(
                        context,
                        "⭐ [DOZE S+ DETECTADO] $dispSym activó compra S+ (92.3% WR) @ $$sweepClosePrice | Suelo: $$floorPrice"
                    )

                    val alarmIntent = Intent(context, SentinelAlarmReceiver::class.java).apply {
                        putExtra("symbol", "$dispSym / USDT (S+ >=90%)")
                        putExtra("event_type", "S_PLUS_ALPHA")
                        putExtra("price", String.format(Locale.US, "$%.4f", sweepClosePrice))
                        putExtra("amount", String.format(Locale.US, "SUELO 1H: $%.4f (-%.1f%% 48h)", floorPrice, drop48hPct))
                        putExtra("target_price", String.format(Locale.US, "TP1: $%.4f | TP2: $%.4f", tp1, tp2))
                        putExtra("projected_profit", String.format(Locale.US, "OCO SL Trigger: $%.4f (-2.8%%) | Limit: $%.4f", slTrig, slLim))
                        putExtra("total_profit", "92.3% WIN RATE (S+)")
                        putExtra("liquid_cash", "$0.91 USDT")
                    }
                    context.sendBroadcast(alarmIntent)
                    break
                }
            } catch (_: Exception) {
                // Continuar con la siguiente moneda sin interrumpir el ciclo Doze
            }
        }
    }
}
