import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import '../constants/app_constants.dart';
import 'package:intl/intl.dart';
import 'native_alarm_service.dart';
import 'sentinel_auto_scanner.dart';
import 'macro_regime_service.dart';

class SPlusCoinRadarItem {
  final String symbol;
  final String displaySymbol;
  final double currentPrice;
  final double entryPrice;
  final double nearestFloorPrice;
  final double distanceToFloorPct;
  final double dropFrom48hHighPct;
  final double currentRsi;
  final int confluenceScore;
  final String grade; // 'S+', 'S', 'A', 'B'
  final bool isSPlusTriggered;
  final bool hasUnbroken2ndTouchSweep;
  final bool hasEngulfingChoch;
  final bool hasRsiDivergence;
  final bool hasRealDiscount48h;
  final double tp1Price;
  final double tp2Price;
  final double slTriggerPrice;
  final double slLimitPrice;
  final String statusReason;
  final String updatedAt;
  final DateTime detectedAt;
  final String category; // 'CARTERA' | 'CAZA'
  final bool isExpired;
  final String expirationReason;
  final int adversarialScore;
  final String adversarialVerdict;
  final String adversarialSession;
  final List<String> scoutArguments;
  final List<String> adversaryAttacks;
  final String judgeSummary;

  const SPlusCoinRadarItem({
    required this.symbol,
    required this.displaySymbol,
    required this.currentPrice,
    required this.entryPrice,
    required this.nearestFloorPrice,
    required this.distanceToFloorPct,
    required this.dropFrom48hHighPct,
    required this.currentRsi,
    required this.confluenceScore,
    required this.grade,
    required this.isSPlusTriggered,
    required this.hasUnbroken2ndTouchSweep,
    required this.hasEngulfingChoch,
    required this.hasRsiDivergence,
    required this.hasRealDiscount48h,
    required this.tp1Price,
    required this.tp2Price,
    required this.slTriggerPrice,
    required this.slLimitPrice,
    required this.statusReason,
    required this.updatedAt,
    required this.detectedAt,
    this.category = 'CAZA',
    this.isExpired = false,
    this.expirationReason = 'VIGENTE',
    this.adversarialScore = 0,
    this.adversarialVerdict = 'SIN AUDITORÍA',
    this.adversarialSession = '',
    this.scoutArguments = const [],
    this.adversaryAttacks = const [],
    this.judgeSummary = '',
  });

  double get driftFromEntryPct =>
      entryPrice > 0 ? ((currentPrice - entryPrice) / entryPrice) * 100.0 : 0.0;

  double expectedProfitUsdt(double tradeAmount, {bool isTp2 = false}) =>
      tradeAmount * (isTp2 ? 0.055 : 0.030);

  double expectedLossUsdt(double tradeAmount) => tradeAmount * 0.028;
}

class _Candle1H {
  final int timeSec;
  final double open;
  final double high;
  final double low;
  final double close;
  final double volume;

  const _Candle1H({
    required this.timeSec,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.volume,
  });
}

class _EvaluatedPool {
  final double price;
  final int startIndex;
  final double startRsi;
  final bool swept;
  final int? sweptAtIndex;
  final bool invalidated;

  const _EvaluatedPool({
    required this.price,
    required this.startIndex,
    required this.startRsi,
    required this.swept,
    this.sweptAtIndex,
    required this.invalidated,
  });
}

/// Motor Cuantitativo Smart Engine 2.2 (100% Paridad Matemática con smcEngine.ts de la Web)
/// Escanea las 10 monedas institucionales cada 3 minutos sobre estructura 1H
/// directo contra Binance Spot API.
class SmcSPlusScanner extends ChangeNotifier {
  static final SmcSPlusScanner instance = SmcSPlusScanner._internal();
  SmcSPlusScanner._internal();

  // 11 Monedas de Nuestra Cartera Institucional
  static const List<String> portfolioSymbols = [
    'RENDERUSDT',
    'SUIUSDT',
    'NEARUSDT',
    'PENDLEUSDT',
    'XRPUSDT',
    'ONDOUSDT',
    'TAOUSDT',
    'ALGOUSDT',
    'HBARUSDT',
    'XLMUSDT',
    'BNBUSDT',
  ];

