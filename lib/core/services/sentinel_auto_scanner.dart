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

  static const String binanceTickerUrl = 'https://api.binance.com/api/v3/ticker/price';

  List<OrderEntity> _orders = [...OrderEntity.currentLiveOrders];
  List<OrderEntity> _archivedOrders = [...OrderEntity.defaultArchivedOrders];
  final Set<String> _archivedOrderIds = {
    'binance-apt-buy-executed-06950',
    'binance-inj-buy-executed-7950',
    'binance-inj-buy-executed-8114',
    'binance-tia-buy-05917',
    'binance-op-sell-tp1-01320',
    'binance-sui-sell-10540',
    'trade-op-buy-filled-01281',
    'binance-op-buy-01281',
    'binance-ondo-sell-04620',
    'binance-inj-sell-tp1-8192',
    'binance-inj-sell-tp2-8320',
    'trade-sui-tp1-10280',
    'trade-render-tp2-1860'
  };

  final Map<String, double> _livePrices = {};
  final Map<String, double> _distancePctMap = {};
  final Set<String> _triggeredOrderIds = {};

  bool _isScanning = false;
  String _lastScanTime = '--:--:--';
  String _statusMessage = '🟢 CENTINELA 100% AUTÓNOMO: Auto-scan Binance cada 25s';
  double _liquidCashUsdt = 458.59;
  Map<String, dynamic>? _remoteAlert;

  Timer? _foregroundScanTimer;

  List<OrderEntity> get orders => _orders;
  List<OrderEntity> get archivedOrders => _archivedOrders;
  Set<String> get archivedOrderIds => _archivedOrderIds;

  // Listas especializadas separadas para Compras y Ventas
  List<OrderEntity> get buyOrders => _orders.where((o) => o.isBuy).toList();
  List<OrderEntity> get sellOrders => _orders.where((o) => o.isSell).toList();

  Map<String, double> get livePrices => _livePrices;
  Map<String, double> get distancePctMap => _distancePctMap;
  bool get isScanning => _isScanning;
  String get lastScanTime => _lastScanTime;
  String get lastCloudSyncTime => 'GitHub Master';
  String get statusMessage => _statusMessage;
  double get liquidCashUsdt => _liquidCashUsdt;
  Map<String, dynamic>? get remoteAlert => _remoteAlert;

  void setLiquidCash(double value) {
    _liquidCashUsdt = value;
    NativeAlarmService.setDoubleSetting('liquid_cash_usdt', value);
    notifyListeners();
  }

  Future<void> addOrder(OrderEntity order) async {
    _orders.removeWhere((o) => o.id == order.id);
    _orders.insert(0, order);
    await _persistLiveOrders();
    notifyListeners();
    await scanBinancePrices();
  }

  Future<void> removeOrder(String orderId) async {
    final order = _orders.firstWhere((o) => o.id == orderId, orElse: () => _orders.first);
    if (order.id == orderId && order.isBuy) {
      // Reintegrar capital de compra cancelada al saldo USDT disponible
      _liquidCashUsdt += order.expectedReturnUsdt;
      await NativeAlarmService.setDoubleSetting('liquid_cash_usdt', _liquidCashUsdt);
    }
    _orders.removeWhere((o) => o.id == orderId);
    await _persistLiveOrders();
    notifyListeners();
  }

  Future<void> _persistLiveOrders() async {
    try {
      final jsonStr = jsonEncode(_orders.map((o) => o.toJson()).toList());
      await NativeAlarmService.saveCachedOrders(jsonStr);
    } catch (_) {}
  }

  double get totalExpectedReturn => _orders.fold(0.0, (sum, o) => sum + o.expectedReturnUsdt);
  double get totalProjectedProfit => _orders.fold(0.0, (sum, o) => sum + o.projectedProfitUsdt);
  double get totalAccumulatedProfit =>
      _archivedOrders.fold(0.0, (sum, o) => sum + o.projectedProfitUsdt) +
      _orders.fold(0.0, (sum, o) => sum + o.projectedProfitUsdt);

  String _calculateElapsedTime(String datePlacedStr) {
    try {
      final cleanStr = datePlacedStr.replaceAll(' BOT', '').trim();
      DateTime placed;
      if (cleanStr.contains('T')) {
        placed = DateTime.parse(cleanStr);
      } else {
        placed = DateTime.parse(cleanStr.replaceAll('/', '-'));
      }
      final now = DateTime.now().toUtc().subtract(const Duration(hours: 4));
      final diff = now.difference(placed);
      if (diff.isNegative) return '0d 0h 1m';
      final days = diff.inDays;
      final hours = diff.inHours % 24;
      final minutes = diff.inMinutes % 60;
      return '${days}d ${hours}h ${minutes}m';
    } catch (_) {
      return '2d 4h 15m';
    }
  }

  String _formatShortDate(String dateStr) {
    try {
      final cleanStr = dateStr.replaceAll(' BOT', '').trim();
      DateTime dt;
      if (cleanStr.contains('T')) {
        dt = DateTime.parse(cleanStr);
      } else {
        dt = DateTime.parse(cleanStr.replaceAll('/', '-'));
      }
      return DateFormat('dd/MM/yy • HH:mm').format(dt);
    } catch (_) {
      return dateStr;
    }
  }
  double get totalArchivedProfit => _archivedOrders.fold(0.0, (sum, o) => sum + o.projectedProfitUsdt);

  /// Inicializar el Centinela Autónomo
  Future<void> init() async {
    // 0. Cargar saldo líquido persistido si existe
    final savedCash = await NativeAlarmService.getDoubleSetting('liquid_cash_usdt', defaultValue: -1.0);
    if (savedCash > 0) {
      _liquidCashUsdt = savedCash;
    }

    // 1. Cargar historial de órdenes archivadas persistidas
    await _loadArchivedOrders();

    // 2. Cargar órdenes activas en caché local nativo
    await _loadLocalCachedOrders();

    // 3. Ejecutar el primer escaneo de precios de Binance
    await scanBinancePrices();

    // 4. Iniciar Radar Cuantitativo Smart Engine 2.2 (S+ 1H cada 3 minutos)
    SmcSPlusScanner.instance.init();

    // 5. Iniciar temporizador de escaneo en primer plano cada 25 segundos (100% automático directo a Binance)
    _foregroundScanTimer?.cancel();
    _foregroundScanTimer = Timer.periodic(const Duration(seconds: 25), (_) async {
      await scanBinancePrices();
    });

    // 6. Activar Centinela Nativo de Fondo en Android (Despierta con AlarmClock en Doze Mode)
    await NativeAlarmService.startNativeBackgroundScan();
  }

  /// Cargar órdenes archivadas de persistencia nativa
  Future<void> _loadArchivedOrders() async {
    try {
      final archivedJson = await NativeAlarmService.getArchivedOrders();
      if (archivedJson != null && archivedJson.isNotEmpty) {
        final List<dynamic> list = jsonDecode(archivedJson);
        if (list.isNotEmpty) {
          _archivedOrders = list.map((item) => OrderEntity.fromJson(item as Map<String, dynamic>)).toList();
          _archivedOrderIds.clear();
          for (final o in _archivedOrders) {
            _archivedOrderIds.add(o.id);
          }
          // Asegurar que órdenes históricas estén siempre archivadas
          if (!_archivedOrderIds.contains('binance-inj-buy-executed-8114')) {
            final injBuy = OrderEntity.defaultArchivedOrders.firstWhere(
              (o) => o.id == 'binance-inj-buy-executed-8114',
              orElse: () => OrderEntity.defaultArchivedOrders.first,
            );
            _archivedOrders.insert(0, injBuy);
            _archivedOrderIds.add('binance-inj-buy-executed-8114');
          }
          if (!_archivedOrderIds.contains('binance-tia-buy-05917')) {
            final tiaBuy = OrderEntity.defaultArchivedOrders.firstWhere(
              (o) => o.id == 'binance-tia-buy-05917',
              orElse: () => OrderEntity.defaultArchivedOrders.first,
            );
            _archivedOrders.insert(0, tiaBuy);
            _archivedOrderIds.add('binance-tia-buy-05917');
          }
          if (!_archivedOrderIds.contains('binance-op-sell-tp1-01320')) {
            final opTp1 = OrderEntity.defaultArchivedOrders.firstWhere(
              (o) => o.id == 'binance-op-sell-tp1-01320',
              orElse: () => OrderEntity.defaultArchivedOrders.first,
            );
            _archivedOrders.insert(0, opTp1);
            _archivedOrderIds.add('binance-op-sell-tp1-01320');
          }
          if (!_archivedOrderIds.contains('binance-sui-sell-10540')) {
            final suiTp1 = OrderEntity.defaultArchivedOrders.firstWhere(
              (o) => o.id == 'binance-sui-sell-10540',
              orElse: () => OrderEntity.defaultArchivedOrders[1],
            );
            _archivedOrders.insert(0, suiTp1);
            _archivedOrderIds.add('binance-sui-sell-10540');
          }
          if (!_archivedOrderIds.contains('binance-ondo-sell-04620')) {
            final ondo = OrderEntity.defaultArchivedOrders.firstWhere(
              (o) => o.id == 'binance-ondo-sell-04620',
              orElse: () => OrderEntity.defaultArchivedOrders.first,
            );
            _archivedOrders.insert(0, ondo);
            _archivedOrderIds.add('binance-ondo-sell-04620');
          }
          notifyListeners();
          return;
        }
      }
      // Sembrar por defecto
      _archivedOrders = [...OrderEntity.defaultArchivedOrders];
      _archivedOrderIds.clear();
      for (final o in _archivedOrders) {
        _archivedOrderIds.add(o.id);
      }
      await _persistArchivedOrders();
    } catch (e) {
      NativeAlarmService.logEvent('⚠️ Error cargando órdenes archivadas: $e');
    }
  }

  /// Persistir lista de archivadas
  Future<void> _persistArchivedOrders() async {
    try {
      final jsonStr = jsonEncode(_archivedOrders.map((o) => o.toJson()).toList());
      await NativeAlarmService.saveArchivedOrders(jsonStr);
    } catch (_) {}
  }

  /// Cargar órdenes guardadas localmente (filtrando archivadas y eliminando órdenes obsoletas)
  Future<void> _loadLocalCachedOrders() async {
    try {
      final cachedJson = await NativeAlarmService.getCachedOrders();
      if (cachedJson != null && cachedJson.isNotEmpty) {
        final List<dynamic> list = jsonDecode(cachedJson);
        if (list.isNotEmpty) {
          final loaded = list.map((item) => OrderEntity.fromJson(item as Map<String, dynamic>)).toList();
          // Descartar órdenes archivadas (incluyendo INJ cobrado, TIA Compra, OP TP1, SUI TP1, ONDO)
          _orders = loaded.where((o) => !_archivedOrderIds.contains(o.id) &&
              o.id != 'binance-inj-sell-tp1-8192' &&
              o.id != 'binance-inj-sell-tp2-8320' &&
              o.id != 'binance-tia-buy-05917' &&
              o.id != 'binance-ondo-sell-04620' &&
              o.id != 'binance-op-buy-01281' &&
              o.id != 'binance-op-sell-tp1-01320' &&
              o.id != 'binance-sui-sell-10540').toList();
          // Asegurar que todas las órdenes vivas oficiales de Binance Spot estén presentes
          for (final liveOrder in OrderEntity.currentLiveOrders) {
            if (!_orders.any((o) => o.id == liveOrder.id) && !_archivedOrderIds.contains(liveOrder.id)) {
              _orders.add(liveOrder);
            }
          }
          if (_orders.isNotEmpty) {
            await _persistLiveOrders();
            notifyListeners();
            return;
          }
        }
      }
      // Sembrar por defecto con las 4 órdenes vivas oficiales de Binance Spot
      _orders = [...OrderEntity.currentLiveOrders];
      await _persistLiveOrders();
      notifyListeners();
    } catch (e) {
      NativeAlarmService.logEvent('⚠️ Error cargando órdenes en caché: $e');
    }
  }

  bool _isSyncingCloud = false;

  bool get isSyncingCloud => _isSyncingCloud;

  /// Sincronizar estado oficial directamente desde GitHub Raw (100% independiente de Vercel)
  Future<void> syncOrdersFromCloud() async {
    if (_isSyncingCloud) return;
    _isSyncingCloud = true;
    notifyListeners();

    try {
      const syncUrl = 'https://raw.githubusercontent.com/crucies/micripto_sentinel/master/assets/data/sentinel_sync.json';
      final res = await http.get(
        Uri.parse(syncUrl),
        headers: {'User-Agent': 'Mozilla/5.0 MiCriptoSentinel/2.19'},
      ).timeout(const Duration(seconds: 8));

      if (res.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(res.body);
        if (data.containsKey('liquidCashUsdt')) {
          _liquidCashUsdt = (data['liquidCashUsdt'] as num).toDouble();
          await NativeAlarmService.setDoubleSetting('liquid_cash_usdt', _liquidCashUsdt);
        }

        if (data.containsKey('orders') && data['orders'] is List) {
          final List<dynamic> list = data['orders'];
          _orders = list.map((item) => OrderEntity.fromJson(item as Map<String, dynamic>)).toList();
          await _persistLiveOrders();
        }

        if (data.containsKey('remoteAlert') && data['remoteAlert'] is Map) {
          _remoteAlert = Map<String, dynamic>.from(data['remoteAlert'] as Map);
        }

        _statusMessage = '🟢 SINCRONIZADO: ${_orders.length} órdenes activas • \$${_liquidCashUsdt.toStringAsFixed(2)} USDT';
        NativeAlarmService.logEvent('✅ Sincronización Nube exitosa (${_orders.length} órdenes, \$${_liquidCashUsdt.toStringAsFixed(2)} USDT)');
        await scanBinancePrices();
      } else {
        _statusMessage = '⚠️ Error HTTP ${res.statusCode} en Sinc Nube';
        NativeAlarmService.logEvent('⚠️ Sincronización fallida: HTTP ${res.statusCode}');
      }
    } catch (e) {
      _statusMessage = '⚠️ Error en Sinc Nube: $e';
      NativeAlarmService.logEvent('⚠️ Excepción en Sinc Nube: $e');
    } finally {
      _isSyncingCloud = false;
      notifyListeners();
    }
  }

  /// Archivar una orden ejecutada o completada
  Future<void> archiveOrder(OrderEntity order, {String reason = 'Ejecutada en Binance Spot'}) async {
    final now = DateTime.now().toUtc().subtract(const Duration(hours: 4));
    final dateStr = '${DateFormat('yyyy-MM-dd HH:mm:ss').format(now)} BOT';

    _archivedOrderIds.add(order.id);

    final archivedOrder = order.copyWith(
      status: 'EJECUTADA / ARCHIVADA',
      archivedAt: dateStr,
      archivedReason: reason,
    );

    // Agregar al historial si no existe
    _archivedOrders.removeWhere((o) => o.id == order.id);
    _archivedOrders.insert(0, archivedOrder);

    // Remover del listado del dashboard
    _orders.removeWhere((o) => o.id == order.id);

    // ACTUALIZACIÓN AUTOMÁTICA DE LIQUIDEZ SPOT
    if (order.isSell) {
      // Venta ejecutada: el capital retornado ingresa a USDT disponible
      _liquidCashUsdt += order.expectedReturnUsdt;
      await NativeAlarmService.setDoubleSetting('liquid_cash_usdt', _liquidCashUsdt);
    }

    // Persistir ambas listas
    await _persistArchivedOrders();
    final jsonStr = jsonEncode(_orders.map((o) => o.toJson()).toList());
    await NativeAlarmService.saveCachedOrders(jsonStr);

    NativeAlarmService.logEvent('📦 Orden ${order.displaySymbol} archivada. Saldo USDT libre: \$${_liquidCashUsdt.toStringAsFixed(2)} ($reason)');
    notifyListeners();
  }

  /// Desarchivar una orden y regresarla al dashboard
  Future<void> unarchiveOrder(String orderId) async {
    _archivedOrderIds.remove(orderId);
    final idx = _archivedOrders.indexWhere((o) => o.id == orderId);
    if (idx != -1) {
      final restored = _archivedOrders.removeAt(idx);
      if (restored.isSell) {
        // Si se revierte una venta ejecutada, se resta el USDT acreditado
        _liquidCashUsdt = (_liquidCashUsdt - restored.expectedReturnUsdt).clamp(0.0, 999999.0);
        await NativeAlarmService.setDoubleSetting('liquid_cash_usdt', _liquidCashUsdt);
      }
      _orders.add(restored.copyWith(
        status: '0% Filled (Esperando)',
        archivedAt: null,
        archivedReason: null,
      ));
    }

    await _persistArchivedOrders();
    final jsonStr = jsonEncode(_orders.map((o) => o.toJson()).toList());
    await NativeAlarmService.saveCachedOrders(jsonStr);

    NativeAlarmService.logEvent('🔄 Orden $orderId restaurada al dashboard activo');
    notifyListeners();
  }

  /// Eliminar permanentemente una orden del historial
  Future<void> deleteArchivedOrder(String orderId) async {
    _archivedOrders.removeWhere((o) => o.id == orderId);
    await _persistArchivedOrders();
    notifyListeners();
  }

  /// Escanear precios en vivo de Binance y disparar alarma militar si se cumple el precio
  Future<void> scanBinancePrices() async {
    if (_isScanning) return;
    _isScanning = true;
    notifyListeners();

    try {
      final res = await http.get(
        Uri.parse(binanceTickerUrl),
        headers: {'User-Agent': 'Mozilla/5.0 MiCriptoSentinel/1.9'},
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

          final isSell = order.isSell;
          // Para SELL: distPct mide cuánto falta subir para TP ((target - cur) / cur) * 100
          // Para BUY: distPct mide cuánto falta caer para tocar límite ((cur - target) / cur) * 100
          final distPct = isSell
              ? ((order.targetPrice - curPrice) / curPrice) * 100.0
              : ((curPrice - order.targetPrice) / curPrice) * 100.0;
          _distancePctMap[order.id] = distPct;

          // Comprobar si se alcanzó la meta (compra o venta)
          final isHit = isSell 
              ? (curPrice >= order.targetPrice) 
              : (curPrice > 0.0 && curPrice <= order.targetPrice);

          if (isHit && !_triggeredOrderIds.contains(order.id)) {
            _triggeredOrderIds.add(order.id);
            final logMsg = isSell
                ? '🎯 ¡TAKE PROFIT ALCANZADO! ${order.displaySymbol} tocó \$${curPrice.toStringAsFixed(4)} (Meta TP: \$${order.targetPrice.toStringAsFixed(4)})'
                : '⚡ ¡COMPRA LIMIT EJECUTADA EN SUELO! ${order.displaySymbol} tocó \$${curPrice.toStringAsFixed(4)} (Límite: \$${order.targetPrice.toStringAsFixed(4)})';
            NativeAlarmService.logEvent(logMsg);

            // Calcular niveles de salida inmediatos si se ejecutó una compra
            final tp1 = order.targetPrice * 1.030;
            final tp2 = order.targetPrice * 1.055;
            final sl = order.targetPrice * 0.972;

            final buyPriceStr = '\$${order.entryPrice.toStringAsFixed(4)}';
            final buyDateStr = _formatShortDate(order.datePlaced);
            final sellDateStr = DateFormat('dd/MM/yy • HH:mm').format(now);
            final elapsedTimeStr = _calculateElapsedTime(order.datePlaced);

            // Disparar Alarma Militar Inmediata (Audio 100%, WakeLock y Formulario Táctico)
            await NativeAlarmService.triggerImmediateAlarm(
              eventType: isSell ? 'TP_HIT' : 'BUY_FILLED',
              symbol: order.displaySymbol,
              price: '\$${curPrice.toStringAsFixed(4)}',
              amount: isSell
                  ? '${order.amountCoins} ${order.displaySymbol} (\$${order.expectedReturnUsdt.toStringAsFixed(2)} USDT)'
                  : 'PRECIO COMPRA: \$${order.targetPrice.toStringAsFixed(4)}',
              targetPrice: isSell
                  ? '\$${order.targetPrice.toStringAsFixed(4)}'
                  : '\$${tp1.toStringAsFixed(4)}',
              projectedProfit: isSell
                  ? '+\$${order.projectedProfitUsdt.toStringAsFixed(4)} USDT'
                  : 'TP1 (+3%): \$${tp1.toStringAsFixed(4)} | TP2 (+5.5%): \$${tp2.toStringAsFixed(4)}',
              totalProfit: '+\$${totalAccumulatedProfit.toStringAsFixed(4)} USDT',
              liquidCash: '\$${_liquidCashUsdt.toStringAsFixed(4)} USDT',
              tp1Price: '\$${tp1.toStringAsFixed(4)}',
              tp2Price: '\$${tp2.toStringAsFixed(4)}',
              slPrice: '\$${sl.toStringAsFixed(4)}',
              limitBuyPrice: '\$${order.targetPrice.toStringAsFixed(4)}',
              buyPrice: buyPriceStr,
              buyDate: buyDateStr,
              sellDate: sellDateStr,
              elapsedTime: elapsedTimeStr,
              appVersion: 'V 0.2.12',
              totalCoins: order.amountCoins > 0 ? order.amountCoins.toStringAsFixed(4) : '',
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
    super.dispose();
  }
}
