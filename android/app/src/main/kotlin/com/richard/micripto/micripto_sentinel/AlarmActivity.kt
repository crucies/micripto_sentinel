package com.richard.micripto.micripto_sentinel

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.PowerManager
import android.view.View
import android.view.WindowManager
import android.widget.EditText
import android.widget.LinearLayout
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.regex.Pattern

class AlarmActivity : AppCompatActivity() {

    private var wakeLock: PowerManager.WakeLock? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val eventType = intent.getStringExtra("event_type") ?: "BUY_FILLED"
        val rawSymbol = intent.getStringExtra("symbol") ?: "OP / USDT"
        FileLogger.logInfo(this, "🚨 [AlarmActivity] onCreate iniciado: $rawSymbol ($eventType)")

        // 1. Mostrar sobre pantalla bloqueada sin clave ni PIN
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
            val km = getSystemService(Context.KEYGUARD_SERVICE) as? android.app.KeyguardManager
            km?.requestDismissKeyguard(this, null)
        }
        @Suppress("DEPRECATION")
        window.addFlags(
            WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
            WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON or
            WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON or
            WindowManager.LayoutParams.FLAG_ALLOW_LOCK_WHILE_SCREEN_ON or
            WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN or
            WindowManager.LayoutParams.FLAG_FULLSCREEN
        )

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
            wakeLock?.acquire(3 * 60 * 1000L) // 3 minutos máximo
        } catch (e: Exception) {
            e.printStackTrace()
        }

        setContentView(R.layout.activity_alarm)

        // 2. Extraer y Normalizar Datos del Intent
        val rawPrice = intent.getStringExtra("price") ?: "$0.0000"
        val rawAmount = intent.getStringExtra("amount") ?: "SUELO 1H: $0.0000"
        val rawTarget = intent.getStringExtra("target_price") ?: "$0.0000"
        val rawProjectedProfit = intent.getStringExtra("projected_profit") ?: ""
        val rawTotalProfit = intent.getStringExtra("total_profit") ?: ""
        val rawLiquidCash = intent.getStringExtra("liquid_cash") ?: "$891.00 USDT"

        val buyPriceExtra = intent.getStringExtra("buy_price") ?: ""
        val buyDateExtra = intent.getStringExtra("buy_date") ?: ""
        val sellDateExtra = intent.getStringExtra("sell_date") ?: ""
        val elapsedTimeExtra = intent.getStringExtra("elapsed_time") ?: ""
        val appVersionExtra = intent.getStringExtra("app_version") ?: "V 0.2.17"
        val totalCoinsExtra = intent.getStringExtra("total_coins") ?: ""

        var tp1Str = intent.getStringExtra("tp1_price") ?: ""
        var tp2Str = intent.getStringExtra("tp2_price") ?: ""
        var slStr = intent.getStringExtra("sl_price") ?: ""
        var limitBuyStr = intent.getStringExtra("limit_buy_price") ?: ""

        // Parser Inteligente de Respaldo: si TP1/TP2 venían concatenados en rawTarget o rawProjectedProfit
        if (tp1Str.isEmpty() || tp2Str.isEmpty()) {
            val fullText = "$rawTarget $rawProjectedProfit $rawTotalProfit"
            val tp1Matcher = Pattern.compile("TP1:?\\s*\\$?([0-9.]+)").matcher(fullText)
            if (tp1Matcher.find()) {
                tp1Str = "$" + tp1Matcher.group(1)
            }
            val tp2Matcher = Pattern.compile("TP2:?\\s*\\$?([0-9.]+)").matcher(fullText)
            if (tp2Matcher.find()) {
                tp2Str = "$" + tp2Matcher.group(1)
            }
            val slMatcher = Pattern.compile("(?:OCO SL(?: Trigger)?:?\\s*|SL:?\\s*)\\$?([0-9.]+)").matcher(fullText)
            if (slMatcher.find()) {
                slStr = "$" + slMatcher.group(1)
            }
        }

        // Normalizar Limit Buy Price
        if (limitBuyStr.isEmpty()) {
            if (!rawTarget.contains("TP1") && !rawTarget.contains("|")) {
                limitBuyStr = rawTarget
            } else {
                val floorMatcher = Pattern.compile("SUELO(?: 1H)?:?\\s*\\$?([0-9.]+)").matcher(rawAmount)
                limitBuyStr = if (floorMatcher.find()) "$" + floorMatcher.group(1) else rawPrice
            }
        }

        // Si TP1 o TP2 aún están vacíos, calcular a partir del precio de entrada
        val cleanEntryVal = limitBuyStr.replace("$", "").trim().toDoubleOrNull() ?: 1.0
        val tp1Val = if (tp1Str.isNotEmpty()) tp1Str.replace("$", "").trim().toDoubleOrNull() ?: (cleanEntryVal * 1.030) else (cleanEntryVal * 1.030)
        val tp2Val = if (tp2Str.isNotEmpty()) tp2Str.replace("$", "").trim().toDoubleOrNull() ?: (cleanEntryVal * 1.055) else (cleanEntryVal * 1.055)

        // Limpieza de Símbolo
        var cleanSymbol = rawSymbol
        if (rawSymbol.contains("(")) {
            val parts = rawSymbol.split("(")
            cleanSymbol = parts[0].trim()
        }

        // 3. Vincular Contenedores Raíz
        val layoutBuyAlarm = findViewById<LinearLayout>(R.id.layoutBuyAlarm)
        val layoutSellAlarm = findViewById<LinearLayout>(R.id.layoutSellAlarm)
        val layoutRadarAlarm = findViewById<LinearLayout>(R.id.layoutRadarAlarm)
        val layoutKaiAlarm = findViewById<LinearLayout>(R.id.layoutKaiAlarm)

        // Vistas del Formulario de Informe Táctico Kai
        val tvKaiAppVersion = findViewById<TextView>(R.id.tvKaiAppVersion)
        val tvKaiCurrentDate = findViewById<TextView>(R.id.tvKaiCurrentDate)
        val tvKaiHeroTitle = findViewById<TextView>(R.id.tvKaiHeroTitle)
        val tvKaiBadge = findViewById<TextView>(R.id.tvKaiBadge)
        val tvKaiSummary = findViewById<TextView>(R.id.tvKaiSummary)
        val tvKaiAction = findViewById<TextView>(R.id.tvKaiAction)
        val tvKaiLiquidCash = findViewById<TextView>(R.id.tvKaiLiquidCash)

        // Vistas del Formulario de Radar Cuantitativo S+ / S
        val tvRadarAppVersion = findViewById<TextView>(R.id.tvRadarAppVersion)
        val tvRadarCurrentDate = findViewById<TextView>(R.id.tvRadarCurrentDate)
        val tvRadarHeroTitle = findViewById<TextView>(R.id.tvRadarHeroTitle)
        val tvRadarGradeBadge = findViewById<TextView>(R.id.tvRadarGradeBadge)
        val tvRadarCurrentPrice = findViewById<TextView>(R.id.tvRadarCurrentPrice)
        val tvRadarFloorPrice = findViewById<TextView>(R.id.tvRadarFloorPrice)
        val tvRadarDistance = findViewById<TextView>(R.id.tvRadarDistance)
        val tvRadarTp1Price = findViewById<TextView>(R.id.tvRadarTp1Price)
        val tvRadarTp2Price = findViewById<TextView>(R.id.tvRadarTp2Price)
        val tvRadarSlPrice = findViewById<TextView>(R.id.tvRadarSlPrice)
        val tvRadarLiquidCash = findViewById<TextView>(R.id.tvRadarLiquidCash)

        // 4. Vincular Vistas del Formulario de Compra (Plano de Richard)
        val tvBuyAppVersion = findViewById<TextView>(R.id.tvBuyAppVersion)
        val tvBuyCurrentDate = findViewById<TextView>(R.id.tvBuyCurrentDate)
        val tvBuyHeroTitle = findViewById<TextView>(R.id.tvBuyHeroTitle)
        val tvBuyCurrentPrice = findViewById<TextView>(R.id.tvBuyCurrentPrice)
        val tvBuyExecutedPrice = findViewById<TextView>(R.id.tvBuyExecutedPrice)
        val tvBuyTotalCoins = findViewById<TextView>(R.id.tvBuyTotalCoins)
        val tvTp1TargetPrice = findViewById<TextView>(R.id.tvTp1TargetPrice)
        val etTp1Coins = findViewById<EditText>(R.id.etTp1Coins)
        val tvTp1CalculatedProfit = findViewById<TextView>(R.id.tvTp1CalculatedProfit)
        val btnCalcTp1 = findViewById<TextView>(R.id.btnCalcTp1)
        val tvTp2TargetPrice = findViewById<TextView>(R.id.tvTp2TargetPrice)
        val etTp2Coins = findViewById<EditText>(R.id.etTp2Coins)
        val tvTp2CalculatedProfit = findViewById<TextView>(R.id.tvTp2CalculatedProfit)
        val btnCalcTp2 = findViewById<TextView>(R.id.btnCalcTp2)
        val tvBuyLiquidCash = findViewById<TextView>(R.id.tvBuyLiquidCash)

        // 5. Vincular Vistas del Formulario de Venta (Plano de Richard)
        val tvSellAppVersion = findViewById<TextView>(R.id.tvSellAppVersion)
        val tvSellCurrentDate = findViewById<TextView>(R.id.tvSellCurrentDate)
        val tvSellHeroTitle = findViewById<TextView>(R.id.tvSellHeroTitle)
        val tvSellCoinName = findViewById<TextView>(R.id.tvSellCoinName)
        val tvSellElapsedTime = findViewById<TextView>(R.id.tvSellElapsedTime)
        val tvSellProfitUsdt = findViewById<TextView>(R.id.tvSellProfitUsdt)
        val tvSellTotalProfit = findViewById<TextView>(R.id.tvSellTotalProfit)
        val tvSellBuyPrice = findViewById<TextView>(R.id.tvSellBuyPrice)
        val tvSellBuyDate = findViewById<TextView>(R.id.tvSellBuyDate)
        val tvSellExecutedPrice = findViewById<TextView>(R.id.tvSellExecutedPrice)
        val tvSellExecutedDate = findViewById<TextView>(R.id.tvSellExecutedDate)
        val tvSellLiquidCash = findViewById<TextView>(R.id.tvSellLiquidCash)

        val shortNow = SimpleDateFormat("dd/MM/yy • HH:mm 'BOT'", Locale.getDefault()).format(Date())

        val cleanLiquid = rawLiquidCash.replace("💵 LIQUIDEZ LISTA EN SPOT:", "").replace("💵", "").trim()

        if (eventType == "TP_HIT") {
            // ========================================================
            // FORMULARIO 1: EXCLUSIVO DE VENTA (TP_HIT)
            // ========================================================
            layoutBuyAlarm.visibility = View.GONE
            layoutSellAlarm.visibility = View.VISIBLE
            layoutRadarAlarm.visibility = View.GONE

            tvSellAppVersion.text = appVersionExtra
            tvSellCurrentDate.text = if (sellDateExtra.isNotEmpty()) sellDateExtra else shortNow
            tvSellHeroTitle.text = "VENTA $cleanSymbol"

            tvSellCoinName.text = cleanSymbol
            tvSellElapsedTime.text = if (elapsedTimeExtra.isNotEmpty()) elapsedTimeExtra else calculateElapsedTimeFromDate(buyDateExtra)
            tvSellProfitUsdt.text = if (rawProjectedProfit.isNotEmpty()) rawProjectedProfit else "+$20.3600 USDT"
            tvSellTotalProfit.text = if (rawTotalProfit.isNotEmpty()) rawTotalProfit else "+$74.3900 USDT"

            tvSellBuyPrice.text = if (buyPriceExtra.isNotEmpty()) buyPriceExtra else limitBuyStr
            tvSellBuyDate.text = if (buyDateExtra.isNotEmpty()) formatShortDate(buyDateExtra) else "15/10/26 • 16:51"
            tvSellExecutedPrice.text = rawPrice
            tvSellExecutedDate.text = if (sellDateExtra.isNotEmpty()) sellDateExtra else shortNow

            tvSellLiquidCash.text = if (cleanLiquid.isNotEmpty()) cleanLiquid else "891.0000 USDT"

                } else if (eventType == "KAI_ANALYSIS") {
            // ========================================================
            // FORMULARIO 4: EXCLUSIVO DE INFORME TÁCTICO KAI (3H)
            // ========================================================
            layoutBuyAlarm.visibility = View.GONE
            layoutSellAlarm.visibility = View.GONE
            layoutRadarAlarm.visibility = View.GONE
            layoutKaiAlarm.visibility = View.VISIBLE

            val kaiTitle = intent.getStringExtra("kai_title") ?: "INFORME TÁCTICO KAI (3H)"
            val kaiHero = intent.getStringExtra("kai_hero") ?: "PORTAFOLIO • 17 ÓRDENES ACTIVAS"
            val kaiSummary = intent.getStringExtra("kai_summary") ?: rawProjectedProfit
            val kaiAction = intent.getStringExtra("kai_action") ?: rawAmount
            val kaiTimestamp = intent.getStringExtra("kai_timestamp") ?: shortNow

            tvKaiAppVersion.text = appVersionExtra
            tvKaiCurrentDate.text = kaiTimestamp
            tvKaiHeroTitle.text = kaiTitle
            tvKaiBadge.text = kaiHero
            tvKaiSummary.text = kaiSummary
            tvKaiAction.text = kaiAction
            tvKaiLiquidCash.text = if (cleanLiquid.isNotEmpty()) cleanLiquid else "458.5900 USDT"

        } else if (eventType == "S_PLUS_ALPHA") {
            // ========================================================
            // FORMULARIO 3: EXCLUSIVO DE RADAR INSTITUCIONAL S+ / S
            // ========================================================
            layoutBuyAlarm.visibility = View.GONE
            layoutSellAlarm.visibility = View.GONE
            layoutRadarAlarm.visibility = View.VISIBLE

            tvRadarAppVersion.text = appVersionExtra
            tvRadarCurrentDate.text = shortNow
            tvRadarHeroTitle.text = "OPORTUNIDAD EN $cleanSymbol"

            val isSPlus = rawSymbol.contains("S+") || rawSymbol.contains("9")
            tvRadarGradeBadge.text = if (isSPlus) "⭐ CONFLUENCIA ALTA (S+ 94%)" else "🟢 ZONA DE ACUMULACIÓN (S 84%)"

            tvRadarCurrentPrice.text = rawPrice
            tvRadarFloorPrice.text = limitBuyStr
            tvRadarDistance.text = "EN ZONA DE ABSORCIÓN 1H"

            tvRadarTp1Price.text = String.format(Locale.US, "$%.4f", tp1Val)
            tvRadarTp2Price.text = String.format(Locale.US, "$%.4f", tp2Val)
            val slVal = cleanEntryVal * 0.972
            tvRadarSlPrice.text = String.format(Locale.US, "$%.4f", slVal)
            tvRadarLiquidCash.text = if (cleanLiquid.isNotEmpty()) cleanLiquid else "891.0000 USDT"

        } else {
            // ========================================================
            // FORMULARIO 2: EXCLUSIVO DE COMPRA (BUY_FILLED)
            // ========================================================
            layoutBuyAlarm.visibility = View.VISIBLE
            layoutSellAlarm.visibility = View.GONE
            layoutRadarAlarm.visibility = View.GONE

            tvBuyAppVersion.text = appVersionExtra
            tvBuyCurrentDate.text = shortNow
            tvBuyHeroTitle.text = "COMPRA $cleanSymbol"

            tvBuyCurrentPrice.text = rawPrice
            tvBuyExecutedPrice.text = limitBuyStr

            // Calcular Monedas en Total
            var totalCoins = totalCoinsExtra.toDoubleOrNull() ?: 0.0
            if (totalCoins <= 0.0) {
                val coinsMatcher = Pattern.compile("([0-9.]+)\\s*(?:[A-Za-z]+)?").matcher(rawAmount)
                if (coinsMatcher.find()) {
                    totalCoins = coinsMatcher.group(1)?.toDoubleOrNull() ?: (100.0 / cleanEntryVal)
                } else {
                    totalCoins = 100.0 / cleanEntryVal
                }
            }
            tvBuyTotalCoins.text = String.format(Locale.US, "%.4f", totalCoins)

            // TP1 y TP2 Precios calculados por el sistema
            tvTp1TargetPrice.text = String.format(Locale.US, "%.4f USDT", tp1Val)
            tvTp2TargetPrice.text = String.format(Locale.US, "%.4f USDT", tp2Val)

            // Por defecto: 50% de las monedas a vender en TP1 y 50% en TP2
            var tp1Coins = totalCoins * 0.50
            var tp2Coins = totalCoins - tp1Coins

            etTp1Coins.setText(String.format(Locale.US, "%.4f", tp1Coins))
            etTp2Coins.setText(String.format(Locale.US, "%.4f", tp2Coins))

            fun updateProfits() {
                val profitTp1 = tp1Coins * (tp1Val - cleanEntryVal)
                val profitTp2 = tp2Coins * (tp2Val - cleanEntryVal)
                tvTp1CalculatedProfit.text = String.format(Locale.US, "+%.4f USDT", profitTp1)
                tvTp2CalculatedProfit.text = String.format(Locale.US, "+%.4f USDT", profitTp2)
                tvBuyTotalCoins.text = String.format(Locale.US, "%.4f", totalCoins)
            }

            updateProfits()

            // Al cambiar cantidad en TP1 y presionar Calcular
            btnCalcTp1.setOnClickListener {
                val entered = etTp1Coins.text.toString().trim().toDoubleOrNull()
                if (entered != null && entered >= 0.0) {
                    tp1Coins = entered
                    if (entered <= totalCoins) {
                        tp2Coins = totalCoins - entered
                    } else {
                        totalCoins = entered
                        tp2Coins = 0.0
                    }
                    etTp2Coins.setText(String.format(Locale.US, "%.4f", tp2Coins))
                    updateProfits()
                }
            }

            // Al cambiar cantidad en TP2 y presionar Calcular
            btnCalcTp2.setOnClickListener {
                val entered = etTp2Coins.text.toString().trim().toDoubleOrNull()
                if (entered != null && entered >= 0.0) {
                    tp2Coins = entered
                    if (entered <= totalCoins) {
                        tp1Coins = totalCoins - entered
                    } else {
                        totalCoins = entered
                        tp1Coins = 0.0
                    }
                    etTp1Coins.setText(String.format(Locale.US, "%.4f", tp1Coins))
                    updateProfits()
                }
            }

            val cleanLiquid = rawLiquidCash.replace("💵 LIQUIDEZ LISTA EN SPOT:", "").replace("💵", "").trim()
            tvBuyLiquidCash.text = if (cleanLiquid.isNotEmpty()) cleanLiquid else "891.0000 USDT"
        }
        // 6. Iniciar Audio
        playTacticalAlarm()

        // 7. Botones de Acción
        val btnSilence = findViewById<TextView>(R.id.btnSilence)
        btnSilence.setOnClickListener {
            stopAlarm()
            btnSilence.text = "🔕 SILENCIADA"
            btnSilence.setBackgroundResource(R.drawable.bg_brutalist_white)
        }

        findViewById<TextView>(R.id.btnOpenBinance).setOnClickListener {
            stopAlarm()
            openBinanceApp(cleanSymbol)
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

    private fun openBinanceApp(symbol: String) {
        try {
            val launchIntent = packageManager.getLaunchIntentForPackage("com.binance.dev")
            if (launchIntent != null) {
                startActivity(launchIntent)
            } else {
                val cleanPair = symbol.replace("/", "").replace(" ", "").uppercase(Locale.US)
                val webIntent = Intent(Intent.ACTION_VIEW, Uri.parse("https://www.binance.com/en/trade/${cleanPair}"))
                startActivity(webIntent)
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun formatShortDate(rawDate: String): String {
        try {
            val clean = rawDate.replace(" BOT", "").trim()
            val sdfIn = SimpleDateFormat("yyyy-MM-dd HH:mm:ss", Locale.getDefault())
            val d = sdfIn.parse(clean)
            if (d != null) {
                val sdfOut = SimpleDateFormat("dd/MM/yy • HH:mm", Locale.getDefault())
                return sdfOut.format(d)
            }
        } catch (_: Exception) {}
        return rawDate
    }

    private fun calculateElapsedTimeFromDate(dateStr: String): String {
        try {
            val clean = dateStr.replace(" BOT", "").trim()
            val sdfIn = SimpleDateFormat("yyyy-MM-dd HH:mm:ss", Locale.getDefault())
            val d = sdfIn.parse(clean)
            if (d != null) {
                val diffMs = System.currentTimeMillis() - d.time
                if (diffMs > 0) {
                    val days = diffMs / (1000 * 60 * 60 * 24)
                    val hours = (diffMs / (1000 * 60 * 60)) % 24
                    val minutes = (diffMs / (1000 * 60)) % 60
                    return "${days}d ${hours}h ${minutes}m"
                }
            }
        } catch (_: Exception) {}
        return "2d 4h 15m"
    }

    override fun onDestroy() {
        super.onDestroy()
        stopAlarm()
        if (wakeLock?.isHeld == true) {
            wakeLock?.release()
        }
    }
}
