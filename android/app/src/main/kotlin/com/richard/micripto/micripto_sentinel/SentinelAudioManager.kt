package com.richard.micripto.micripto_sentinel

import android.content.Context
import android.media.AudioAttributes
import android.media.AudioManager
import android.media.MediaPlayer
import android.media.RingtoneManager
import android.os.Build
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import android.util.Log

object SentinelAudioManager {

    private const val TAG = "SentinelAudio"
    private var mediaPlayer: MediaPlayer? = null
    private var vibrator: Vibrator? = null
    private var isPlayingAudio = false

    @Synchronized
    fun play(context: Context) {
        if (isPlayingAudio) {
            Log.d(TAG, "Audio ya está en reproducción activa.")
            return
        }

        try {
            val audioManager = context.getSystemService(Context.AUDIO_SERVICE) as? AudioManager
            val prefs = context.getSharedPreferences("sentinel_settings", Context.MODE_PRIVATE)
            val soundMode = prefs.getString("sound_mode", "ALWAYS") ?: "ALWAYS"
            val ringerMode = audioManager?.ringerMode ?: AudioManager.RINGER_MODE_NORMAL

            var allowAudio = true
            var allowVibrate = true

            if (soundMode == "DEVICE_SETTINGS") {
                when (ringerMode) {
                    AudioManager.RINGER_MODE_SILENT -> {
                        allowAudio = false
                        allowVibrate = false
                        FileLogger.logInfo(context, "🔇 [Audio] Silenciado por perfil del teléfono (RINGER_MODE_SILENT)")
                    }
                    AudioManager.RINGER_MODE_VIBRATE -> {
                        allowAudio = false
                        allowVibrate = true
                        FileLogger.logInfo(context, "📳 [Audio] Solo vibración por perfil del teléfono (RINGER_MODE_VIBRATE)")
                    }
                }
            } else {
                FileLogger.logInfo(context, "🚨 [Audio] Modo SONAR SIEMPRE activo. Forzando alarma al 100%.")
            }

            if (allowAudio) {
                val audioAttributes = AudioAttributes.Builder()
                    .setUsage(AudioAttributes.USAGE_ALARM)
                    .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                    .build()

                try {
                    mediaPlayer = MediaPlayer.create(context, R.raw.tactical_sonar_alert, audioAttributes, 0)
                    if (mediaPlayer != null) {
                        FileLogger.logInfo(context, "🎵 [Audio] Sonar Cuántico cargado exitosamente")
                    }
                } catch (e: Exception) {
                    FileLogger.logError(context, "Error cargando tactical_sonar_alert", e)
                }

                if (mediaPlayer == null) {
                    try {
                        val alertUri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
                            ?: RingtoneManager.getDefaultUri(RingtoneManager.TYPE_RINGTONE)
                        mediaPlayer = MediaPlayer().apply {
                            setAudioAttributes(audioAttributes)
                            setDataSource(context, alertUri)
                            prepare()
                        }
                        FileLogger.logInfo(context, "🔔 [Audio] Fallback tono sistema cargado")
                    } catch (e: Exception) {
                        FileLogger.logError(context, "Error cargando fallback de alarma", e)
                    }
                }

                mediaPlayer?.apply {
                    isLooping = true
                    setOnCompletionListener { mp ->
                        try { mp.start() } catch (e: Exception) { e.printStackTrace() }
                    }
                    start()
                }

                isPlayingAudio = true

                // Forzar volumen ALARM al 100%
                try {
                    val maxVolume = audioManager?.getStreamMaxVolume(AudioManager.STREAM_ALARM) ?: 15
                    audioManager?.setStreamVolume(AudioManager.STREAM_ALARM, maxVolume, 0)
                } catch (e: Exception) {
                    Log.w(TAG, "No se pudo forzar volumen: ${e.message}")
                }
            }

            // Vibración táctica en pulsos
            if (allowVibrate) {
                vibrator = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                    val vm = context.getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as? VibratorManager
                    vm?.defaultVibrator
                } else {
                    @Suppress("DEPRECATION")
                    context.getSystemService(Context.VIBRATOR_SERVICE) as? Vibrator
                }

                val pattern = longArrayOf(0, 500, 200, 500, 800)
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    vibrator?.vibrate(VibrationEffect.createWaveform(pattern, 0))
                } else {
                    @Suppress("DEPRECATION")
                    vibrator?.vibrate(pattern, 0)
                }
            }
        } catch (e: Exception) {
            FileLogger.logError(context, "Error en SentinelAudioManager.play", e)
        }
    }

    @Synchronized
    fun stop() {
        try {
            if (mediaPlayer?.isPlaying == true) {
                mediaPlayer?.stop()
            }
            mediaPlayer?.release()
            mediaPlayer = null
            vibrator?.cancel()
            vibrator = null
            isPlayingAudio = false
            Log.d(TAG, "🛑 SentinelAudioManager detenido y silenciado.")
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    fun isPlaying(): Boolean = isPlayingAudio
}
