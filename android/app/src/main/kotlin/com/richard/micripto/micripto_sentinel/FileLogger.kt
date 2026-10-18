package com.richard.micripto.micripto_sentinel

import android.content.Context
import android.util.Log
import java.io.File
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

object FileLogger {
    private const val LOG_FILE_NAME = "sentinel_logs.txt"
    private const val TAG = "MiCriptoSentinel"

    fun logInfo(context: Context, message: String) {
        log(context, "INFO", message)
    }

    fun logWarning(context: Context, message: String) {
        log(context, "WARN", message)
    }

    fun logError(context: Context, message: String, error: Throwable? = null) {
        val fullMsg = if (error != null) "$message | Ex: ${error.message}" else message
        log(context, "ERROR", fullMsg)
    }

    private fun log(context: Context, level: String, message: String) {
        try {
            val sdf = SimpleDateFormat("yyyy-MM-dd HH:mm:ss.SSS", Locale.getDefault())
            val timestamp = sdf.format(Date())
            val logLine = "[$timestamp] [$level] $message\n"

            val logFile = File(context.filesDir, LOG_FILE_NAME)
            logFile.appendText(logLine)

            when (level) {
                "ERROR" -> Log.e(TAG, message)
                "WARN" -> Log.w(TAG, message)
                else -> Log.d(TAG, message)
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error writing to log file", e)
        }
    }

    fun getLogs(context: Context): String {
        return try {
            val logFile = File(context.filesDir, LOG_FILE_NAME)
            if (logFile.exists()) {
                logFile.readText()
            } else {
                "--- No hay registros de telemetría todavía ---"
            }
        } catch (e: Exception) {
            "Error al leer logs: ${e.message}"
        }
    }

    fun clearLogs(context: Context) {
        try {
            val logFile = File(context.filesDir, LOG_FILE_NAME)
            if (logFile.exists()) {
                logFile.writeText("")
            }
            logInfo(context, "🗑️ Registros de telemetría borrados por el usuario")
        } catch (e: Exception) {
            Log.e(TAG, "Error limpiando logs", e)
        }
    }
}
