package com.richard.micripto.micripto_sentinel

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.PowerManager
import android.view.View
import android.view.WindowManager
import android.widget.LinearLayout
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

class AlarmActivity : AppCompatActivity() {

    private var wakeLock: PowerManager.WakeLock? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val eventType = intent.getStringExtra("event_type") ?: "BUY_FILLED"
        val symbol = intent.getStringExtra("symbol") ?: "SUI / USDT"
        FileLogger.logInfo(this, "🚨 [AlarmActivity] onCreate iniciado: $symbol ($eventType)")

        // 1. Mostrar formulario directamente sobre la pantalla bloqueada (sin solicitar PIN/clave)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
        }
        @Suppress("DEPRECATION")
        window.addFlags(
            WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
            WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON or
            WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON or
            WindowManager.LayoutParams.FLAG_ALLOW_LOCK_WHILE_SCREEN_ON
        )

        // Iconos oscuros en barra de estado para máximo contraste sobre lienzo dorado claro (#FFF8E7)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            @Suppress("DEPRECATION")
            window.decorView.systemUiVisibility = View.SYSTEM_UI_FLAG_LIGHT_STATUS_BAR
        }

        // Adquirir WakeLock agresivo para iluminar pantalla de inmediato
        try {
            val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
            @Suppress("DEPRECATION")
            wakeLock = powerManager.newWakeLock(
                PowerManager.SCREEN_BRIGHT_WAKE_LOCK or PowerManager.ACQUIRE_CAUSES_WAKEUP,
                "micripto:AlarmActivityWakeLock"
            )
            wakeLock?.acquire(3 * 60 * 1000L) // 3 minutos máximo de seguridad
        } catch (e: Exception) {
            e.printStackTrace()
        }

        setContentView(R.layout.activity_alarm)

        // 2. Extraer datos del Intent
        val price = intent.getStringExtra("price") ?: "$1.0020"
        val amount = intent.getStringExtra("amount") ?: "149.7 SUI ($149.99 USDT)"
        val targetPrice = intent.getStringExtra("target_price") ?: "$1.0650"
        val projectedProfit = intent.getStringExtra("projected_profit") ?: "+$9.12 USDT (+6.08%)"
        val totalProfit = intent.getStringExtra("total_profit") ?: "+$70.07 USDT"
        val liquidCash = intent.getStringExtra("liquid_cash") ?: "$36.59 USDT"

        // 3. Vincular Vistas Brutalistas
        val timeTv = findViewById<TextView>(R.id.alarmTime)
        val statusBadge = findViewById<TextView>(R.id.statusBadge)
        val assetSymbol = findViewById<TextView>(R.id.assetSymbol)
        val assetModeBadge = findViewById<TextView>(R.id.assetModeBadge)
        val assetPriceLabel = findViewById<TextView>(R.id.assetPriceLabel)
        val assetPrice = findViewById<TextView>(R.id.assetPrice)
        val assetAmount = findViewById<TextView>(R.id.assetAmount)
        val actionHeader = findViewById<TextView>(R.id.actionHeader)
        val actionInstruction = findViewById<TextView>(R.id.actionInstruction)
        val actionTargetPrice = findViewById<TextView>(R.id.actionTargetPrice)
        val actionProjectedProfit = findViewById<TextView>(R.id.actionProjectedProfit)
        val profitTelemetryBox = findViewById<LinearLayout>(R.id.profitTelemetryBox)
        val profitCurrentTradeLabel = findViewById<TextView>(R.id.profitCurrentTradeLabel)
        val profitCurrentTrade = findViewById<TextView>(R.id.profitCurrentTrade)
        val profitTotalAccumulated = findViewById<TextView>(R.id.profitTotalAccumulated)
        val liquidCashAvailable = findViewById<TextView>(R.id.liquidCashAvailable)

        val sdf = SimpleDateFormat("HH:mm:ss 'BOT'", Locale.getDefault())
        timeTv.text = sdf.format(Date())

        assetSymbol.text = symbol
        assetPrice.text = price
        assetAmount.text = amount

        // La matriz de telemetría de capital permanece siempre visible para equilibrar el formulario
        profitTelemetryBox.visibility = LinearLayout.VISIBLE

        // Configurar según el tipo de evento (Los 3 Modos Operativos de Richard con estética Neo-Brutalista Dinero)
        when (eventType) {
            "TP_HIT" -> {
                statusBadge.text = "💰 ¡TAKE PROFIT COBRADO EN BINANCE!"
                statusBadge.setBackgroundResource(R.drawable.bg_brutalist_orange)
                statusBadge.setTextColor(0xFFFFFFFF.toInt())

                assetModeBadge.text = "TP COBRADO"
                assetPriceLabel.text = "PRECIO DE VENTA"
                actionHeader.text = " 🎉 BENEFICIO ASEGURADO EN BÓVEDA "
                actionInstruction.text = "Venta ejecutada con éxito en precio objetivo:"
                actionTargetPrice.text = price
                actionProjectedProfit.text = "💵 GANANCIA LIMPIA: $projectedProfit"

                profitCurrentTradeLabel.text = "GANANCIA DE ESTE TRADE"
                profitCurrentTrade.text = projectedProfit
                profitTotalAccumulated.text = totalProfit
                liquidCashAvailable.text = "💵 SALDO DISPONIBLE EN SPOT: $liquidCash"
            }
            "S_PLUS_ALPHA" -> {
                statusBadge.text = "🔥 ¡OPORTUNIDAD INSTITUCIONAL GRADO S+!"
                statusBadge.setBackgroundResource(R.drawable.bg_brutalist_yellow)
                statusBadge.setTextColor(0xFF0A0A0A.toInt())

                assetModeBadge.text = "SCORE >= 90"
                assetPriceLabel.text = "PRECIO ACTUAL"
                actionHeader.text = " 🎯 SUELO DE ALTA PROBABILIDAD DETECTADO "
                actionInstruction.text = "Plantar orden Limit Buy en zona de absorción:"
                actionTargetPrice.text = targetPrice
                actionProjectedProfit.text = "⚡ CONFLUENCIA: $projectedProfit"

                profitCurrentTradeLabel.text = "POTENCIAL TÁCTICO"
                profitCurrentTrade.text = "ALTA LIQUIDEZ (S+)"
                profitTotalAccumulated.text = totalProfit
                liquidCashAvailable.text = "💵 LIQUIDEZ LISTA PARA DISPARO: $liquidCash"
            }
            else -> { // "BUY_FILLED" (Por defecto)
                statusBadge.text = "⚡ ¡COMPRA EN SUELO EJECUTADA EN BINANCE!"
                statusBadge.setBackgroundResource(R.drawable.bg_brutalist_yellow)
                statusBadge.setTextColor(0xFF0A0A0A.toInt())

                assetModeBadge.text = "COMPRA SPOT"
                assetPriceLabel.text = "PRECIO ENTRADA"
                actionHeader.text = " 🎯 ACCIÓN OBLIGATORIA: PLANTAR TAKE PROFIT "
                actionInstruction.text = "Colocar orden Limit Sell inmediatamente en:"
                actionTargetPrice.text = targetPrice
                actionProjectedProfit.text = "💰 RETORNO ESPERADO: $projectedProfit"

                profitCurrentTradeLabel.text = "META DE ESTA ORDEN"
                profitCurrentTrade.text = projectedProfit
                profitTotalAccumulated.text = totalProfit
                liquidCashAvailable.text = "💵 LIQUIDEZ SPOT RESTANTE: $liquidCash"
            }
        }

        // 4. Iniciar Audio Táctico de Flujo Institucional en USAGE_ALARM
        playTacticalAlarm()

        // 5. Botones Brutalistas de Acción
        findViewById<TextView>(R.id.btnSilence).setOnClickListener {
            stopAlarm()
            statusBadge.text = "🔕 ALARMA SILENCIADA — ORDEN EN PANTALLA"
            statusBadge.setBackgroundResource(R.drawable.bg_brutalist_white)
            statusBadge.setTextColor(0xFF0A0A0A.toInt())
        }

        findViewById<TextView>(R.id.btnOpenBinance).setOnClickListener {
            stopAlarm()
            openBinanceApp()
            finish()
        }

        findViewById<TextView>(R.id.btnOpenDashboard).setOnClickListener {
            stopAlarm()
            val mainIntent = Intent(this, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            startActivity(mainIntent)
            finish()
        }
    }

    private fun playTacticalAlarm() {
        SentinelAudioManager.play(this)
    }

    private fun stopAlarm() {
        SentinelAudioManager.stop()
    }

    private fun openBinanceApp() {
        try {
            // Intent directo para abrir la app oficial de Binance en Android
            val launchIntent = packageManager.getLaunchIntentForPackage("com.binance.dev")
            if (launchIntent != null) {
                startActivity(launchIntent)
            } else {
                // Fallback al navegador
                val webIntent = Intent(Intent.ACTION_VIEW, Uri.parse("https://www.binance.com/"))
                startActivity(webIntent)
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        stopAlarm()
        if (wakeLock?.isHeld == true) {
            wakeLock?.release()
        }
    }
}
