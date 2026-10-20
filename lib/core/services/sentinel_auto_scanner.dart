import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../../features/orders/domain/order_entity.dart';
import 'native_alarm_service.dart';
import 'smc_s_plus_scanner.dart';

class SentinelAutoScanner extends ChangeNotifier {
  static final SentinelAutoScanner instance = SentinelAutoScanner._internal();
  SentinelAutoScanner._internal();

  static const String cloudOrdersUrl = 'https://micripto-lts.vercel.app/api/orders';
  static const String binanceTickerUrl = 'https://api.binance.com/api/v3/ticker/price';

  List<OrderEntity> _orders = [...OrderEntity.currentLiveOrders];
  final Map<String, double> _livePrices = {};
  final Map<String, double> _distancePctMap = {};
  final Set<String> _triggeredOrderIds = {};

  bool _isScanning = false;
  bool _isSyncingCloud = false;
  String _lastScanTime = '--:--:--';
  String _lastCloudSyncTime = 'Pendiente';
  String _statusMessage = '🟢 CENTINELA VIGILANDO: Auto-scan cada 25s + Radar S+ (3m)';
  double _liquidCashUsdt = 0.91;

  Timer? _foregroundScanTimer;
  Timer? _cloudSyncTimer;

  List<OrderEntity> get orders => _orders;
  Map<String, double> get livePrices => _livePrices;
  Map<String, double> get distancePctMap => _distancePctMap;
  bool get isScanning => _isScanning;
  bool get isSyncingCloud => _isSyncingCloud;
  String get lastScanTime => _lastScanTime;
  String get lastCloudSyncTime => _lastCloudSyncTime;
  String get statusMessage => _statusMessage;
  double get liquidCashUsdt => _liquidCashUsdt;

  void setLiquidCash(double value) {
    _liquidCashUsdt = value;
    notifyListeners();
  }

  double get totalExpectedReturn => _orders.fold(0.0, (sum, o) => sum + o.expectedReturnUsdt);
  double get totalProjectedProfit => _orders.fold(0.0, (sum, o) => sum + o.projectedProfitUsdt);

  /// Inicializar el Centinela Autónomo
  Future<void> init() async {
    // 1. Cargar órdenes guardadas en SharedPreferences nativo
    await _loadLocalCachedOrders();

    // 2. Sincronizar de inmediato con la nube (Vercel api/orders)
    await syncOrdersFromCloud();

    // 3. Ejecutar el primer escaneo de precios de Binance
    await scanBinancePrices();

    // 4. Iniciar Radar Cuantitativo Smart Engine 2.2 (S+ 1H cada 3 minutos)
    SmcSPlusScanner.instance.init();

    // 5. Iniciar temporizador de escaneo en primer plano cada 25 segundos (100% automático)
    _foregroundScanTimer?.cancel();
    _foregroundScanTimer = Timer.periodic(const Duration(seconds: 25), (_) async {
      await scanBinancePrices();
    });

    // 6. Iniciar temporizador de sincronización de órdenes con la nube cada 3 minutos
    _cloudSyncTimer?.cancel();
    _cloudSyncTimer = Timer.periodic(const Duration(minutes: 3), (_) async {
      await syncOrdersFromCloud();
    });

    // 7. Activar Centinela Nativo de Fondo en Android (Despierta con AlarmClock en Doze Mode)
    await NativeAlarmService.startNativeBackgroundScan();
  }

  /// Cargar órdenes guardadas localmente
  Future<void> _loadLocalCachedOrders() async {
    try {
      final cachedJson = await NativeAlarmService.getCachedOrders();
      if (cachedJson != null && cachedJson.isNotEmpty) {
        final List<dynamic> list = jsonDecode(cachedJson);
        if (list.isNotEmpty) {
          _orders = list.map((item) => OrderEntity.fromJson(item as Map<String, dynamic>)).toList();
          notifyListeners();
        }
      }
    } catch (e) {
      NativeAlarmService.logEvent('⚠️ Error cargando órdenes en caché: $e');
    }
  }

