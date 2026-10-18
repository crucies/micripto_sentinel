package com.richard.micripto.micripto_sentinel

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.util.Log
import androidx.core.app.NotificationCompat
import com.google.firebase.messaging.FirebaseMessaging
import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage

class SentinelFirebaseService : FirebaseMessagingService() {

    companion object {
        private const val TAG = "SentinelFCM"
        private const val CHANNEL_ID = "sentinel_tactical_channel"
        private const val CHANNEL_NAME = "MiCripto Sentinel Alarmas"
        const val PREFS_NAME = "sentinel_fcm_prefs"
        const val KEY_FCM_TOKEN = "fcm_token"
    }

    override fun onNewToken(token: String) {
        super.onNewToken(token)
        Log.d(TAG, "🔑 Nuevo Token FCM generado: $token")

        // Guardar token en preferencias para Flutter
        val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        prefs.edit().putString(KEY_FCM_TOKEN, token).apply()

        // Suscribirse automáticamente al tópico maestro
        FirebaseMessaging.getInstance().subscribeToTopic("sentinel_alerts")
            .addOnCompleteListener { task ->
                if (task.isSuccessful) {
                    Log.d(TAG, "📡 Suscripción exitosa al tópico: sentinel_alerts")
                } else {
                    Log.e(TAG, "❌ Error al suscribirse al tópico sentinel_alerts", task.exception)
                }
            }
    }

    override fun onMessageReceived(remoteMessage: RemoteMessage) {
        super.onMessageReceived(remoteMessage)
        Log.d(TAG, "🚨 Mensaje FCM recibido. Payload data: ${remoteMessage.data}")

        // 1. Extraer telemetría de la alerta táctica
        val data = remoteMessage.data
        val eventType = data["event_type"] ?: data["eventType"] ?: "BUY_FILLED"
        val symbol = data["symbol"] ?: "SUI / USDT"
        val price = data["price"] ?: "$1.0020"
        val amount = data["amount"] ?: "149.7 SUI ($149.99 USDT)"
        val targetPrice = data["target_price"] ?: data["targetPrice"] ?: "$1.0650"
        val projectedProfit = data["projected_profit"] ?: data["projectedProfit"] ?: "+$9.12 USDT (+6.08%)"
        val totalProfit = data["total_profit"] ?: data["totalProfit"] ?: "+$41.56 USDT"
        val liquidCash = data["liquid_cash"] ?: data["liquidCash"] ?: "$345.84 USDT"

        // 2. Despertar CPU y pantalla inmediatamente con WakeLock
        try {
            val pm = getSystemService(Context.POWER_SERVICE) as? PowerManager
            @Suppress("DEPRECATION")
            val wl = pm?.newWakeLock(
                PowerManager.SCREEN_BRIGHT_WAKE_LOCK or PowerManager.ACQUIRE_CAUSES_WAKEUP,
                "micripto:fcm_instant_wake"
            )
            wl?.acquire(30000) // 30 segundos
        } catch (e: Exception) {
            Log.e(TAG, "Error adquiriendo WakeLock", e)
        }

        // 3. Preparar Intent para AlarmActivity
        val alarmIntent = Intent(this, AlarmActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                    Intent.FLAG_ACTIVITY_CLEAR_TOP or
                    Intent.FLAG_ACTIVITY_EXCLUDE_FROM_RECENTS
            putExtra("event_type", eventType)
            putExtra("symbol", symbol)
            putExtra("price", price)
            putExtra("amount", amount)
            putExtra("target_price", targetPrice)
            putExtra("projected_profit", projectedProfit)
            putExtra("total_profit", totalProfit)
            putExtra("liquid_cash", liquidCash)
        }

        val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        } else {
            PendingIntent.FLAG_UPDATE_CURRENT
        }
        val fullScreenPendingIntent = PendingIntent.getActivity(this, 2001, alarmIntent, flags)

        // 4. Crear Canal de Notificación de Máxima Prioridad con Sonar Cuántico
        createNotificationChannel()

        val notificationTitle = when (eventType) {
            "TP_HIT" -> "🎯 ¡TAKE PROFIT EJECUTADO! ($symbol)"
            "S_PLUS_ALPHA" -> "⭐ OPORTUNIDAD RADAR S+ ($symbol)"
            else -> "🟢 ORDEN DE COMPRA EJECUTADA ($symbol)"
        }

        val notificationBody = when (eventType) {
            "TP_HIT" -> "Beneficio asegurado: $projectedProfit | Saldo: $liquidCash"
            "S_PLUS_ALPHA" -> "Señal de Alta Convicción a $price. Objetivo: $targetPrice"
            else -> "Entrada a $price. Colocar venta en $targetPrice ($projectedProfit)"
        }

        val soundUri = Uri.parse("android.resource://$packageName/raw/tactical_sonar_alert")

        val notificationBuilder = NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(android.R.drawable.ic_dialog_alert)
            .setContentTitle(notificationTitle)
            .setContentText(notificationBody)
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setAutoCancel(true)
            .setOngoing(true)
            .setSound(soundUri)
            .setFullScreenIntent(fullScreenPendingIntent, true) // Activa pantalla sobre Keyguard en Android 10+
            .setContentIntent(fullScreenPendingIntent)

        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        notificationManager.notify(1001, notificationBuilder.build())

        // 5. Intento directo de startActivity para acelerar en versiones compatibles
        try {
            startActivity(alarmIntent)
        } catch (e: Exception) {
            Log.w(TAG, "Direct startActivity deferred to FullScreenIntent: ${e.message}")
        }
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            val soundUri = Uri.parse("android.resource://$packageName/raw/tactical_sonar_alert")

            val audioAttributes = AudioAttributes.Builder()
                .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                .setUsage(AudioAttributes.USAGE_ALARM)
                .build()

            val channel = NotificationChannel(
                CHANNEL_ID,
                CHANNEL_NAME,
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Canal de alarmas críticas para ejecución de órdenes en Binance"
                enableLights(true)
                enableVibration(true)
                vibrationPattern = longArrayOf(0, 350, 150, 350, 150, 500)
                setSound(soundUri, audioAttributes)
                lockscreenVisibility = NotificationCompat.VISIBILITY_PUBLIC
                setBypassDnd(true)
            }

            notificationManager.createNotificationChannel(channel)
        }
    }
}
