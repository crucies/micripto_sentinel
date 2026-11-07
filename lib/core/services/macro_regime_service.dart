import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

enum MacroRegimeState {
  hunt, // 🟢 Risk-On (BTC sobre EMA20 4H y RSI > 50)
  defensive, // 🟡 Cautela (BTC lateral / testeando soporte)
  refuge, // 🔴 Risk-Off (BTC en corrección / bajo EMA20 4H & RSI < 48)
}

/// Motor de Régimen Macro de Bitcoin (Richard & Kai)
/// Evalúa la estructura de 4H de BTCUSDT para determinar el clima del mercado
/// y gobernar la agresividad de compras en altcoins del Centinela.
class MacroRegimeService extends ChangeNotifier {
  static final MacroRegimeService instance = MacroRegimeService._internal();
  MacroRegimeService._internal();

  double _btcPrice = 0.0;
  double _btcChange24h = 0.0;
  double _btcRsi4h = 50.0;
  double _btcEma20 = 0.0;
  double _btcHigh48h = 0.0;
  double _btcDropFromHighPct = 0.0;
  MacroRegimeState _regimeState = MacroRegimeState.defensive;
  String _lastUpdate = '--:--';
  bool _isLoading = false;
  Timer? _refreshTimer;

  double get btcPrice => _btcPrice;
  double get btcChange24h => _btcChange24h;
  double get btcRsi4h => _btcRsi4h;
  double get btcEma20 => _btcEma20;
  double get btcDropFromHighPct => _btcDropFromHighPct;
  double get btcHigh48h => _btcHigh48h;
  MacroRegimeState get regimeState => _regimeState;
  String get lastUpdate => _lastUpdate;
  bool get isLoading => _isLoading;

  bool get isBuyAllowed => _regimeState != MacroRegimeState.refuge;
  double get positionMultiplier => _regimeState == MacroRegimeState.hunt
      ? 1.0
      : (_regimeState == MacroRegimeState.defensive ? 0.5 : 0.0);

  String get regimeName {
    switch (_regimeState) {
      case MacroRegimeState.hunt:
        return '🟢 MODO CAZA (EXPANSIÓN)';
      case MacroRegimeState.defensive:
        return '🟡 MODO DEFENSIVO (CAUTELA)';
      case MacroRegimeState.refuge:
        return '🔴 MODO REFUGIO (CORRECCIÓN)';
    }
  }

  String get regimeDirective {
    switch (_regimeState) {
      case MacroRegimeState.hunt:
        return 'BTC en tendencia sana 4H. Clima favorable: Radar S+ habilitado al 100% de tamaño (\$200 USDT).';
      case MacroRegimeState.defensive:
        return 'BTC en consolidación lateral. Clima neutral: Disparos limitados al 50% (\$100 USDT) y máxima confluencia.';
      case MacroRegimeState.refuge:
        return 'BTC bajo presión bajista en 4H. Clima hostil: COMPRAS EN ALTCOINS SUSPENDIDAS. Solo cobro de TPs y gestión de cartera.';
    }
  }

  void init() {
    refreshRegime();
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(minutes: 2), (_) {
      refreshRegime();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> refreshRegime() async {
    if (_isLoading) return;
    _isLoading = true;

    try {
      final url = Uri.parse('https://api.binance.com/api/v3/klines?symbol=BTCUSDT&interval=4h&limit=60');
      final resp = await http.get(url).timeout(const Duration(seconds: 6));

      if (resp.statusCode == 200) {
        final List<dynamic> data = jsonDecode(resp.body);
        if (data.length >= 30) {
          final closes = <double>[];
          final highs = <double>[];
          final lows = <double>[];

          for (final item in data) {
            closes.add(double.parse(item[4].toString()));
            highs.add(double.parse(item[2].toString()));
            lows.add(double.parse(item[3].toString()));
          }

          final currentClose = closes.last;
          _btcPrice = currentClose;

          // Cambio 24h aproximado (últimas 6 velas de 4H)
          if (closes.length >= 6) {
            final price24hAgo = closes[closes.length - 6];
            _btcChange24h = ((currentClose - price24hAgo) / price24hAgo) * 100.0;
          }

          // Máximo 48h (últimas 12 velas)
          double max48 = 0.0;
          final startIdx = (closes.length - 12).clamp(0, closes.length);
          for (int i = startIdx; i < highs.length; i++) {
            if (highs[i] > max48) max48 = highs[i];
          }
          _btcHigh48h = max48;
          _btcDropFromHighPct = max48 > 0 ? ((max48 - currentClose) / max48) * 100.0 : 0.0;

          // Calcular EMA(20) de 4H
          _btcEma20 = _calculateEma(closes, 20);

          // Calcular RSI(14) de 4H
          _btcRsi4h = _calculateRsi(closes, 14);

          // Regla de Clasificación de Régimen Macro:
          // 🔴 REFUGIO: Si BTC está bajo su EMA20 4H Y RSI < 48, o caída > 4.5% desde el pico de 48h
          // 🟢 CAZA: Si BTC está sobre su EMA20 4H Y RSI >= 52
          // 🟡 DEFENSIVO: En cualquier estado intermedio
          if ((currentClose < _btcEma20 && _btcRsi4h < 48.0) || _btcDropFromHighPct >= 5.0) {
            _regimeState = MacroRegimeState.refuge;
          } else if (currentClose >= _btcEma20 && _btcRsi4h >= 52.0 && _btcDropFromHighPct < 3.0) {
            _regimeState = MacroRegimeState.hunt;
          } else {
            _regimeState = MacroRegimeState.defensive;
          }

          final now = DateTime.now().toUtc().subtract(const Duration(hours: 4));
          _lastUpdate = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} BOT';
        }
      }
    } catch (_) {
      // Degradación elegante: mantiene el último estado conocido
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  double _calculateEma(List<double> values, int period) {
    if (values.length < period) return values.last;
    final k = 2.0 / (period + 1);
    double ema = values.take(period).reduce((a, b) => a + b) / period;
    for (int i = period; i < values.length; i++) {
      ema = (values[i] * k) + (ema * (1.0 - k));
    }
    return ema;
  }

  double _calculateRsi(List<double> values, int period) {
    if (values.length <= period) return 50.0;
    double gains = 0.0;
    double losses = 0.0;

    for (int i = 1; i <= period; i++) {
      final diff = values[i] - values[i - 1];
      if (diff >= 0) {
        gains += diff;
      } else {
        losses -= diff;
      }
    }

    double avgGain = gains / period;
    double avgLoss = losses / period;

    for (int i = period + 1; i < values.length; i++) {
      final diff = values[i] - values[i - 1];
      final g = diff >= 0 ? diff : 0.0;
      final l = diff < 0 ? -diff : 0.0;
      avgGain = ((avgGain * (period - 1)) + g) / period;
      avgLoss = ((avgLoss * (period - 1)) + l) / period;
    }

    if (avgLoss == 0.0) return 100.0;
    final rs = avgGain / avgLoss;
    return 100.0 - (100.0 / (1.0 + rs));
  }
}