  /// Sincronizar órdenes dinámicas desde la plataforma web (Vercel)
  Future<void> syncOrdersFromCloud() async {
    _isSyncingCloud = true;
    notifyListeners();

    try {
      final res = await http.get(Uri.parse(cloudOrdersUrl)).timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['metrics'] != null && data['metrics']['liquidCashUsdt'] != null) {
          _liquidCashUsdt = (data['metrics']['liquidCashUsdt'] as num).toDouble();
        }
        if (data['success'] == true && data['orders'] is List) {
          final List<dynamic> rawOrders = data['orders'];
          if (rawOrders.isNotEmpty) {
            _orders = rawOrders.map((item) => OrderEntity.fromJson(item as Map<String, dynamic>)).toList();
            
            // Guardar en SharedPreferences nativo para que el escáner de fondo también las tenga
            final jsonStr = jsonEncode(_orders.map((o) => o.toJson()).toList());
            await NativeAlarmService.saveCachedOrders(jsonStr);

            final now = DateTime.now().toUtc().subtract(const Duration(hours: 4));
            _lastCloudSyncTime = DateFormat('HH:mm:ss').format(now);
            _statusMessage = '🟢 CENTINELA VIGILANDO: ${_orders.length} órdenes vivas (Nube Sincronizada)';
            NativeAlarmService.logEvent('✅ Órdenes sincronizadas desde la nube (${_orders.length} órdenes)');
          }
        }
      }
    } catch (e) {
      NativeAlarmService.logEvent('⚠️ Error sincronizando órdenes desde la nube: $e');
    } finally {
      _isSyncingCloud = false;
      notifyListeners();
    }
  }

  /// Escanear precios en vivo de Binance y disparar alarma militar si se cumple el precio
  Future<void> scanBinancePrices() async {
    if (_isScanning) return;
    _isScanning = true;
    notifyListeners();

    try {
      final res = await http.get(
        Uri.parse(binanceTickerUrl),
        headers: {'User-Agent': 'Mozilla/5.0 MiCriptoSentinel/1.0'},
      ).timeout(const Duration(seconds: 5));

      if (res.statusCode == 200) {
        final List<dynamic> priceList = jsonDecode(res.body);
        final priceMap = <String, double>{};
        for (final item in priceList) {
          final sym = item['symbol']?.toString();
          final pr = double.tryParse(item['price']?.toString() ?? '0');
          if (sym != null && pr != null) {
            priceMap[sym] = pr;
          }
        }

        final now = DateTime.now().toUtc().subtract(const Duration(hours: 4));
        _lastScanTime = DateFormat('HH:mm:ss').format(now);

        // Evaluar cada orden de la lista activa
        for (final order in _orders) {
          final curPrice = priceMap[order.symbol];
          if (curPrice == null || curPrice <= 0) continue;

          _livePrices[order.symbol] = curPrice;

          // Calcular distancia porcentual hacia el objetivo de salida
          final distPct = ((order.targetPrice - curPrice) / curPrice) * 100;
          _distancePctMap[order.id] = distPct;

          // Comprobar si se alcanzó la meta
          final isSell = order.side.toUpperCase().contains('SELL');
          final isHit = isSell ? (curPrice >= order.targetPrice) : (curPrice <= order.targetPrice);

          if (isHit && !_triggeredOrderIds.contains(order.id)) {
            _triggeredOrderIds.add(order.id);
            NativeAlarmService.logEvent('🎯 ¡ALERTA MILITAR! ${order.displaySymbol} tocó \$${curPrice.toStringAsFixed(4)} (Meta: \$${order.targetPrice.toStringAsFixed(4)})');

            // Disparar Alarma Militar Inmediata (Audio 100%, WakeLock y Formulario Brutalista)
            await NativeAlarmService.triggerImmediateAlarm(
              eventType: isSell ? 'TP_HIT' : 'BUY_FILLED',
              symbol: order.displaySymbol,
              price: '\$${curPrice.toStringAsFixed(4)}',
              amount: '${order.amountCoins} ${order.displaySymbol} (\$${order.expectedReturnUsdt.toStringAsFixed(2)} USDT)',
              targetPrice: '\$${order.targetPrice.toStringAsFixed(4)}',
              projectedProfit: '+\$${order.projectedProfitUsdt.toStringAsFixed(2)} USDT',
              totalProfit: '+\$${totalProjectedProfit.toStringAsFixed(2)} USDT',
              liquidCash: '\$36.59 USDT',
            );
          }
        }
      }
    } catch (e) {
      NativeAlarmService.logEvent('⚠️ Error escaneando Binance: $e');
    } finally {
      _isScanning = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _foregroundScanTimer?.cancel();
    _cloudSyncTimer?.cancel();
    super.dispose();
  }
}