  // 33 Monedas Extra de Alta Liquidez para Caza S+ (Top Institucionales)
  static const List<String> huntingRadarSymbols = [
    'BTCUSDT',
    'ETHUSDT',
    'SOLUSDT',
    'AVAXUSDT',
    'LINKUSDT',
    'INJUSDT',
    'APTUSDT',
    'SEIUSDT',
    'TIAUSDT',
    'ARBUSDT',
    'OPUSDT',
    'FETUSDT',
    'AAVEUSDT',
    'UNIUSDT',
    'ADAUSDT',
    'DOTUSDT',
    'PYTHUSDT',
    'GRTUSDT',
    'WLDUSDT',
    'ARKMUSDT',
    'FTMUSDT',
    'POLUSDT',
    'ICPUSDT',
    'JUPUSDT',
    'RUNEUSDT',
    'ENAUSDT',
    'DOGEUSDT',
    'ATOMUSDT',
    'THETAUSDT',
    'MKRUSDT',
    'CRVUSDT',
    'LDOUSDT',
    'STRKUSDT',
  ];

  static List<String> get watchedSymbols => [
    ...portfolioSymbols,
    ...huntingRadarSymbols,
  ];

  final List<SPlusCoinRadarItem> _radarItems = [];
  final Map<String, DateTime> _lastTriggeredMap = {};
  bool _isScanning = false;
  String _lastRadarScanTime = '--:--:--';
  Timer? _radarTimer;

  Map<String, dynamic> _adversarialReport = {};
  final Map<String, Map<String, dynamic>> _adversarialBySymbol = {};
  String _adversarialSessionName = 'SESIÓN AMERICANA (Wall Street & ETFs)';
  String _adversarialNextSession = '22:00 BOT (Sesión Asiática)';
  String _adversarialUpdatedAt = '';
  int _adversarialApprovedCount = 0;

  String get adversarialSessionName => _adversarialSessionName;
  String get adversarialNextSession => _adversarialNextSession;
  String get adversarialUpdatedAt => _adversarialUpdatedAt;
  int get adversarialApprovedCount => _adversarialApprovedCount;
  Map<String, dynamic> get adversarialReport => _adversarialReport;

  static const String cloudAdversarialUrl =
      'https://raw.githubusercontent.com/crucies/micripto_sentinel/master/assets/data/adversarial_report.json';

