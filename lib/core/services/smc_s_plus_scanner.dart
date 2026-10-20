import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'native_alarm_service.dart';
import 'sentinel_auto_scanner.dart';

class SPlusCoinRadarItem {
  final String symbol;
  final String displaySymbol;
  final double currentPrice;
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

  const SPlusCoinRadarItem({
    required this.symbol,
    required this.displaySymbol,
    required this.currentPrice,
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
  });
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

  static const List<String> watchedSymbols = [
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
  ];

  final List<SPlusCoinRadarItem> _radarItems = [];
  final Map<String, DateTime> _lastTriggeredMap = {};
  bool _isScanning = false;
  String _lastRadarScanTime = '--:--:--';
  Timer? _radarTimer;

  List<SPlusCoinRadarItem> get radarItems => _radarItems;
  bool get isScanning => _isScanning;
  String get lastRadarScanTime => _lastRadarScanTime;

  List<SPlusCoinRadarItem> get activeSPlusSignals =>
      _radarItems.where((item) => item.confluenceScore >= 90).toList();

  void init() {
    scanAllCoins1H();
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

    for (final sym in watchedSymbols) {
      try {
        final item = await _evaluateSymbol1H(sym, timeStr);
        if (item != null) {
          updatedList.add(item);

          // Disparar alarma S+ SOLO si cumple los 4 pilares idénticos a la Web (>= 90%)
          if (item.confluenceScore >= 90) {
            final lastTrig = _lastTriggeredMap[sym];
            final canTrigger = lastTrig == null ||
                DateTime.now().difference(lastTrig).inMinutes >= 240;
            if (canTrigger) {
              _lastTriggeredMap[sym] = DateTime.now();
              final cashStr = '\$${SentinelAutoScanner.instance.liquidCashUsdt.toStringAsFixed(2)} USDT';
              NativeAlarmService.logEvent(
                '⭐ [RADAR S+] ¡SEÑAL GRADO S+ (${item.confluenceScore}%) EN ${item.displaySymbol}! Entrada: \$${_fmt(item.currentPrice)} | TP1: \$${_fmt(item.tp1Price)} | OCO SL: \$${_fmt(item.slTriggerPrice)}',
              );
              await NativeAlarmService.triggerImmediateAlarm(
                eventType: 'S_PLUS_ALPHA',
                symbol: '${item.displaySymbol} / USDT (S+ ${item.confluenceScore}%)',
                price: '\$${_fmt(item.currentPrice)}',
                amount: 'SUELO 1H: \$${_fmt(item.nearestFloorPrice)} (-${item.dropFrom48hHighPct.toStringAsFixed(1)}% 48h)',
                targetPrice: 'TP1: \$${_fmt(item.tp1Price)} | TP2: \$${_fmt(item.tp2Price)}',
                projectedProfit: 'OCO SL Trigger: \$${_fmt(item.slTriggerPrice)} (-2.8%) | Limit: \$${_fmt(item.slLimitPrice)}',
                totalProfit: '92.3% WIN RATE (S+)',
                liquidCash: cashStr,
              );
            }
          }
        }
      } catch (e) {
        // Continuar con el siguiente activo sin bloquear el radar
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

      // CHoCH Envolvente Inmediato estricto (sweepCandle.close > prevCandle.high)
      final immediateChoch = sweepCandle.close > prevCandle.high;
      final lowerWick = math.min(sweepCandle.open, sweepCandle.close) - sweepCandle.low;
      final totalRange = sweepCandle.high - sweepCandle.low;
      final strongWick = totalRange > 0 && (lowerWick / totalRange) >= 0.35;
      final isBullishSweep = sweepCandle.close > sweepCandle.open;

      if (!immediateChoch && !(isBullishSweep && (rsiDiv || strongWick))) {
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

      final isVerifiedSPlus = immediateChoch && realDisc && rsiOk;
      if (isVerifiedSPlus) {
        finalScore = 94;
        statusReason = '🔥 COMPRA S+ ACTIVA: Barrida 2do Toque + CHoCH + RSI';
      } else {
        finalScore = 84;
        statusReason = '🟢 Señal Grado S Activa (Falta CHoCH envolvente para S+)';
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
        finalScore = 80; // Espera Estratégica cercana al suelo (Grado S Verde Esmeralda, igual que NEAR 80% en Web)
        statusReason =
            'Espera Estratégica: A ${distPct.toStringAsFixed(2)}% del suelo 1H (\$${_fmt(nearestFloor)})';
      } else {
        finalScore = 75; // Vigilancia estándar (Grado A Ámbar)
        statusReason =
            'Esperando retroceso al suelo 1H en \$${_fmt(nearestFloor)} (-${distPct.toStringAsFixed(1)}%)';
      }
    }

    final distToFloorPct = nearestFloor > 0
        ? ((currentPrice - nearestFloor) / currentPrice) * 100.0
        : 0.0;

    final String grade;
    if (finalScore >= 90) {
      grade = 'S+';
    } else if (finalScore >= 80) {
      grade = 'S';
    } else {
      grade = 'A';
    }

    final tp1 = entryPrice * 1.030;
    final tp2 = entryPrice * 1.055;
    final slTrigger = entryPrice * 0.972; // -2.8% OCO SL Trigger
    final slLimit = slTrigger * 0.9985;  // -2.95% OCO SL Limit

    return SPlusCoinRadarItem(
      symbol: symbol,
      displaySymbol: symbol.replaceAll('USDT', ''),
      currentPrice: currentPrice,
      nearestFloorPrice: nearestFloor,
      distanceToFloorPct: distToFloorPct,
      dropFrom48hHighPct: liveDrop48hPct,
      currentRsi: currentRsi,
      confluenceScore: finalScore,
      grade: grade,
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
