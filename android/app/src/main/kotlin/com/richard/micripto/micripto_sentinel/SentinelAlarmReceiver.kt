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

                fun fireKaiAlert(
            context: Context,
            title: String,
            hero: String,
            summary: String,
            action: String,
            timestamp: String,
            liquidCash: String = "$458.59 USDT",
            appVersion: String = "V 0.2.20"
        ) {
            val settingsPrefs = context.getSharedPreferences("sentinel_settings", Context.MODE_PRIVATE)
            val soundMode = settingsPrefs.getString("sound_mode", "ALWAYS") ?: "ALWAYS"
            if (soundMode == "TOTAL_SILENCE") {
                FileLogger.logInfo(context, "🔕 [Receiver] ALERTA KAI SUPRIMIDA por MODO SILENCIO TOTAL")
                return
            }

            FileLogger.logInfo(context, "🔔 [Receiver] Disparo de Informe Táctico Kai: $title")

            // 1. Audio Inmediato
            SentinelAudioManager.play(context)

            // 2. WakeLock agresivo para encender pantalla física
            try {
                val pm = context.getSystemService(Context.POWER_SERVICE) as? PowerManager
                @Suppress("DEPRECATION")
                val wl = pm?.newWakeLock(
                    PowerManager.SCREEN_BRIGHT_WAKE_LOCK or
                    PowerManager.ACQUIRE_CAUSES_WAKEUP or
                    PowerManager.ON_AFTER_RELEASE,
                    "micripto:receiver_kai_wakeup"
                )
                wl?.acquire(60000)
            } catch (e: Exception) {
                FileLogger.logError(context, "Error adquiriendo WakeLock para Kai Alert", e)
            }

            // 3. Preparar Intent para AlarmActivity
            val alarmIntent = Intent(context, AlarmActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                        Intent.FLAG_ACTIVITY_CLEAR_TOP or
                        Intent.FLAG_ACTIVITY_REORDER_TO_FRONT
                putExtra("event_type", "KAI_ANALYSIS")
                putExtra("symbol", "PORTAFOLIO")
                putExtra("kai_title", title)
                putExtra("kai_hero", hero)
                putExtra("kai_summary", summary)
                putExtra("kai_action", action)
                putExtra("kai_timestamp", timestamp)
                putExtra("liquid_cash", liquidCash)
                putExtra("app_version", appVersion)
            }

            val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            } else {
                PendingIntent.FLAG_UPDATE_CURRENT
            }
            val fullScreenPendingIntent = PendingIntent.getActivity(context, 1003, alarmIntent, flags)

            // Canal y Notificación Heads-Up
            val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val channel = NotificationChannel(
                    CHANNEL_ID,
                    "MiCripto Sentinel Alarmas Críticas",
                    NotificationManager.IMPORTANCE_HIGH
                ).apply {
                    description = "Alertas críticas y tácticas de Richard & Kai"
                    enableVibration(true)
                    lockscreenVisibility = Notification.VISIBILITY_PUBLIC
                }
                notificationManager.createNotificationChannel(channel)
            }

            val notif = NotificationCompat.Builder(context, CHANNEL_ID)
                .setSmallIcon(android.R.drawable.ic_dialog_alert)
                .setContentTitle("🧠 " + title)
                .setContentText(hero)
                .setStyle(NotificationCompat.BigTextStyle().bigText(hero + "\n\n" + summary + "\n\n⚡ Acción: " + action))
                .setPriority(NotificationCompat.PRIORITY_MAX)
                .setCategory(NotificationCompat.CATEGORY_ALARM)
                .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
                .setFullScreenIntent(fullScreenPendingIntent, true)
                .setContentIntent(fullScreenPendingIntent)
                .setAutoCancel(true)
                .build()

            notificationManager.notify(NOTIFICATION_ID, notif)

            try {
                context.startActivity(alarmIntent)
            } catch (e: Exception) {
                FileLogger.logError(context, "Error iniciando AlarmActivity para Kai", e)
            }
        }

        fun fireImmediateAlarm(
            context: Context,
            symbol: String,
            eventType: String,
            price: String,
            amount: String,
            targetPrice: String,
            projectedProfit: String,
            totalProfit: String = "+$31.91 USDT",
            liquidCash: String = "$78.45 USDT",
            tp1Price: String = "",
            tp2Price: String = "",
            slPrice: String = "",
            limitBuyPrice: String = "",
            tradeAmount: String = "100.0",
            buyPrice: String = "",
            buyDate: String = "",
            sellDate: String = "",
            elapsedTime: String = "",
            appVersion: String = "V 0.2.17",
            totalCoins: String = ""
        ) {
            val settingsPrefs = context.getSharedPreferences("sentinel_settings", Context.MODE_PRIVATE)
            val soundMode = settingsPrefs.getString("sound_mode", "ALWAYS") ?: "ALWAYS"
            if (soundMode == "TOTAL_SILENCE") {
                FileLogger.logInfo(context, "🔕 [Receiver] ALARMA SUPRIMIDA por MODO SILENCIO TOTAL: $symbol ($eventType)")
                return
            }

            FileLogger.logInfo(context, "🚨 [Receiver] Disparo directo de alarma en Doze: $symbol ($eventType)")

            // 1. Audio Inmediato 100%
            SentinelAudioManager.play(context)

            // 2. WakeLock agresivo para encender pantalla física
            try {
                val pm = context.getSystemService(Context.POWER_SERVICE) as? PowerManager
                @Suppress("DEPRECATION")
                val wl = pm?.newWakeLock(
                    PowerManager.SCREEN_BRIGHT_WAKE_LOCK or
                    PowerManager.ACQUIRE_CAUSES_WAKEUP or
                    PowerManager.ON_AFTER_RELEASE,
                    "micripto:receiver_wakeup"
                )
                wl?.acquire(60000) // 1 minuto encendida
                FileLogger.logInfo(context, "💡 [Receiver] WakeLock pantalla brillante adquirido con éxito (60s)")
            } catch (e: Exception) {
                FileLogger.logError(context, "❌ [Receiver] Error adquiriendo WakeLock", e)
            }

            // 3. Preparar Intent para AlarmActivity
            val alarmIntent = Intent(context, AlarmActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                        Intent.FLAG_ACTIVITY_CLEAR_TOP or
                        Intent.FLAG_ACTIVITY_REORDER_TO_FRONT
                putExtra("symbol", symbol)
                putExtra("event_type", eventType)
                putExtra("price", price)
                putExtra("amount", amount)
                putExtra("target_price", targetPrice)
                putExtra("projected_profit", projectedProfit)
                putExtra("total_profit", totalProfit)
                putExtra("liquid_cash", liquidCash)
                putExtra("tp1_price", tp1Price)
                putExtra("tp2_price", tp2Price)
                putExtra("sl_price", slPrice)
                putExtra("limit_buy_price", limitBuyPrice)
                putExtra("trade_amount", tradeAmount)
                putExtra("buy_price", buyPrice)
                putExtra("buy_date", buyDate)
                putExtra("sell_date", sellDate)
                putExtra("elapsed_time", elapsedTime)
                putExtra("app_version", appVersion)
                putExtra("total_coins", totalCoins)
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

            // Crear Canal de Notificación de Máxima Prioridad
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

    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action

        // 0. Manejar Encendido de Dispositivo o Actualización de Paquete
        if (action == Intent.ACTION_BOOT_COMPLETED ||
            action == "android.intent.action.MY_PACKAGE_REPLACED" ||
            action == "android.intent.action.QUICKBOOT_POWERON" ||
            action == "com.htc.intent.action.QUICKBOOT_POWERON") {
            FileLogger.logInfo(context, "📱 [Receiver] Dispositivo reiniciado / paquete actualizado ($action). Reactivando Centinela 24/7...")
            SentinelForegroundService.start(context)
            scheduleNextScan(context, 15)
            return
        }

        // 1. Manejar acción rápida de silenciar desde la notificación
        if (action == ACTION_SILENCE) {
            SentinelAudioManager.stop()
            val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
            nm?.cancel(NOTIFICATION_ID)
            FileLogger.logInfo(context, "🔕 [Receiver] Alarma silenciada desde la notificación")
            return
        }

        // Asegurar que el Servicio en Primer Plano esté activo
        if (!SentinelForegroundService.isRunning) {
            try {
                SentinelForegroundService.start(context)
            } catch (_: Exception) {}
        }

        // 2. Manejar Escaneo Autónomo de Binance en Segundo Plano (Doze Mode)
        if (action == ACTION_SENTINEL_SCAN) {
            val pendingResult = goAsync()
            val pm = context.getSystemService(Context.POWER_SERVICE) as? PowerManager
            val scanWakeLock = pm?.newWakeLock(
                PowerManager.PARTIAL_WAKE_LOCK,
                "micripto:background_scan_wakelock"
            )
            scanWakeLock?.acquire(25000) // Mantener CPU activa durante HTTP/DNS

            Thread {
                try {
                    val prefs = context.getSharedPreferences("sentinel_orders_prefs", Context.MODE_PRIVATE)
                    val ordersJson = prefs.getString("cached_orders_json", null)
                    var alarmFiredInCycle = false

                    if (!ordersJson.isNullOrEmpty()) {
                        val jsonArray = JSONArray(ordersJson)
                        var resp: String? = null

                        // Retry de 2 intentos para despertar la interfaz de red si la radio móvil estaba dormida
                        for (attempt in 1..2) {
                            try {
                                val url = URL("https://api.binance.com/api/v3/ticker/price")
                                val conn = url.openConnection() as HttpURLConnection
                                conn.connectTimeout = 7000
                                conn.readTimeout = 7000
                                conn.setRequestProperty("User-Agent", "Mozilla/5.0 MiCriptoSentinel/1.9")

                                if (conn.responseCode == 200) {
                                    resp = conn.inputStream.bufferedReader().readText()
                                    break
                                }
                            } catch (e: Exception) {
                                if (attempt == 1) {
                                    Thread.sleep(1500)
                                } else {
                                    FileLogger.logWarning(context, "⚠️ Error en intento 2 de escaneo nativo Doze: ${e.message}")
                                }
                            }
                        }

                        if (resp != null) {
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
                                val side = order.optString("side", "SELL").uppercase(Locale.US)
                                val isBuy = side.contains("BUY")
                                val curPrice = priceMap[sym] ?: continue
                                val triggeredKey = "triggered_" + order.optString("id", sym)
                                val alreadyTriggered = prefs.getBoolean(triggeredKey, false)

                                val isHit = if (isBuy) {
                                    curPrice > 0.0 && curPrice <= target
                                } else {
                                    curPrice > 0.0 && curPrice >= target
                                }

                                // Si el precio está lejos del target y la orden sigue abierta, limpiar bandera para garantizar disparo
                                if (!isHit && alreadyTriggered) {
                                    val safeDistance = if (isBuy) curPrice > target * 1.015 else curPrice < target * 0.985
                                    if (safeDistance) {
                                        prefs.edit().putBoolean(triggeredKey, false).apply()
                                    }
                                }

                                if (isHit && !alreadyTriggered) {
                                    prefs.edit().putBoolean(triggeredKey, true).apply()
                                    val dispSym = order.optString("displaySymbol", sym)
                                    val tp1 = target * 1.030
                                    val tp2 = target * 1.055
                                    val sl = target * 0.972

                                    FileLogger.logInfo(context, if (isBuy) "⚡ ¡COMPRA LIMIT EJECUTADA EN BINANCE! $dispSym tocó $$curPrice (Límite: $$target)" else "🎯 ¡TAKE PROFIT COBRADO EN BINANCE! $dispSym tocó $$curPrice (Meta: $$target)")

                                    fireImmediateAlarm(
                                        context = context,
                                        symbol = dispSym,
                                        eventType = if (isBuy) "BUY_FILLED" else "TP_HIT",
                                        price = String.format(Locale.US, "$%.4f", curPrice),
                                        amount = if (isBuy) String.format(Locale.US, "SUELO COMPRADO: $%.4f", target) else "${order.optDouble("amountCoins")} (${order.optDouble("expectedReturnUsdt")} USDT)",
                                        targetPrice = String.format(Locale.US, "$%.4f", if (isBuy) tp1 else target),
                                        projectedProfit = if (isBuy) String.format(Locale.US, "TP1: $%.4f | TP2: $%.4f", tp1, tp2) else "+$${order.optDouble("projectedProfitUsdt")} USDT",
                                        totalProfit = "+$31.91 USDT",
                                        liquidCash = "$78.45 USDT",
                                        tp1Price = String.format(Locale.US, "$%.4f", tp1),
                                        tp2Price = String.format(Locale.US, "$%.4f", tp2),
                                        slPrice = String.format(Locale.US, "$%.4f", sl),
                                        limitBuyPrice = String.format(Locale.US, "$%.4f", target),
                                        buyPrice = String.format(Locale.US, "$%.4f", order.optDouble("entryPrice", target)),
                                        buyDate = order.optString("datePlaced", ""),
                                        totalCoins = String.format(Locale.US, "%.4f", order.optDouble("amountCoins", 100.0))
                                    )
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
                    FileLogger.logWarning(context, "⚠️ Error en escaneo nativo Doze: ${e.message}")
                } finally {
                    try {
                        if (scanWakeLock?.isHeld == true) scanWakeLock.release()
                    } catch (_: Exception) {}
                    pendingResult.finish()
                    scheduleNextScan(context, 60)
                }
            }.start()
            return
        }

        // 3. Disparo de Alarma desde intent externo (Prueba de alarma o FCM)
        val symbol = intent.getStringExtra("symbol") ?: "BINANCE SPOT"
        val eventType = intent.getStringExtra("event_type") ?: "BUY_FILLED"
        val price = intent.getStringExtra("price") ?: "$0.0000"
        val amount = intent.getStringExtra("amount") ?: ""
        val targetPrice = intent.getStringExtra("target_price") ?: "$0.0000"
        val projectedProfit = intent.getStringExtra("projected_profit") ?: "+$0.00 USDT"
        val totalProfit = intent.getStringExtra("total_profit") ?: "+$25.56 USDT"
        val liquidCash = intent.getStringExtra("liquid_cash") ?: "$1,225.14 USDT"
        val tp1Price = intent.getStringExtra("tp1_price") ?: ""
        val tp2Price = intent.getStringExtra("tp2_price") ?: ""
        val slPrice = intent.getStringExtra("sl_price") ?: ""
        val limitBuyPrice = intent.getStringExtra("limit_buy_price") ?: ""
        val tradeAmount = intent.getStringExtra("trade_amount") ?: "100.0"

        fireImmediateAlarm(
            context = context,
            symbol = symbol,
            eventType = eventType,
            price = price,
            amount = amount,
            targetPrice = targetPrice,
            projectedProfit = projectedProfit,
            totalProfit = totalProfit,
            liquidCash = liquidCash,
            tp1Price = tp1Price,
            tp2Price = tp2Price,
            slPrice = slPrice,
            limitBuyPrice = limitBuyPrice,
            tradeAmount = tradeAmount
        )
    }

    /**
     * Escáner Nativo Smart Engine 2.2 (100% Paridad con smcEngine.ts de la Web) en Segundo Plano (Doze Mode)
     * Evalúa cada 3 minutos la estructura 1H de las 10 monedas institucionales directo contra Binance.
     */
    private fun scanSmartEngineSPlus1H(context: Context, prefs: android.content.SharedPreferences) {
        val settingsPrefs = context.getSharedPreferences("sentinel_settings", Context.MODE_PRIVATE)
        val soundMode = settingsPrefs.getString("sound_mode", "ALWAYS") ?: "ALWAYS"
        if (soundMode == "TOTAL_SILENCE") return

        val watchedSymbols = listOf(
            // 11 Monedas de Nuestra Cartera Institucional
            "RENDERUSDT", "SUIUSDT", "NEARUSDT", "PENDLEUSDT", "XRPUSDT",
            "ONDOUSDT", "TAOUSDT", "ALGOUSDT", "HBARUSDT", "XLMUSDT", "BNBUSDT",
            // 33 Monedas Extra de Radar de Caza S+ (Top Institucionales)
            "BTCUSDT", "ETHUSDT", "SOLUSDT", "AVAXUSDT", "LINKUSDT",
            "INJUSDT", "APTUSDT", "SEIUSDT", "TIAUSDT", "ARBUSDT",
            "OPUSDT", "FETUSDT", "AAVEUSDT", "UNIUSDT", "ADAUSDT",
            "DOTUSDT", "PYTHUSDT", "GRTUSDT", "WLDUSDT", "ARKMUSDT",
            "FTMUSDT", "POLUSDT", "ICPUSDT", "JUPUSDT", "RUNEUSDT",
            "ENAUSDT", "DOGEUSDT", "ATOMUSDT", "THETAUSDT", "MKRUSDT",
            "CRVUSDT", "LDOUSDT", "STRKUSDT"
        )
        val nowMs = System.currentTimeMillis()

        for (sym in watchedSymbols) {
            try {
                // Cooldown de 4 horas por moneda para evitar alarmas repetidas en la misma barrida
                val lastTrigMs = prefs.getLong("splus_last_trig_$sym", 0L)
                if (nowMs - lastTrigMs < 4 * 3600 * 1000L) continue

                val url = URL("https://api.binance.com/api/v3/klines?symbol=$sym&interval=1h&limit=180")
                val conn = url.openConnection() as HttpURLConnection
                conn.connectTimeout = 6000
                conn.readTimeout = 6000
                conn.setRequestProperty("User-Agent", "Mozilla/5.0 MiCriptoSentinel/1.9")

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
                    val settingsPrefs = context.getSharedPreferences("sentinel_settings", Context.MODE_PRIVATE)
                    val soundSPlus = settingsPrefs.getBoolean("alarm_sound_s_plus", true)
                    if (!soundSPlus) {
                        FileLogger.logInfo(context, "🔕 [DOZE] Señal S+ detectada en $sym pero silenciada por ajustes de usuario")
                        continue
                    }
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

                    fireImmediateAlarm(
                        context = context,
                        symbol = "$dispSym / USDT (S+ >=90%)",
                        eventType = "S_PLUS_ALPHA",
                        price = String.format(Locale.US, "$%.4f", sweepClosePrice),
                        amount = String.format(Locale.US, "SUELO 1H: $%.4f (-%.1f%% 48h)", floorPrice, drop48hPct),
                        targetPrice = String.format(Locale.US, "$%.4f", floorPrice),
                        projectedProfit = String.format(Locale.US, "TP1: $%.4f | TP2: $%.4f", tp1, tp2),
                        totalProfit = "92.3% WIN RATE (S+)",
                        liquidCash = "$78.45 USDT",
                        tp1Price = String.format(Locale.US, "$%.4f", tp1),
                        tp2Price = String.format(Locale.US, "$%.4f", tp2),
                        slPrice = String.format(Locale.US, "$%.4f", slTrig),
                        limitBuyPrice = String.format(Locale.US, "$%.4f", floorPrice)
                    )
                    break
                }
            } catch (_: Exception) {
                // Continuar con la siguiente moneda sin interrumpir el ciclo Doze
            }
        }
    }
}