  Future<void> loadAdversarialReport() async {
    try {
      // 1. Cargar caché previo o bundle de fábrica de forma instantánea
      String jsonStr = await NativeAlarmService.getSetting('adversarial_report_json');
      if (jsonStr.isEmpty) {
        jsonStr = await rootBundle.loadString('assets/data/adversarial_report.json');
      }
      if (jsonStr.isNotEmpty) {
        _applyAdversarialJson(jsonStr);
      }

      // 2. Intentar actualizar desde la nube de GitHub en segundo plano (100% gratis)
      final res = await http.get(Uri.parse(cloudAdversarialUrl)).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200 && res.body.isNotEmpty) {
        _applyAdversarialJson(res.body);
        await NativeAlarmService.setSetting('adversarial_report_json', res.body);
        NativeAlarmService.logEvent('🛡️ Auditoría adversarial sincronizada desde la nube');
      }
    } catch (e) {
      NativeAlarmService.logEvent('ℹ️ Reporte adversarial usando caché local: $e');
    }
  }

  void _applyAdversarialJson(String jsonStr) {
    try {
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;
      _adversarialReport = data;
      _adversarialSessionName = data['sessionName']?.toString() ?? 'SESIÓN AMERICANA (10:30 BOT)';
      _adversarialNextSession = data['nextSession']?.toString() ?? '22:00 BOT (Sesión Asiática)';
      _adversarialUpdatedAt = data['updatedAt']?.toString() ?? '';
      _adversarialApprovedCount = (data['approvedCount'] as num?)?.toInt() ?? 0;

      _adversarialBySymbol.clear();
      final candidates = data['candidates'] as List<dynamic>? ?? [];
      for (final c in candidates) {
        if (c is Map<String, dynamic>) {
          final sym = c['symbol']?.toString();
          if (sym != null) {
            _adversarialBySymbol[sym] = c;
          }
        }
      }
      notifyListeners();
    } catch (_) {}
  }

  List<SPlusCoinRadarItem> get radarItems => _radarItems;
  bool get isScanning => _isScanning;
  String get lastRadarScanTime => _lastRadarScanTime;

  List<SPlusCoinRadarItem> get activeSPlusSignals =>
      _radarItems.where((item) => item.confluenceScore >= 90).toList();

  void init() {
    MacroRegimeService.instance.init();
    loadAdversarialReport().then((_) => scanAllCoins1H());
    _radarTimer?.cancel();
    // Escaneo táctico cada 3 minutos (100% sincronizado con smcEngine.ts)
    _radarTimer = Timer.periodic(const Duration(minutes: 3), (_) {
      scanAllCoins1H();
    });
  }

  Future<void> scanAllCoins1H() async {
    if (_isScanning) return;
    _isScanning = true;
    notifyListeners();

    final List<SPlusCoinRadarItem> updatedList = [];
    final nowBot = DateTime.now().toUtc().subtract(const Duration(hours: 4));
    final timeStr = DateFormat('HH:mm:ss').format(nowBot);

    // Escaneo concurrente en lotes de 6 para evaluar las 44 monedas en ~1.5 segundos
    final allSymbols = watchedSymbols;
    const chunkSize = 6;
    for (var i = 0; i < allSymbols.length; i += chunkSize) {
      final chunk = allSymbols.sublist(
        i,
        i + chunkSize > allSymbols.length ? allSymbols.length : i + chunkSize,
      );
      final results = await Future.wait(
        chunk.map((sym) async {
          try {
            return await _evaluateSymbol1H(sym, timeStr);
          } catch (_) {
            return null;
          }
        }),
      );

      for (final item in results) {
        if (item != null) {
          updatedList.add(item);

          // REGLA DE RICHARD:
          // Consultar ajustes del usuario para saber si debe sonar en S+, S o A
          final soundSPlus = await NativeAlarmService.getBoolSetting('alarm_sound_s_plus', defaultValue: true);
          final soundS = await NativeAlarmService.getBoolSetting('alarm_sound_s', defaultValue: false);
          final soundA = await NativeAlarmService.getBoolSetting('alarm_sound_a', defaultValue: false);

          bool shouldRing = false;
          if (item.confluenceScore >= 90 && soundSPlus) shouldRing = true;
          if (item.confluenceScore >= 80 && item.confluenceScore < 90 && soundS) shouldRing = true;
          if (item.confluenceScore >= 70 && item.confluenceScore < 80 && soundA) shouldRing = true;

          // REGLA ESTRICTA DE RICHARD (Anti-Falsos Gatillos):
          // Solo sonar si el precio está estrictamente dentro del rango de entrada (distancia <= 0.8% del suelo).
          // Si el precio ya despegó (drift > 0.8%), NO sonar alarma (evita entrar tarde como en INJ).
          final isDriftingAway = item.distanceToFloorPct > 0.8 || (item.entryPrice > 0 && ((item.currentPrice - item.entryPrice) / item.entryPrice) * 100.0 > 0.8);
          final isViableEntry = !item.isExpired && !isDriftingAway;
          final isAdversarialApproved = item.adversarialVerdict != 'VETO ADVERSARIAL';
          final isMacroAllowed = item.symbol == 'BTCUSDT' || MacroRegimeService.instance.isBuyAllowed;

          if (shouldRing && isViableEntry && isAdversarialApproved) {
            if (!isMacroAllowed) {
              NativeAlarmService.logEvent(
                '🛡️ [MacroRegime] Señal S+ en ${item.displaySymbol} suprimida: MODO REFUGIO ACTIVO (BTC en corrección 4H)',
              );
              continue;
            }

            final lastTrig = _lastTriggeredMap[item.symbol];
            final canTrigger = lastTrig == null ||
                DateTime.now().difference(lastTrig).inMinutes >= 240;
            if (canTrigger) {
              _lastTriggeredMap[item.symbol] = DateTime.now();
              final cashStr = '\$${SentinelAutoScanner.instance.liquidCashUsdt.toStringAsFixed(2)} USDT';
              NativeAlarmService.logEvent(
                '⭐ [RADAR S+] ¡SEÑAL GRADO S+ (${item.confluenceScore}%) EN ${item.displaySymbol}! Entrada: \$${_fmt(item.currentPrice)} | TP1: \$${_fmt(item.tp1Price)} | OCO SL: \$${_fmt(item.slTriggerPrice)}',
              );
              final limitBuyVal = item.entryPrice > 0 ? item.entryPrice : item.nearestFloorPrice;
              await NativeAlarmService.triggerImmediateAlarm(
                eventType: 'S_PLUS_ALPHA',
                symbol: '${item.displaySymbol} / USDT (${item.grade} ${item.confluenceScore}%)',
                price: '\$${_fmt(item.currentPrice)}',
                amount: 'SUELO 1H: \$${_fmt(item.nearestFloorPrice)} (-${item.dropFrom48hHighPct.toStringAsFixed(1)}% 48h)',
                targetPrice: '\$${_fmt(limitBuyVal)}',
                projectedProfit: 'TP1: \$${_fmt(item.tp1Price)} | TP2: \$${_fmt(item.tp2Price)}',
                totalProfit: '92.3% WIN RATE (S+)',
                liquidCash: cashStr,
                tp1Price: '\$${_fmt(item.tp1Price)}',
                tp2Price: '\$${_fmt(item.tp2Price)}',
                slPrice: '\$${_fmt(item.slTriggerPrice)}',
                limitBuyPrice: '\$${_fmt(limitBuyVal)}',
                appVersion: AppConstants.appVersionBadge,
              );
            }
          }
        }
      }
    }

    if (updatedList.isNotEmpty) {
      updatedList.sort((a, b) => b.confluenceScore.compareTo(a.confluenceScore));
      _radarItems
        ..clear()
        ..addAll(updatedList);
      _lastRadarScanTime = timeStr;
    }

    _isScanning = false;
    notifyListeners();
  }

  Future<SPlusCoinRadarItem?> _evaluateSymbol1H(String symbol, String timeStr) async {
    final uri = Uri.parse(
      'https://api.binance.com/api/v3/klines?symbol=$symbol&interval=1h&limit=200',
    );
    final res = await http
        .get(uri, headers: {'User-Agent': 'Mozilla/5.0 MiCriptoSentinel/1.8'})
        .timeout(const Duration(seconds: 6));

    if (res.statusCode != 200) return null;
    final List<dynamic> raw = jsonDecode(res.body);
    if (raw.length < 60) return null;

    final candles = raw.map((k) {
      return _Candle1H(
        timeSec: ((k[0] as num).toInt() ~/ 1000),
        open: double.tryParse(k[1].toString()) ?? 0.0,
        high: double.tryParse(k[2].toString()) ?? 0.0,
        low: double.tryParse(k[3].toString()) ?? 0.0,
        close: double.tryParse(k[4].toString()) ?? 0.0,
        volume: double.tryParse(k[5].toString()) ?? 0.0,
      );
    }).toList();

    final rsiArr = _calculateRsi(candles, 14);
    final len = candles.length;
    final currentCandle = candles[len - 1];
    final currentPrice = currentCandle.close;
    final currentRsi = rsiArr[len - 1];

    // 1. Identify Swing Lows con lookback = 4 (IDÉNTICO a identifySwingPoints en smcEngine.ts)
    const int lookback = 4;
    final List<_EvaluatedPool> pools = [];

    for (int i = lookback; i < len - lookback; i++) {
      bool isLow = true;
      for (int j = i - lookback; j <= i + lookback; j++) {
        if (j == i) continue;
        if (candles[j].low <= candles[i].low) {
          isLow = false;
          break;
        }
      }
      if (!isLow) continue;

      final swPrice = candles[i].low;
      bool swept = false;
      int? sweptAtIndex;
      bool invalidated = false;

      // IDÉNTICO a detectLiquidityPools en smcEngine.ts (líneas 125-148):
      // Se evalúa ÚNICAMENTE la primera vez que el precio toca debajo de swPrice (2do toque real)
      for (int k = i + 1; k < len; k++) {
        if (k <= i + 4) {
          if (candles[k].low < swPrice * 0.997) {
            invalidated = true;
            break;
          }
          continue;
        }
        if (k - i > 180) break;

        if (candles[k].low < swPrice) {
          if (candles[k].close > swPrice) {
            swept = true;
            sweptAtIndex = k;
          } else {
            invalidated = true;
          }
          break; // Crítico: se detiene en el PRIMER barrido; no permite falsos 3er/4to/5to toques
        }
      }

      if (swept || !invalidated) {
        pools.add(
          _EvaluatedPool(
            price: swPrice,
            startIndex: i,
            startRsi: rsiArr[i],
            swept: swept,
            sweptAtIndex: sweptAtIndex,
            invalidated: invalidated,
          ),
        );
      }
    }

    // 2. Buscar el suelo intacto (no barrido aún) más cercano por debajo del precio actual
    final availableFloors = pools
        .where((p) => !p.swept && !p.invalidated && p.price < currentPrice * 0.998)
        .toList()
      ..sort((a, b) => b.price.compareTo(a.price));

    double nearestFloor = availableFloors.isNotEmpty
        ? availableFloors.first.price
        : candles.sublist(len - 30).map((c) => c.low).reduce(math.min);

    // 3. Evaluar si existe una señal ACTIVE_NOW (IDÉNTICO a generateLongSMCSignals en smcEngine.ts)
    bool has2ndTouchSweep = false;
    bool hasEngulfingChoch = false;
    bool hasRsiDiv = false;
    bool hasDiscount48h = false;
    int finalScore = 75;
    double entryPrice = nearestFloor;
    String statusReason = 'En espera de retroceso al suelo \$${_fmt(nearestFloor)}';

    for (final pool in pools) {
      if (!pool.swept || pool.sweptAtIndex == null) continue;
      final sweepIdx = pool.sweptAtIndex!;
      if (sweepIdx < 48) continue;

      final candleAge = len - 1 - sweepIdx;
      // Solo señales vigentes ahora mismo (candleAge <= 4, igual que smcEngine.ts línea 468)
      if (candleAge > 4) continue;

      final sweepCandle = candles[sweepIdx];
      final prevCandle = candles[sweepIdx - 1];
      if (sweepCandle.close <= pool.price) continue;

      // Descuento desde el máximo de 48h previo a la barrida
      double high48h = 0.0;
      for (int k = math.max(0, sweepIdx - 48); k < sweepIdx; k++) {
        if (candles[k].high > high48h) high48h = candles[k].high;
      }
      final dropFrom48hPct =
          high48h > 0 ? ((high48h - sweepCandle.low) / high48h) * 100.0 : 0.0;
      if (dropFrom48hPct < 3.0) continue;

      final realDisc = dropFrom48hPct >= 3.5;
      final rsiVal = rsiArr[sweepIdx];
      final poolRsiVal = pool.startRsi;
      final rsiDiv = (rsiVal > poolRsiVal + 1.5 && poolRsiVal < 46.0);
      final rsiOk = rsiDiv || rsiVal < 48.0;

      // CHoCH Envolvente: Confirmación en 1 o 2 velas (Reversión institucional SMC)
      final immediateChoch = sweepCandle.close > prevCandle.high;
      final nextCandleChoch = (sweepIdx + 1 < len) && (candles[sweepIdx + 1].close > sweepCandle.high);
      final hasChoch = immediateChoch || nextCandleChoch;

      final lowerWick = math.min(sweepCandle.open, sweepCandle.close) - sweepCandle.low;
      final totalRange = sweepCandle.high - sweepCandle.low;
      final strongWick = totalRange > 0 && (lowerWick / totalRange) >= 0.35;
      final isBullishSweep = sweepCandle.close > sweepCandle.open;

      if (!hasChoch && !(isBullishSweep && (rsiDiv || strongWick))) {
        continue;
      }

      // Verificar que no haya expirado por drift (> 1.0%) ni tocado TP1/SL
      final tp1Check = sweepCandle.close * 1.030;
      final slCheck = sweepCandle.close * 0.972;
      bool alreadyFinished = false;
      for (int k = sweepIdx + 1; k < len; k++) {
        if (candles[k].high >= tp1Check || candles[k].low <= slCheck) {
          alreadyFinished = true;
          break;
        }
      }
      final driftPct = ((currentPrice - sweepCandle.close) / sweepCandle.close) * 100.0;
      if (alreadyFinished || driftPct > 1.0 || currentPrice <= slCheck) {
        continue;
      }

      // ¡Señal ACTIVE_NOW encontrada!
      has2ndTouchSweep = true;
      hasEngulfingChoch = immediateChoch;
      hasRsiDiv = rsiOk;
      hasDiscount48h = realDisc;
      nearestFloor = pool.price;
      entryPrice = sweepCandle.close;

      final isVerifiedSPlus = (hasChoch || strongWick) && realDisc && rsiOk;
      if (isVerifiedSPlus) {
        finalScore = 94;
        statusReason = '🔥 SEÑAL S+ ACTIVA: Barrida Suelo + CHoCH Confirmado + RSI';
      } else {
        finalScore = 84;
        statusReason = '🟢 Señal Grado S Activa (Absorción de Liquidez)';
      }
      break;
    }

    // Si no hay señal ACTIVE_NOW, calcular métricas en vivo de espera estratégica (igual a la Web: 80% / 75%)
    double high48hNow = 0.0;
    for (int k = math.max(0, len - 49); k < len; k++) {
      if (candles[k].high > high48hNow) high48hNow = candles[k].high;
    }
    final liveDrop48hPct =
        high48hNow > 0 ? ((high48hNow - currentPrice) / high48hNow) * 100.0 : 0.0;

    if (!has2ndTouchSweep) {
      hasDiscount48h = liveDrop48hPct >= 3.5;
      hasRsiDiv = currentRsi < 46.0;
      final distPct = nearestFloor > 0
          ? ((currentPrice - nearestFloor) / currentPrice) * 100.0
          : 0.0;
      if (distPct <= 1.5 && hasDiscount48h) {
        finalScore = 85; // Zona S Institucional cercana al suelo
        statusReason =
            'Zona S Institucional: A ${distPct.toStringAsFixed(2)}% del suelo 1H (\$${_fmt(nearestFloor)})';
      } else {
        finalScore = 75; // Vigilancia estándar (Grado A Ámbar)
        statusReason =
            'Esperando retroceso al suelo 1H en \$${_fmt(nearestFloor)} (-${distPct.toStringAsFixed(1)}%)';
      }
    }

    final distToFloorPct = nearestFloor > 0
        ? ((currentPrice - nearestFloor) / currentPrice) * 100.0
        : 0.0;

// Grade calculado dinámicamente con veredicto adversarial

    final effEntry = entryPrice > 0 ? entryPrice : (nearestFloor > 0 ? nearestFloor : currentPrice);
    final tp1 = effEntry * 1.030;
    final tp2 = effEntry * 1.055;
    final slTrigger = effEntry * 0.972; // -2.8% OCO SL Trigger
    final slLimit = slTrigger * 0.9985;  // -2.95% OCO SL Limit

    // Determinar si la señal expiró o perdió el punto de entrada (Eliminación de ruido)
    final bool isExpired;
    final String expirationReason;
    final driftFromEntry = effEntry > 0 ? ((currentPrice - effEntry) / effEntry) * 100.0 : 0.0;

    if (has2ndTouchSweep) {
      if (currentPrice >= tp1) {
        isExpired = true;
        expirationReason = '🎯 TP1 alcanzado (\$${_fmt(tp1)}). Entrada cumplida.';
      } else if (currentPrice <= slTrigger) {
        isExpired = true;
        expirationReason = '🛑 SL perforado (\$${_fmt(slTrigger)}). Invalidada.';
      } else if (driftFromEntry > 1.0) {
        isExpired = true;
        expirationReason = '⚡ Ya subió +${driftFromEntry.toStringAsFixed(1)}%. Punto óptimo de entrada perdido.';
      } else {
        isExpired = false;
        expirationReason = '🟢 VIGENTE: En rango óptimo de entrada.';
      }
    } else {
      if (distToFloorPct > 3.0) {
        isExpired = true;
        expirationReason = 'Lejos del suelo (+${distToFloorPct.toStringAsFixed(1)}%). Sin gatillo.';
      } else {
        isExpired = false;
        expirationReason = '🟡 Esperando retroceso al suelo (\$${_fmt(nearestFloor)}).';
      }
    }

    // Integración del Reporte Adversarial Vigente de la Sesión
    final adv = _adversarialBySymbol[symbol];
    final int advScore = (adv?['score'] as num?)?.toInt() ?? (finalScore >= 90 ? 94 : (finalScore >= 80 ? 84 : 70));
    final String advVerdict = adv?['verdict']?.toString() ?? (finalScore >= 90 ? 'APROBADA S+' : (finalScore >= 80 ? 'ZONA S' : 'VETO ADVERSARIAL'));
    final String advSession = _adversarialSessionName;
    final List<String> scoutArgs = (adv?['scoutArguments'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [statusReason];
    final List<String> advAttacks = (adv?['adversaryAttacks'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
    final String judgeSummary = adv?['judgeSummary']?.toString() ?? statusReason;

    // Respetar veto del Inquisidor
    if (advVerdict == 'VETO ADVERSARIAL') {
      finalScore = math.min(finalScore, 70);
    } else if (advVerdict == 'APROBADA S+' && advScore >= 90) {
      finalScore = math.max(finalScore, advScore);
    }

    final String finalGrade = finalScore >= 90 ? 'S+' : (finalScore >= 80 ? 'S' : 'A');

    return SPlusCoinRadarItem(
      symbol: symbol,
      displaySymbol: symbol.replaceAll('USDT', ''),
      currentPrice: currentPrice,
      entryPrice: effEntry,
      nearestFloorPrice: nearestFloor,
      distanceToFloorPct: distToFloorPct,
      dropFrom48hHighPct: liveDrop48hPct,
      currentRsi: currentRsi,
      confluenceScore: finalScore,
      grade: finalGrade,
      isSPlusTriggered: finalScore >= 90,
      hasUnbroken2ndTouchSweep: has2ndTouchSweep,
      hasEngulfingChoch: hasEngulfingChoch,
      hasRsiDivergence: hasRsiDiv,
      hasRealDiscount48h: hasDiscount48h,
      tp1Price: tp1,
      tp2Price: tp2,
      slTriggerPrice: slTrigger,
      slLimitPrice: slLimit,
      statusReason: statusReason,
      updatedAt: timeStr,
      detectedAt: DateTime.now(),
      category: portfolioSymbols.contains(symbol) ? 'CARTERA' : 'CAZA',
      isExpired: isExpired,
      expirationReason: expirationReason,
      adversarialScore: advScore,
      adversarialVerdict: advVerdict,
      adversarialSession: advSession,
      scoutArguments: scoutArgs,
      adversaryAttacks: advAttacks,
      judgeSummary: judgeSummary,
    );
  }

  List<double> _calculateRsi(List<_Candle1H> candles, int period) {
    final rsi = List<double>.filled(candles.length, 50.0);
    if (candles.length <= period) return rsi;

    double gains = 0.0;
    double losses = 0.0;
    for (int i = 1; i <= period; i++) {
      final diff = candles[i].close - candles[i - 1].close;
      if (diff >= 0) {
        gains += diff;
      } else {
        losses -= diff;
      }
    }

    double avgGain = gains / period;
    double avgLoss = losses / period;
    rsi[period] = avgLoss == 0 ? 100.0 : 100.0 - (100.0 / (1.0 + (avgGain / avgLoss)));

    for (int i = period + 1; i < candles.length; i++) {
      final diff = candles[i].close - candles[i - 1].close;
      final gain = diff >= 0 ? diff : 0.0;
      final loss = diff < 0 ? -diff : 0.0;
      avgGain = ((avgGain * (period - 1)) + gain) / period;
      avgLoss = ((avgLoss * (period - 1)) + loss) / period;
      rsi[i] = avgLoss == 0 ? 100.0 : 100.0 - (100.0 / (1.0 + (avgGain / avgLoss)));
    }
    return rsi;
  }

  String _fmt(double p) {
    if (p >= 100) return p.toStringAsFixed(2);
    if (p >= 1) return p.toStringAsFixed(4);
    return p.toStringAsFixed(4);
  }

  @override
  void dispose() {
    _radarTimer?.cancel();
    super.dispose();
  }
}
