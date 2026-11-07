import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/native_alarm_service.dart';
import '../../../../core/services/sentinel_auto_scanner.dart';
import '../../../orders/domain/order_entity.dart';
import '../../../orders/presentation/widgets/order_detail_modal.dart';
import '../../../orders/presentation/widgets/archived_orders_modal.dart';
import '../widgets/macro_regime_widget.dart';
import '../../../../core/services/macro_regime_service.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late String _currentTimeStr;
  Timer? _clockTimer;
  int _countdown = 0;
  Timer? _countdownTimer;
  final bool _showTestAlarmSection = false; // Oculto en UI manteniendo todo el código táctico intacto
  bool _isIgnoringBattery = true;
  String _soundMode = 'ALWAYS';
  int _ordersFilterTab = 0; // 0: TODAS, 1: COMPRAS, 2: VENTAS

  @override
  void initState() {
    super.initState();
    _updateTime();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) => _updateTime());
    _checkBatteryOptimization();

    // Conectar el Centinela Autónomo (Descarga Nube + Auto-scan Binance cada 25s)
    SentinelAutoScanner.instance.addListener(_onScannerUpdate);
    SentinelAutoScanner.instance.init();
    MacroRegimeService.instance.init();
  }

  Future<void> _checkBatteryOptimization() async {
    final ignoring = await NativeAlarmService.isIgnoringBatteryOptimizations();
    final mode = await NativeAlarmService.getSoundMode();
    if (mounted) {
      setState(() {
        _isIgnoringBattery = ignoring;
        _soundMode = mode;
      });
    }
  }

  Widget _buildSectionDivider({
    required String title,
    required String subtitle,
    required Color color,
    Color textColor = AppColors.ink,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: AppColors.brutalistCell(
        color: color,
        borderWidth: 2.0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontFamily: 'monospace',
              fontWeight: FontWeight.w900,
              fontSize: 11,
              color: textColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: textColor.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptySectionMessage(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 14),
      decoration: AppColors.brutalistCell(
        color: AppColors.surfaceLight,
        borderWidth: 1.5,
      ),
      child: Center(
        child: Text(
          message,
          style: const TextStyle(
            fontFamily: 'monospace',
            fontWeight: FontWeight.bold,
            fontSize: 11,
            color: AppColors.textMuted,
          ),
        ),
      ),
    );
  }

  Widget _buildTotalSilenceBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: AppColors.brutalistBox(
        color: const Color(0xFFFFCDD2),
        borderWidth: 2.5,
        shadowOffset: 4.0,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text('🛑', style: TextStyle(fontSize: 20)),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'MODO SILENCIO TOTAL ACTIVO',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                    color: Color(0xFFB71C1C),
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Ninguna alarma sonará ni despertará la pantalla. Activado para reuniones, descanso o sin fondos. Puedes reactivarlo en la pestaña Ajustes.',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                    color: Color(0xFF7F0000),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBatteryWarningBanner() {
    return GestureDetector(
      onTap: () async {
        await NativeAlarmService.requestIgnoreBatteryOptimizations();
        await Future.delayed(const Duration(seconds: 1));
        _checkBatteryOptimization();
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: AppColors.brutalistBox(
          color: AppColors.orange,
          borderWidth: 2.5,
          shadowOffset: 4.0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.battery_alert, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '⚠️ VIGILANCIA EN BLOQUEO: BATERÍA OPTIMIZADA',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w900,
                      fontSize: 11,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Android Doze Mode puede suspender la conexión a Binance con la pantalla apagada. Toca aquí para conceder "Sin Restricciones" y permitir que la alarma suene 24/7.',
              style: TextStyle(
                fontSize: 10,
                color: Colors.white,
                fontWeight: FontWeight.bold,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: AppColors.ink, width: 1.5),
              ),
              child: const Text(
                '⚡ TOCAR PARA DESACTIVAR OPTIMIZACIÓN DE BATERÍA ➔',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: AppColors.ink,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onScannerUpdate() {
    if (mounted) setState(() {});
  }

  void _updateTime() {
    final now = DateTime.now().toUtc().subtract(const Duration(hours: 4)); // UTC-4 Bolivia
    if (mounted) {
      setState(() {
        _currentTimeStr = DateFormat('HH:mm:ss').format(now);
      });
    }
  }

  @override
  void dispose() {
    SentinelAutoScanner.instance.removeListener(_onScannerUpdate);
    _clockTimer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  String _formatOrderElapsedTime(String datePlacedStr) {
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
      if (diff.isNegative) return 'Reciente';
      final days = diff.inDays;
      final hours = diff.inHours % 24;
      final mins = diff.inMinutes % 60;
      if (days > 0) return '${days}d ${hours}h ${mins}m';
      if (hours > 0) return '${hours}h ${mins}m';
      return '${mins}m';
    } catch (_) {
      return 'Activa';
    }
  }

  void _showRegisterMovementModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const _RegisterMovementSheet(),
    );
  }

  void _showEditCashDialog() {
    final controller = TextEditingController(
      text: SentinelAutoScanner.instance.liquidCashUsdt.toStringAsFixed(2),
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.background,
        shape: const RoundedRectangleBorder(
          side: BorderSide(color: AppColors.ink, width: 3.0),
          borderRadius: BorderRadius.zero,
        ),
        title: const Text(
          '💵 SALDO LIBRE SPOT (USDT)',
          style: TextStyle(
            fontFamily: 'monospace',
            fontWeight: FontWeight.w900,
            fontSize: 13,
            color: AppColors.ink,
          ),
        ),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(
            fontFamily: 'monospace',
            fontWeight: FontWeight.w900,
            fontSize: 18,
            color: AppColors.ink,
          ),
          decoration: const InputDecoration(
            prefixText: '\$ ',
            suffixText: 'USDT',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.zero,
              borderSide: BorderSide(color: AppColors.ink, width: 2.0),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'CANCELAR',
              style: TextStyle(
                fontFamily: 'monospace',
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.gold,
              foregroundColor: AppColors.ink,
              shape: const RoundedRectangleBorder(
                side: BorderSide(color: AppColors.ink, width: 2.0),
                borderRadius: BorderRadius.zero,
              ),
            ),
            onPressed: () {
              final val = double.tryParse(controller.text.replaceAll(',', '.'));
              if (val != null && val >= 0) {
                SentinelAutoScanner.instance.setLiquidCash(val);
              }
              Navigator.pop(ctx);
            },
            child: const Text(
              'GUARDAR',
              style: TextStyle(
                fontFamily: 'monospace',
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _triggerImmediateAlarm({
    required String eventType,
    required String symbol,
    required String price,
    required String amount,
    required String targetPrice,
    required String projectedProfit,
    String totalProfit = r'+$84.33 USDT',
    String liquidCash = r'$378.67 USDT',
    String tp1Price = '',
    String tp2Price = '',
    String slPrice = '',
    String limitBuyPrice = '',
    String buyPrice = '',
    String buyDate = '',
    String sellDate = '',
    String elapsedTime = '',
    String appVersion = 'V 0.2.17',
    String totalCoins = '',
  }) {
    NativeAlarmService.triggerImmediateAlarm(
      eventType: eventType,
      symbol: symbol,
      price: price,
      amount: amount,
      targetPrice: targetPrice,
      projectedProfit: projectedProfit,
      totalProfit: totalProfit,
      liquidCash: liquidCash,
      tp1Price: tp1Price,
      tp2Price: tp2Price,
      slPrice: slPrice,
      limitBuyPrice: limitBuyPrice,
      buyPrice: buyPrice,
      buyDate: buyDate,
      sellDate: sellDate,
      elapsedTime: elapsedTime,
      appVersion: appVersion,
      totalCoins: totalCoins,
    );
  }

  void _startCountdownAndAlarm({
    required String eventType,
    required String symbol,
    required String price,
    required String amount,
    required String targetPrice,
    required String projectedProfit,
    String totalProfit = r'+$84.33 USDT',
    String liquidCash = r'$378.67 USDT',
    String tp1Price = '',
    String tp2Price = '',
    String slPrice = '',
    String limitBuyPrice = '',
    String buyPrice = '',
    String buyDate = '',
    String sellDate = '',
    String elapsedTime = '',
    String appVersion = 'V 0.2.17',
    String totalCoins = '',
  }) {
    setState(() {
      _countdown = 5;
    });

    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 1) {
        setState(() {
          _countdown--;
        });
      } else {
        timer.cancel();
        setState(() {
          _countdown = 0;
        });
      }
    });

    NativeAlarmService.scheduleTestAlarm(
      delaySeconds: 5,
      eventType: eventType,
      symbol: symbol,
      price: price,
      amount: amount,
      targetPrice: targetPrice,
      projectedProfit: projectedProfit,
      totalProfit: totalProfit,
      liquidCash: liquidCash,
      tp1Price: tp1Price,
      tp2Price: tp2Price,
      slPrice: slPrice,
      limitBuyPrice: limitBuyPrice,
      buyPrice: buyPrice,
      buyDate: buyDate,
      sellDate: sellDate,
      elapsedTime: elapsedTime,
      appVersion: appVersion,
      totalCoins: totalCoins,
    );

    NativeAlarmService.checkOverlayPermission().then((hasOverlay) {
      if (!hasOverlay && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.ink,
            duration: const Duration(seconds: 8),
            content: const Text(
              '⚠️ Para que la alarma despierte la pantalla bloqueada sin pedir clave, activa "Aparecer encima".',
              style: TextStyle(
                fontFamily: 'monospace',
                fontWeight: FontWeight.bold,
                fontSize: 11,
                color: AppColors.gold,
              ),
            ),
            action: SnackBarAction(
              label: 'ACTIVAR',
              textColor: AppColors.orange,
              onPressed: () => NativeAlarmService.requestOverlayPermission(),
            ),
          ),
        );
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.ink,
        duration: const Duration(seconds: 4),
        content: Row(
          children: const [
            Icon(Icons.lock_clock, color: AppColors.gold, size: 20),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                '¡Alarma programada en 5s! Bloquea tu teléfono ahora para ver el despertar físico.',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.background,
            border: Border(
              bottom: BorderSide(color: AppColors.ink, width: 3.0),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: AppColors.brutalistBox(
                          color: AppColors.orange,
                          borderWidth: 2.5,
                          shadowOffset: 3.0,
                        ),
                        child: const Text(
                          '\$ SENTINEL',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.w900,
                            fontSize: 13,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
                        decoration: AppColors.brutalistCell(
                          color: AppColors.gold,
                          borderWidth: 2.0,
                        ),
                        child: const Text(
                          'V.0.2.17',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.w900,
                            fontSize: 10,
                            color: AppColors.ink,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: AppColors.brutalistBox(
                      color: AppColors.surface,
                      borderWidth: 2.0,
                      shadowOffset: 3.0,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.orange,
                            shape: BoxShape.rectangle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '$_currentTimeStr BOT',
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.w900,
                            fontSize: 11,
                            color: AppColors.ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(22, 20, 22, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_soundMode == 'TOTAL_SILENCE') ...[
              _buildTotalSilenceBanner(),
              const SizedBox(height: 16),
            ],
            if (!_isIgnoringBattery) ...[
              _buildBatteryWarningBanner(),
              const SizedBox(height: 16),
            ],
            // 1. Hero Card Brutalista: Resumen de Bóveda y Liquidez
            _buildVaultHeroCard(),

            const SizedBox(height: 16),

            // Semáforo de Régimen Macro de Bitcoin (4H)
            const MacroRegimeWidget(),

            const SizedBox(height: 24),

            // 2. Cabecera de Sección: Órdenes Vivas en Binance Spot
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                      decoration: AppColors.brutalistBox(
                        color: AppColors.ink,
                        borderWidth: 2.0,
                        shadowOffset: 2.5,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.bolt, color: AppColors.gold, size: 15),
                          SizedBox(width: 5),
                          Text(
                            'ÓRDENES BINANCE',
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.w900,
                              fontSize: 11,
                              color: AppColors.gold,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
                      decoration: AppColors.brutalistBox(
                        color: AppColors.gold,
                        borderWidth: 1.5,
                        shadowOffset: 2.0,
                      ),
                      child: Text(
                        '${SentinelAutoScanner.instance.orders.length} ACTIVAS',
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 10,
                          color: AppColors.ink,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () => ArchivedOrdersModal.show(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    decoration: AppColors.brutalistBox(
                      color: AppColors.surface,
                      borderWidth: 1.8,
                      shadowOffset: 2.0,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('📦 ', style: TextStyle(fontSize: 10)),
                        Text(
                          'HISTORIAL (${SentinelAutoScanner.instance.archivedOrders.length})',
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 9.5,
                            color: AppColors.ink,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Banner Táctico: Centinela Autónomo (Binance Scan cada 25s + Nube)
            _buildAutoScanBanner(),

            const SizedBox(height: 14),

            // Botón Táctico: [+ REGISTRAR MOVIMIENTO EN BINANCE]
            GestureDetector(
              onTap: () => _showRegisterMovementModal(context),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                decoration: AppColors.brutalistBox(
                  color: AppColors.gold,
                  borderWidth: 2.5,
                  shadowOffset: 4.0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.add_circle_outline, size: 16, color: AppColors.ink),
                    SizedBox(width: 8),
                    Text(
                      '➕ REGISTRAR MOVIMIENTO SPOT (BINANCE)',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w900,
                        fontSize: 11.5,
                        color: AppColors.ink,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 14),

            // Segmentador Brutalista: [TODAS] | [🟢 COMPRAS] | [🎯 VENTAS]
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _ordersFilterTab = 0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: _ordersFilterTab == 0
                          ? AppColors.brutalistBox(color: AppColors.gold, borderWidth: 2.0, shadowOffset: 2.5)
                          : AppColors.brutalistCell(color: AppColors.surface, borderWidth: 1.5),
                      child: Center(
                        child: Text(
                          'TODAS (${SentinelAutoScanner.instance.orders.length})',
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.w900,
                            fontSize: 10,
                            color: AppColors.ink,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _ordersFilterTab = 1),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: _ordersFilterTab == 1
                          ? AppColors.brutalistBox(color: const Color(0xFF00E5FF), borderWidth: 2.0, shadowOffset: 2.5)
                          : AppColors.brutalistCell(color: AppColors.surface, borderWidth: 1.5),
                      child: Center(
                        child: Text(
                          '🟢 COMPRAS (${SentinelAutoScanner.instance.buyOrders.length})',
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.w900,
                            fontSize: 10,
                            color: AppColors.ink,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _ordersFilterTab = 2),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: _ordersFilterTab == 2
                          ? AppColors.brutalistBox(color: AppColors.orange, borderWidth: 2.0, shadowOffset: 2.5)
                          : AppColors.brutalistCell(color: AppColors.surface, borderWidth: 1.5),
                      child: Center(
                        child: Text(
                          '🎯 VENTAS (${SentinelAutoScanner.instance.sellOrders.length})',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.w900,
                            fontSize: 10,
                            color: _ordersFilterTab == 2 ? Colors.white : AppColors.ink,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // 3. Lista Dinámica de Órdenes Separadas en Bloques Exclusivos
            if (_ordersFilterTab == 0) ...[
              if (SentinelAutoScanner.instance.buyOrders.isNotEmpty) ...[
                _buildSectionDivider(
                  title: '🟢 ÓRDENES DE COMPRA LÍMITE (${SentinelAutoScanner.instance.buyOrders.length})',
                  subtitle: 'Esperando retroceso al precio límite de entrada en Binance Spot',
                  color: const Color(0xFF00E5FF),
                ),
                const SizedBox(height: 10),
                ...SentinelAutoScanner.instance.buyOrders.map((order) => _buildOrderCard(order)),
                const SizedBox(height: 10),
              ],
              if (SentinelAutoScanner.instance.sellOrders.isNotEmpty) ...[
                _buildSectionDivider(
                  title: '🎯 ÓRDENES DE VENTA / TAKE PROFIT (${SentinelAutoScanner.instance.sellOrders.length})',
                  subtitle: 'Monedas en cartera esperando subida a objetivo Take Profit',
                  color: AppColors.orange,
                  textColor: Colors.white,
                ),
                const SizedBox(height: 10),
                ...SentinelAutoScanner.instance.sellOrders.map((order) => _buildOrderCard(order)),
              ],
            ] else if (_ordersFilterTab == 1) ...[
              _buildSectionDivider(
                title: '🟢 ÓRDENES DE COMPRA LÍMITE (${SentinelAutoScanner.instance.buyOrders.length})',
                subtitle: 'Esperando retroceso al precio límite de entrada en Binance Spot',
                color: const Color(0xFF00E5FF),
              ),
              const SizedBox(height: 10),
              if (SentinelAutoScanner.instance.buyOrders.isEmpty)
                _buildEmptySectionMessage('No hay órdenes de compra activas en Binance Spot')
              else
                ...SentinelAutoScanner.instance.buyOrders.map((order) => _buildOrderCard(order)),
            ] else ...[
              _buildSectionDivider(
                title: '🎯 ÓRDENES DE VENTA / TAKE PROFIT (${SentinelAutoScanner.instance.sellOrders.length})',
                subtitle: 'Monedas en cartera esperando subida a objetivo Take Profit',
                color: AppColors.orange,
                textColor: Colors.white,
              ),
              const SizedBox(height: 10),
              if (SentinelAutoScanner.instance.sellOrders.isEmpty)
                _buildEmptySectionMessage('No hay órdenes de venta activas en Binance Spot')
              else
                ...SentinelAutoScanner.instance.sellOrders.map((order) => _buildOrderCard(order)),
            ],

            const SizedBox(height: 14),

            // 4. Tarjeta de Enlace Remoto Firebase FCM
            _buildFcmStatusCard(),

            // 5. Sección: Simulador y Probador de Alarma de Bloqueo (Oculto por bandera _showTestAlarmSection)
            if (_showTestAlarmSection) ...[
              const SizedBox(height: 24),
              _buildTestAlarmSection(),
            ],

            const SizedBox(height: 28),

            // 6. Footer Institucional Neo-Brutalista según Protocolo
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
              decoration: AppColors.brutalistCell(
                color: AppColors.surfaceLight,
                borderWidth: 2.0,
              ),
              child: Column(
                children: const [
                  Text(
                    'ALIANZA RICHARD & KAI — PROTOCOLO ANTIGRAVITY',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w900,
                      fontSize: 10,
                      color: AppColors.ink,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'MiCripto Sentinel V.0.2.17 • Terminal Centinela & Radar S+',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVaultHeroCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: AppColors.brutalistBox(
        color: AppColors.gold,
        borderWidth: 3.0,
        shadowOffset: 6.0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cinta Superior Negra + Badge EN VIVO Naranja
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  color: AppColors.ink,
                  child: const Text(
                    '💰 BÓVEDA DEL ANFITRIÓN (BINANCE)',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w900,
                      fontSize: 11,
                      color: AppColors.gold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: AppColors.brutalistCell(
                  color: AppColors.orange,
                  borderWidth: 2.0,
                ),
                child: const Text(
                  'EN VIVO',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Grilla de 2 Celdas Blancas: Saldo Libre Spot (Editable al tocar) + En Órdenes Vivas
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: _showEditCashDialog,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: AppColors.brutalistCell(
                      color: AppColors.surface,
                      borderWidth: 2.5,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: const [
                            Text(
                              'SALDO LIBRE SPOT',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                color: AppColors.textMuted,
                                fontFamily: 'monospace',
                              ),
                            ),
                            Icon(Icons.edit, size: 11, color: AppColors.orange),
                          ],
                        ),
                        const SizedBox(height: 4),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '\$${SentinelAutoScanner.instance.liquidCashUsdt.toStringAsFixed(2)}',
                            maxLines: 1,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: AppColors.ink,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'USDT Líquido (Toca p/ editar)',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: AppColors.brutalistCell(
                    color: AppColors.surface,
                    borderWidth: 2.5,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'CAPITAL EN JUEGO',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textMuted,
                          fontFamily: 'monospace',
                        ),
                      ),
                      const SizedBox(height: 4),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '\$${SentinelAutoScanner.instance.totalExpectedReturn.toStringAsFixed(2)}',
                          maxLines: 1,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: AppColors.orange,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Retorno Total al TP',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Franja Inferior Naranja Fuego: Meta de Ganancia Neta (Monto en línea inferior para evitar desborde)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: AppColors.brutalistCell(
              color: AppColors.orange,
              borderWidth: 2.5,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '🎯 META DE GANANCIA NETA:',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w900,
                    fontSize: 10,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 3),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '+\$${SentinelAutoScanner.instance.totalProjectedProfit.toStringAsFixed(2)} USDT LIMPIOS',
                    maxLines: 1,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: AppColors.gold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAutoScanBanner() {
    final scanner = SentinelAutoScanner.instance;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: AppColors.brutalistBox(
        color: AppColors.surface,
        borderWidth: 2.5,
        shadowOffset: 4.0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 9,
                      height: 9,
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        scanner.isScanning ? 'ESCANEANDO BINANCE...' : 'AUTO-SCAN ACTIVO (25s)',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.w900,
                          fontSize: 10.5,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () => scanner.syncOrdersFromCloud(),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                  decoration: AppColors.brutalistCell(
                    color: AppColors.gold,
                    borderWidth: 1.5,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.sync,
                        size: 11,
                        color: AppColors.ink,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        scanner.isSyncingCloud ? 'Sinc...' : 'Sinc Nube',
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.w900,
                          fontSize: 9,
                          color: AppColors.ink,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Último scan Binance: ${scanner.lastScanTime}',
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textMuted,
                ),
              ),
              Text(
                'Nube: ${scanner.lastCloudSyncTime}',
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(OrderEntity order) {
    final isBuy = order.side.toUpperCase().contains('BUY');
    final elapsedStr = _formatOrderElapsedTime(order.datePlaced);
    final livePrice = SentinelAutoScanner.instance.livePrices[order.symbol];
    final isHit = livePrice != null &&
        (isBuy ? (livePrice <= order.targetPrice) : (livePrice >= order.targetPrice));

    return GestureDetector(
      onTap: () => OrderDetailModal.show(context, order),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isHit ? const Color(0xFFE8F5E9) : AppColors.surface,
          border: Border.all(
            color: isHit ? const Color(0xFF10B981) : AppColors.ink,
            width: isHit ? 3.0 : 2.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isHit ? const Color(0xFF10B981).withValues(alpha: 0.5) : AppColors.ink,
              offset: const Offset(5.0, 5.0),
              blurRadius: 0,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabecera: Moneda + Badge (LIMIT BUY en Cyan / LIMIT SELL en Naranja) + Precio Objetivo
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      order.displaySymbol,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: AppColors.brutalistCell(
                        color: isBuy ? const Color(0xFF00E5FF) : AppColors.orange,
                        borderWidth: 1.5,
                      ),
                      child: Text(
                        isBuy ? 'LIMIT BUY' : 'LIMIT SELL',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 9.5,
                          fontWeight: FontWeight.w900,
                          color: isBuy ? AppColors.ink : Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '\$${order.targetPrice.toStringAsFixed(4)}',
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: AppColors.ink,
                      ),
                    ),
                    Text(
                      isBuy ? 'PRECIO LÍMITE' : 'TAKE PROFIT',
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 8.5,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 6),

            // Línea de Tiempo Activa en Binance Spot
            Row(
              children: [
                const Icon(Icons.timer_outlined, size: 12, color: AppColors.textMuted),
                const SizedBox(width: 4),
                Text(
                  '⏱️ ACTIVA: $elapsedStr en Binance Spot',
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Precios en vivo de Binance Spot, Proximidad y Barra Táctica de Progreso
            Builder(
              builder: (context) {
                final livePrice = SentinelAutoScanner.instance.livePrices[order.symbol];
                if (livePrice == null) return const SizedBox.shrink();

                final isHit = isBuy
                    ? (livePrice <= order.targetPrice)
                    : (livePrice >= order.targetPrice);

                final dropNeededPct = isBuy && livePrice > order.targetPrice
                    ? ((livePrice - order.targetPrice) / livePrice) * 100.0
                    : 0.0;

                final riseNeededPct = !isBuy && livePrice < order.targetPrice
                    ? ((order.targetPrice - livePrice) / livePrice) * 100.0
                    : 0.0;

                // Cálculo táctico del factor y porcentaje de progreso (0.0 a 1.0 / 0% a 100%)
                double progressFactor = 0.0;
                double progressPct = 0.0;
                Color barColor = AppColors.orange;

                if (isBuy) {
                  const dropWindowPct = 5.0; // Ventana de aproximación del 5%
                  if (isHit) {
                    progressFactor = 1.0;
                    progressPct = 100.0;
                    barColor = const Color(0xFF10B981);
                  } else {
                    progressFactor = (1.0 - (dropNeededPct / dropWindowPct)).clamp(0.05, 1.0);
                    progressPct = progressFactor * 100.0;
                    barColor = (progressPct >= 70 || dropNeededPct <= 1.5)
                        ? const Color(0xFF00E5FF)
                        : const Color(0xFF38BDF8);
                  }
                } else {
                  // Ventana de aproximación hacia el Take Profit (6.0% para cubrir TP1 +3% y TP2 +5.5%)
                  const riseWindowPct = 6.0;
                  if (isHit) {
                    progressFactor = 1.0;
                    progressPct = 100.0;
                    barColor = const Color(0xFF10B981);
                  } else {
                    progressFactor = (1.0 - (riseNeededPct / riseWindowPct)).clamp(0.05, 1.0);
                    progressPct = progressFactor * 100.0;
                    barColor = (progressPct >= 70 || riseNeededPct <= 1.5)
                        ? AppColors.gold
                        : AppColors.orange;
                  }
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Celda de Proximidad Inteligente con Precio en Vivo
                    Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                      decoration: AppColors.brutalistCell(
                        color: isHit
                            ? const Color(0xFF10B981)
                            : (isBuy
                                ? (dropNeededPct <= 1.5 ? const Color(0xFF00E5FF) : AppColors.surfaceLight)
                                : (riseNeededPct <= 1.5 ? AppColors.gold : AppColors.surfaceLight)),
                        borderWidth: 1.5,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: isHit
                                      ? Colors.white
                                      : (isBuy
                                          ? (dropNeededPct <= 1.5 ? const Color(0xFF0090A0) : const Color(0xFF10B981))
                                          : (riseNeededPct <= 1.5 ? AppColors.orange : const Color(0xFF10B981))),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'BINANCE: \$${livePrice.toStringAsFixed(4)}',
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontWeight: FontWeight.w900,
                                  fontSize: 10,
                                  color: isHit ? Colors.white : AppColors.ink,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            isHit
                                ? (isBuy ? '⚡ ¡PRECIO LÍMITE ALCANZADO!' : '🎯 ¡TAKE PROFIT ALCANZADO!')
                                : (isBuy
                                    ? '📉 Falta caída de -${dropNeededPct.toStringAsFixed(2)}%'
                                    : '📈 Falta subir +${riseNeededPct.toStringAsFixed(2)}%'),
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.w900,
                              fontSize: 10,
                              color: isHit
                                  ? Colors.white
                                  : (isBuy
                                      ? (dropNeededPct <= 1.5 ? const Color(0xFF007580) : AppColors.orange)
                                      : (riseNeededPct <= 1.5 ? AppColors.orange : AppColors.textSecondary)),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 2. Barra Táctica de Progreso y Distancia Visual (Línea de Proximidad)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              isBuy ? Icons.south_west : Icons.show_chart,
                              size: 11,
                              color: isHit ? const Color(0xFF10B981) : AppColors.ink,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isBuy
                                  ? 'DISTANCIA A COMPRA (\$${livePrice.toStringAsFixed(4)} ➔ \$${order.targetPrice.toStringAsFixed(4)})'
                                  : 'DISTANCIA AL TP (\$${livePrice.toStringAsFixed(4)} ➔ \$${order.targetPrice.toStringAsFixed(4)})',
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.bold,
                                fontSize: 8.5,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '${progressPct.toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.w900,
                            fontSize: 9.5,
                            color: isHit
                                ? const Color(0xFF10B981)
                                : (progressPct >= 70 ? AppColors.orange : AppColors.ink),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Container(
                      height: 8,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E8F0),
                        border: Border.all(color: AppColors.ink, width: 1.5),
                      ),
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor: progressFactor > 0 ? progressFactor : 0.02,
                        child: Container(
                          color: barColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                );
              },
            ),

            // Grilla de 3 Celdas Simétricas
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: AppColors.brutalistCell(
                      color: AppColors.surfaceLight,
                      borderWidth: 1.5,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'CANTIDAD',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.w900,
                            fontSize: 9,
                            color: AppColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 3),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '${order.amountCoins} ${order.displaySymbol}',
                            maxLines: 1,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.w900,
                              fontSize: 11,
                              color: AppColors.ink,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: AppColors.brutalistCell(
                      color: AppColors.surface,
                      borderWidth: 1.5,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isBuy ? 'INVERSIÓN' : 'RETORNO TP',
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.w900,
                            fontSize: 9,
                            color: AppColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 3),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            isBuy
                                ? '\$${(order.amountCoins * order.targetPrice).toStringAsFixed(2)}'
                                : '\$${order.expectedReturnUsdt.toStringAsFixed(2)}',
                            maxLines: 1,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.w900,
                              fontSize: 11,
                              color: AppColors.ink,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: AppColors.brutalistCell(
                      color: isBuy ? const Color(0xFFE0F7FA) : AppColors.orangeSoft,
                      borderWidth: 1.5,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isBuy ? 'TP1 (+3%)' : 'GANANCIA',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.w900,
                            fontSize: 9,
                            color: isBuy ? const Color(0xFF007580) : const Color(0xFF9A3412),
                          ),
                        ),
                        const SizedBox(height: 3),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            isBuy
                                ? '\$${(order.targetPrice * 1.030).toStringAsFixed(4)}'
                                : '+${order.projectedProfitUsdt} USDT',
                            maxLines: 1,
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.w900,
                              fontSize: 11,
                              color: isBuy ? const Color(0xFF007580) : AppColors.orange,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Pie de Tarjeta: Fecha de Registro
            Row(
              children: [
                const Text('📅 ', style: TextStyle(fontSize: 10)),
                Text(
                  order.datePlaced,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Acciones Tácticas: Banner al tocar meta + Botones de Ficha y Archivo
            Builder(
              builder: (context) {
                final livePrice = SentinelAutoScanner.instance.livePrices[order.symbol];
                final isHit = livePrice != null &&
                    (isBuy ? (livePrice <= order.targetPrice) : (livePrice >= order.targetPrice));

                return Column(
                  children: [
                    if (isHit) ...[
                      GestureDetector(
                        onTap: () {
                          SentinelAutoScanner.instance.archiveOrder(
                            order,
                            reason: isBuy
                                ? 'Compra Límite Ejecutada en Suelo'
                                : 'Take Profit Alcanzado en Binance',
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: AppColors.ink,
                              content: Text(
                                isBuy
                                    ? '⚡ ¡Compra de ${order.displaySymbol} ejecutada y archivada!'
                                    : '🎯 ¡Orden ${order.displaySymbol} archivada con éxito!',
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  color: Color(0xFF10B981),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          );
                        },
                        child: Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(vertical: 9),
                          decoration: AppColors.brutalistBox(
                            color: const Color(0xFF10B981),
                            borderWidth: 2.0,
                            shadowOffset: 3.0,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(isBuy ? '⚡ ' : '🎯 ', style: const TextStyle(fontSize: 13)),
                              Text(
                                isBuy
                                    ? '¡COMPRA EJECUTADA! TOCAR PARA ARCHIVAR'
                                    : '¡META EJECUTADA! TOCAR PARA ARCHIVAR',
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontWeight: FontWeight.w900,
                                  fontSize: 11,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: GestureDetector(
                            onTap: () => OrderDetailModal.show(context, order),
                            child: Container(
                              height: 38,
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              decoration: AppColors.brutalistCell(
                                color: AppColors.surfaceLight,
                                borderWidth: 1.5,
                              ),
                              child: const Center(
                                child: Text(
                                  'VER FICHA Y BINANCE ➔',
                                  style: TextStyle(
                                    fontFamily: 'monospace',
                                    fontWeight: FontWeight.w900,
                                    fontSize: 10,
                                    color: AppColors.orange,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: GestureDetector(
                            onTap: () {
                              SentinelAutoScanner.instance.archiveOrder(order);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor: AppColors.ink,
                                  content: Text(
                                    '📦 Orden ${order.displaySymbol} archivada en historial',
                                    style: const TextStyle(
                                      fontFamily: 'monospace',
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              height: 38,
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              decoration: AppColors.brutalistCell(
                                color: AppColors.surface,
                                borderWidth: 1.5,
                              ),
                              child: const Center(
                                child: Text(
                                  'ARCHIVAR',
                                  style: TextStyle(
                                    fontFamily: 'monospace',
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFcmStatusCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: AppColors.brutalistBox(
        color: AppColors.surface,
        borderWidth: 2.5,
        shadowOffset: 5.0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.cloud_sync, color: AppColors.orange, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'ENLACE REMOTO FIREBASE (FCM)',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w900,
                      fontSize: 11,
                      color: AppColors.ink,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: AppColors.brutalistCell(
                  color: AppColors.gold,
                  borderWidth: 1.5,
                ),
                child: const Text(
                  'ACTIVO',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    color: AppColors.ink,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: AppColors.brutalistCell(
              color: AppColors.surfaceLight,
              borderWidth: 1.5,
            ),
            child: const Text(
              '📡 Tópico: /topics/sentinel_alerts\nRecibe alertas institucionales en vivo directo sobre tu pantalla bloqueada.',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
                height: 1.35,
              ),
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () async {
              final messenger = ScaffoldMessenger.of(context);
              final token = await NativeAlarmService.getFcmToken();
              if (!mounted) return;
              if (token != null && token.isNotEmpty) {
                await Clipboard.setData(ClipboardData(text: token));
                if (!mounted) return;
                messenger.showSnackBar(
                  const SnackBar(
                    backgroundColor: AppColors.ink,
                    content: Text(
                      '📋 ¡Token FCM copiado al portapapeles!',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                        color: AppColors.gold,
                      ),
                    ),
                  ),
                );
              } else {
                messenger.showSnackBar(
                  const SnackBar(
                    backgroundColor: AppColors.ink,
                    content: Text(
                      '⏳ Inicializando token FCM... Reintenta en unos segundos.',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                );
              }
            },
            child: Container(
              width: double.infinity,
              height: 44,
              decoration: AppColors.brutalistBox(
                color: AppColors.gold,
                borderWidth: 2.0,
                shadowOffset: 3.5,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.key, size: 16, color: AppColors.ink),
                  SizedBox(width: 8),
                  Text(
                    'COPIAR TOKEN FCM DEL DISPOSITIVO',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w900,
                      fontSize: 11,
                      color: AppColors.ink,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestAlarmSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: AppColors.brutalistBox(
        color: AppColors.surface,
        borderWidth: 3.0,
        shadowOffset: 6.0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            color: AppColors.ink,
            child: Row(
              children: const [
                Icon(Icons.alarm_on, color: AppColors.gold, size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'SIMULADOR DE FORMULARIOS EN BLOQUEO',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w900,
                      fontSize: 11,
                      color: AppColors.gold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Prueba los 3 formularios Neo-Brutalistas de dinero en vivo ("⚡ DISPARAR AHORA") o con pantalla apagada ("🔒 BLOQUEO 5S"):',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary,
              height: 1.35,
            ),
          ),
          if (_countdown > 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: AppColors.brutalistBox(
                color: AppColors.orange,
                borderWidth: 2.5,
                shadowOffset: 4.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.timer, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    '¡BLOQUEA TU TELÉFONO AHORA! ($_countdown s)',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 14),

          // MODO 1: BUY_FILLED (Formulario Limpio Exclusivo de Compra)
          _buildModeTestCard(
            title: '⚡ MODO 1: COMPRA EN SUELO (BUY_FILLED)',
            badgeText: 'PLANTAR TP',
            bgCard: AppColors.surfaceLight,
            onImmediate: () => _triggerImmediateAlarm(
              eventType: 'BUY_FILLED',
              symbol: 'SUI / USDT',
              price: r'$1.0020',
              amount: r'PRECIO COMPRA: $1.0000',
              targetPrice: r'$1.0300',
              projectedProfit: r'TP1 (+3%): $1.0300 | TP2 (+5.5%): $1.0550',
              tp1Price: r'$1.0300',
              tp2Price: r'$1.0550',
              slPrice: r'$0.9720',
              limitBuyPrice: r'$1.0000',
              totalCoins: '100.0000',
            ),
            onDelayed: () => _startCountdownAndAlarm(
              eventType: 'BUY_FILLED',
              symbol: 'SUI / USDT',
              price: r'$1.0020',
              amount: r'PRECIO COMPRA: $1.0000',
              targetPrice: r'$1.0300',
              projectedProfit: r'TP1 (+3%): $1.0300 | TP2 (+5.5%): $1.0550',
              tp1Price: r'$1.0300',
              tp2Price: r'$1.0550',
              slPrice: r'$0.9720',
              limitBuyPrice: r'$1.0000',
              totalCoins: '100.0000',
            ),
          ),

          const SizedBox(height: 12),

          // MODO 2: TP_HIT (Formulario de Venta Exacto Wireframe Richard)
          _buildModeTestCard(
            title: '💰 MODO 2: VENTA EJECUTADA (TP_HIT - PLANO RICHARD)',
            badgeText: 'GANANCIA',
            bgCard: AppColors.orangeSoft,
            onImmediate: () => _triggerImmediateAlarm(
              eventType: 'TP_HIT',
              symbol: 'XRP',
              price: r'$1.3580',
              amount: r'261.0 XRP ($354.44 USDT)',
              targetPrice: r'$1.3580',
              projectedProfit: r'+20.3600 USDT',
              totalProfit: r'+74.3900 USDT',
              liquidCash: r'891.0000 USDT',
              buyPrice: r'1.2800 USDT',
              buyDate: '15/10/26 • 16:51',
              sellDate: '21/10/26 • 05:54',
              elapsedTime: '5d 13h 2m',
              appVersion: 'V 0.2.12',
            ),
            onDelayed: () => _startCountdownAndAlarm(
              eventType: 'TP_HIT',
              symbol: 'XRP',
              price: r'$1.3580',
              amount: r'261.0 XRP ($354.44 USDT)',
              targetPrice: r'$1.3580',
              projectedProfit: r'+20.3600 USDT',
              totalProfit: r'+74.3900 USDT',
              liquidCash: r'891.0000 USDT',
              buyPrice: r'1.2800 USDT',
              buyDate: '15/10/26 • 16:51',
              sellDate: '21/10/26 • 05:54',
              elapsedTime: '5d 13h 2m',
              appVersion: 'V 0.2.12',
            ),
          ),

          const SizedBox(height: 12),

          // MODO 3: S_PLUS_ALPHA (Alerta Inicial Radar)
          _buildModeTestCard(
            title: '🔥 MODO 3: OPORTUNIDAD ALFA S+ (RADAR)',
            badgeText: 'SCORE 90+',
            bgCard: AppColors.surfaceLight,
            onImmediate: () => _triggerImmediateAlarm(
              eventType: 'S_PLUS_ALPHA',
              symbol: 'NEAR / USDT',
              price: r'$4.9500',
              amount: 'Suelo de Absorción Institucional',
              targetPrice: r'$4.8200',
              projectedProfit: 'Soporte Macro 06:00 (R:R 3.4R)',
              tp1Price: r'$4.9650',
              tp2Price: r'$5.0850',
              slPrice: r'$4.6850',
              limitBuyPrice: r'$4.8200',
            ),
            onDelayed: () => _startCountdownAndAlarm(
              eventType: 'S_PLUS_ALPHA',
              symbol: 'NEAR / USDT',
              price: r'$4.9500',
              amount: 'Suelo de Absorción Institucional',
              targetPrice: r'$4.8200',
              projectedProfit: 'Soporte Macro 06:00 (R:R 3.4R)',
              tp1Price: r'$4.9650',
              tp2Price: r'$5.0850',
              slPrice: r'$4.6850',
              limitBuyPrice: r'$4.8200',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeTestCard({
    required String title,
    required String badgeText,
    required Color bgCard,
    required VoidCallback onImmediate,
    required VoidCallback onDelayed,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: AppColors.brutalistCell(
        color: bgCard,
        borderWidth: 2.0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                    color: AppColors.ink,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                color: AppColors.ink,
                child: Text(
                  badgeText,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w900,
                    fontSize: 8,
                    color: AppColors.gold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: onImmediate,
                  child: Container(
                    height: 42,
                    decoration: AppColors.brutalistBox(
                      color: AppColors.orange,
                      borderWidth: 2.0,
                      shadowOffset: 3.0,
                    ),
                    child: const Center(
                      child: Text(
                        '⚡ DISPARAR AHORA',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.w900,
                          fontSize: 10,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: onDelayed,
                  child: Container(
                    height: 42,
                    decoration: AppColors.brutalistBox(
                      color: AppColors.gold,
                      borderWidth: 2.0,
                      shadowOffset: 3.0,
                    ),
                    child: const Center(
                      child: Text(
                        '🔒 BLOQUEO 5S',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.w900,
                          fontSize: 10,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}



class _RegisterMovementSheet extends StatefulWidget {
  const _RegisterMovementSheet();

  @override
  State<_RegisterMovementSheet> createState() => _RegisterMovementSheetState();
}

class _RegisterMovementSheetState extends State<_RegisterMovementSheet> {
  int _selectedType = 0; // 0: Compra Límite, 1: Venta Límite / TP, 2: Saldo USDT
  bool _alreadyExecuted = false;
  bool _isDca5050 = true;

  final _coinController = TextEditingController(text: 'TIA');
  final _limitPriceController = TextEditingController(text: '0.5917');
  final _amountCoinsController = TextEditingController(text: '338.0');
  final _totalUsdtController = TextEditingController(text: '200.00');

  final _sellBuyPriceController = TextEditingController(text: '1.2800');
  final _sellTargetPriceController = TextEditingController(text: '1.3580');
  final _sellCoinsController = TextEditingController(text: '261.0');

  final _liquidUsdtController = TextEditingController(
    text: SentinelAutoScanner.instance.liquidCashUsdt.toStringAsFixed(2),
  );

  @override
  void dispose() {
    _coinController.dispose();
    _limitPriceController.dispose();
    _amountCoinsController.dispose();
    _totalUsdtController.dispose();
    _sellBuyPriceController.dispose();
    _sellTargetPriceController.dispose();
    _sellCoinsController.dispose();
    _liquidUsdtController.dispose();
    super.dispose();
  }

  void _saveMovement() {
    final now = DateTime.now().toUtc().subtract(const Duration(hours: 4));
    final dateStr = '${DateFormat('yyyy-MM-dd HH:mm:ss').format(now)} BOT';

    if (_selectedType == 0) {
      // Compra Límite
      final coin = _coinController.text.trim().toUpperCase().replaceAll('USDT', '').replaceAll('/', '');
      final symbol = '${coin}USDT';
      final limitPrice = double.tryParse(_limitPriceController.text.replaceAll(',', '.')) ?? 0.0;
      final coins = double.tryParse(_amountCoinsController.text.replaceAll(',', '.')) ?? 0.0;

      if (coin.isEmpty || limitPrice <= 0 || coins <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('⚠️ Por favor completa los campos válidos de compra')),
        );
        return;
      }

      final cost = limitPrice * coins;
      final currentCash = SentinelAutoScanner.instance.liquidCashUsdt;
      final newCash = (currentCash - cost) >= 0 ? (currentCash - cost) : 0.0;
      SentinelAutoScanner.instance.setLiquidCash(newCash);

      if (_isDca5050 && !_alreadyExecuted) {
        // ENTRADA ESCALONADA 50/50 INSTITUCIONAL (SNIPER DCA)
        final coinsBlock1 = coins / 2.0;
        final costBlock1 = limitPrice * coinsBlock1;

        final retestPrice = limitPrice * 0.982;
        final coinsBlock2 = (cost / 2.0) / retestPrice;
        final costBlock2 = retestPrice * coinsBlock2;
        final avgEntry = (limitPrice + retestPrice) / 2.0;

        final order1 = OrderEntity(
          id: 'manual-buy-dca1-${DateTime.now().millisecondsSinceEpoch}',
          symbol: symbol,
          side: 'BUY',
          displaySymbol: '$coin (DCA 1)',
          entryPrice: limitPrice,
          targetPrice: limitPrice,
          amountCoins: coinsBlock1,
          status: 'ACTIVA',
          datePlaced: dateStr,
          expectedReturnUsdt: costBlock1,
          projectedProfitUsdt: costBlock1 * 0.030,
          notes: 'Disparo 1 (50% Lote @ \$$limitPrice) • TP1: \$${(limitPrice * 1.03).toStringAsFixed(4)}',
        );

        final order2 = OrderEntity(
          id: 'manual-buy-dca2-${DateTime.now().millisecondsSinceEpoch + 1}',
          symbol: symbol,
          side: 'BUY',
          displaySymbol: '$coin (DCA 2 Retest)',
          entryPrice: retestPrice,
          targetPrice: retestPrice,
          amountCoins: coinsBlock2,
          status: 'ACTIVA',
          datePlaced: dateStr,
          expectedReturnUsdt: costBlock2,
          projectedProfitUsdt: costBlock2 * 0.030,
          notes: 'Disparo 2 Retest (-1.8% @ \$${retestPrice.toStringAsFixed(4)}) • Promedio Ponderado: \$${avgEntry.toStringAsFixed(4)}',
        );

        SentinelAutoScanner.instance.addOrder(order1);
        SentinelAutoScanner.instance.addOrder(order2);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.ink,
            content: Text(
              '🎯 ¡Entrada Escalonada 50/50 activada ($coin: 50% @ \$$limitPrice y 50% @ \$${retestPrice.toStringAsFixed(4)})!',
              style: const TextStyle(fontFamily: 'monospace', color: Color(0xFF00E5FF), fontWeight: FontWeight.bold),
            ),
          ),
        );
        Navigator.pop(context);
        return;
      }

      final newOrder = OrderEntity(
        id: 'manual-buy-${DateTime.now().millisecondsSinceEpoch}',
        symbol: symbol,
        side: 'BUY',
        displaySymbol: coin,
        entryPrice: limitPrice,
        targetPrice: limitPrice,
        amountCoins: coins,
        status: _alreadyExecuted ? 'EJECUTADA / ARCHIVADA' : 'ACTIVA',
        datePlaced: dateStr,
        expectedReturnUsdt: cost,
        projectedProfitUsdt: cost * 0.030,
        notes: _alreadyExecuted ? 'Compra ejecutada en Binance Spot @ \$$limitPrice' : '',
      );

      if (_alreadyExecuted) {
        SentinelAutoScanner.instance.archiveOrder(newOrder, reason: 'Compra Ejecutada en Binance Spot');
      } else {
        SentinelAutoScanner.instance.addOrder(newOrder);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.ink,
          content: Text(
            _alreadyExecuted
                ? '⚡ ¡Compra de $coins $coin @ \$$limitPrice registrada y descontada de USDT!'
                : '⚡ ¡Orden de Compra Límite ($coin @ \$$limitPrice) activada! Saldo USDT: \$${newCash.toStringAsFixed(2)}',
            style: const TextStyle(fontFamily: 'monospace', color: Color(0xFF00E5FF), fontWeight: FontWeight.bold),
          ),
        ),
      );
      Navigator.pop(context);

    } else if (_selectedType == 1) {
      // Venta Límite / TP
      final coin = _coinController.text.trim().toUpperCase().replaceAll('USDT', '').replaceAll('/', '');
      final symbol = '${coin}USDT';
      final buyPrice = double.tryParse(_sellBuyPriceController.text.replaceAll(',', '.')) ?? 0.0;
      final targetPrice = double.tryParse(_sellTargetPriceController.text.replaceAll(',', '.')) ?? 0.0;
      final coins = double.tryParse(_sellCoinsController.text.replaceAll(',', '.')) ?? 0.0;

      if (coin.isEmpty || targetPrice <= 0 || coins <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('⚠️ Por favor completa los campos válidos de venta')),
        );
        return;
      }

      final totalReturn = targetPrice * coins;
      final profit = (targetPrice - (buyPrice > 0 ? buyPrice : targetPrice * 0.97)) * coins;

      final newOrder = OrderEntity(
        id: 'manual-sell-${DateTime.now().millisecondsSinceEpoch}',
        symbol: symbol,
        side: 'SELL',
        displaySymbol: coin,
        entryPrice: buyPrice > 0 ? buyPrice : targetPrice * 0.97,
        targetPrice: targetPrice,
        amountCoins: coins,
        status: _alreadyExecuted ? 'EJECUTADA / ARCHIVADA' : 'ACTIVA',
        datePlaced: dateStr,
        expectedReturnUsdt: totalReturn,
        projectedProfitUsdt: profit > 0 ? profit : 0.0,
        notes: _alreadyExecuted ? 'Venta ejecutada en Binance Spot @ \$$targetPrice' : '',
      );

      if (_alreadyExecuted) {
        // Al archivar una venta, archiveOrder ya acredita el retorno esperado al saldo USDT
        SentinelAutoScanner.instance.archiveOrder(newOrder, reason: 'Venta Ejecutada en Binance Spot');
      } else {
        SentinelAutoScanner.instance.addOrder(newOrder);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.ink,
          content: Text(
            _alreadyExecuted
                ? '🎯 ¡Venta de $coins $coin @ \$$targetPrice cobrada! Saldo USDT acreditado: +\$${totalReturn.toStringAsFixed(2)}'
                : '🎯 ¡Orden de Venta Límite ($coin @ \$$targetPrice) activada en Centinela!',
            style: const TextStyle(fontFamily: 'monospace', color: AppColors.gold, fontWeight: FontWeight.bold),
          ),
        ),
      );
      Navigator.pop(context);

    } else {
      // Ajustar Saldo USDT
      final usdt = double.tryParse(_liquidUsdtController.text.replaceAll(',', '.')) ?? 0.0;
      SentinelAutoScanner.instance.setLiquidCash(usdt);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.ink,
          content: Text(
            '💵 Saldo Spot actualizado: \$$usdt USDT',
            style: const TextStyle(fontFamily: 'monospace', color: AppColors.gold, fontWeight: FontWeight.bold),
          ),
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.ink, width: 3.5),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabecera Modal
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '📝 REGISTRAR MOVIMIENTO SPOT',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                    color: AppColors.ink,
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: AppColors.brutalistCell(
                      color: AppColors.surfaceLight,
                      borderWidth: 1.5,
                    ),
                    child: const Icon(Icons.close, size: 16, color: AppColors.ink),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Selector de Tipo de Movimiento
            Row(
              children: [
                _buildTabButton(0, '⚡ COMPRA LÍMITE', const Color(0xFF00E5FF)),
                const SizedBox(width: 8),
                _buildTabButton(1, '🎯 VENTA LÍMITE', AppColors.orange),
                const SizedBox(width: 8),
                _buildTabButton(2, '💵 SALDO USDT', AppColors.gold),
              ],
            ),
            const SizedBox(height: 16),

            if (_selectedType == 0) ...[
              // COMPRA LÍMITE
              _buildField('MONEDA (SPOT)', _coinController, hint: 'Ej. TIA, OP, SOL'),
              const SizedBox(height: 10),
              _buildField('PRECIO LÍMITE DE COMPRA (USDT)', _limitPriceController,
                  hint: '0.5917', isNumber: true, onChanged: (_) => _recalcBuyCoins()),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildField('MONEDAS', _amountCoinsController,
                        hint: '338.0', isNumber: true, onChanged: (_) => _recalcBuyUsdt()),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildField('TOTAL USDT', _totalUsdtController,
                        hint: '200.00', isNumber: true, onChanged: (_) => _recalcBuyCoins()),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Proyección Automática
              Builder(
                builder: (_) {
                  final p = double.tryParse(_limitPriceController.text) ?? 0.0;
                  final tp1 = p * 1.030;
                  final tp2 = p * 1.055;
                  return Container(
                    padding: const EdgeInsets.all(10),
                    decoration: AppColors.brutalistCell(
                      color: const Color(0xFFE0F7FA),
                      borderWidth: 1.5,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'TP1 (+3%): \$${tp1.toStringAsFixed(4)}',
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.bold,
                            fontSize: 10.5,
                            color: Color(0xFF007580),
                          ),
                        ),
                        Text(
                          'TP2 (+5.5%): \$${tp2.toStringAsFixed(4)}',
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.bold,
                            fontSize: 10.5,
                            color: Color(0xFF007580),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () => setState(() => _isDca5050 = !_isDca5050),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: AppColors.brutalistCell(
                    color: _isDca5050 ? const Color(0xFFE0F2F1) : AppColors.surfaceLight,
                    borderWidth: 1.5,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _isDca5050 ? Icons.check_circle : Icons.radio_button_unchecked,
                        size: 18,
                        color: _isDca5050 ? const Color(0xFF00796B) : AppColors.ink,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              '🎯 ENTRADA ESCALONADA 50/50 (SNIPER DCA)',
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF004D40),
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              '50% al precio inicial y 50% en retesteo (-1.8%). Reduce el drawdown y acelera el TP.',
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF00796B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: AppColors.brutalistCell(
                  color: const Color(0xFFFFF8E1),
                  borderWidth: 1.0,
                ),
                child: Row(
                  children: const [
                    Text('🛡️ ', style: TextStyle(fontSize: 12)),
                    Expanded(
                      child: Text(
                        'BLINDAJE BREAK-EVEN: Al tocar TP1 (+3%), mueve el SL de la segunda mitad al precio de entrada (\$0 riesgo).',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 8.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFB78103),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (_selectedType == 1) ...[
              // VENTA LÍMITE / TP
              _buildField('MONEDA (SPOT)', _coinController, hint: 'Ej. ONDO, SUI, NEAR'),
              const SizedBox(height: 10),
              _buildField('PRECIO DE COMPRA ORIGINAL (USDT)', _sellBuyPriceController,
                  hint: '1.2800', isNumber: true),
              const SizedBox(height: 10),
              _buildField('PRECIO OBJETIVO DE VENTA / TP (USDT)', _sellTargetPriceController,
                  hint: '1.3580', isNumber: true),
              const SizedBox(height: 10),
              _buildField('CANTIDAD DE MONEDAS', _sellCoinsController,
                  hint: '261.0', isNumber: true),
            ] else ...[
              // SALDO USDT SPOT
              _buildField('SALDO LÍQUIDO SPOT (USDT)', _liquidUsdtController,
                  hint: '891.00', isNumber: true),
              const SizedBox(height: 8),
              const Text(
                '💡 Este monto se actualiza en el Panel y en los Formularios de Alarma.',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 10,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],

            if (_selectedType == 0 || _selectedType == 1) ...[
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () => setState(() => _alreadyExecuted = !_alreadyExecuted),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: AppColors.brutalistCell(
                    color: _alreadyExecuted ? const Color(0xFFE8F5E9) : AppColors.surfaceLight,
                    borderWidth: 1.5,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _alreadyExecuted ? Icons.check_box : Icons.check_box_outline_blank,
                        size: 18,
                        color: _alreadyExecuted ? const Color(0xFF2E7D32) : AppColors.ink,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _selectedType == 0
                              ? '¿Orden ya ejecutada en Binance? (Descuenta saldo USDT e ingresa al historial)'
                              : '¿Venta ya ejecutada / cobrada en Binance? (Acredita saldo USDT inmediatamente)',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: _alreadyExecuted ? const Color(0xFF1B5E20) : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: AppColors.brutalistCell(
                  color: const Color(0xFFFFF9C4),
                  borderWidth: 1.5,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Saldo Spot: \$${SentinelAutoScanner.instance.liquidCashUsdt.toStringAsFixed(2)} USDT',
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppColors.ink,
                      ),
                    ),
                    Text(
                      _selectedType == 0
                          ? 'Tras orden: \$${(SentinelAutoScanner.instance.liquidCashUsdt - ((double.tryParse(_limitPriceController.text) ?? 0.0) * (double.tryParse(_amountCoinsController.text) ?? 0.0))).clamp(0.0, 999999.0).toStringAsFixed(2)}'
                          : (_alreadyExecuted
                              ? 'Tras cobro: \$${(SentinelAutoScanner.instance.liquidCashUsdt + ((double.tryParse(_sellTargetPriceController.text) ?? 0.0) * (double.tryParse(_sellCoinsController.text) ?? 0.0))).toStringAsFixed(2)}'
                              : 'Sin cambio hasta cobro'),
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFFE65100),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 20),

            // Botón Guardar
            GestureDetector(
              onTap: _saveMovement,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: AppColors.brutalistBox(
                  color: _selectedType == 0
                      ? const Color(0xFF00E5FF)
                      : (_selectedType == 1 ? AppColors.orange : AppColors.gold),
                  borderWidth: 2.5,
                  shadowOffset: 4.0,
                ),
                child: Center(
                  child: Text(
                    _selectedType == 2
                        ? '💾 ACTUALIZAR SALDO SPOT'
                        : '💾 ACTIVAR VIGILANCIA EN CENTINELA',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                      color: _selectedType == 1 ? Colors.white : AppColors.ink,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _recalcBuyCoins() {
    final price = double.tryParse(_limitPriceController.text.replaceAll(',', '.')) ?? 0.0;
    final usdt = double.tryParse(_totalUsdtController.text.replaceAll(',', '.')) ?? 0.0;
    if (price > 0 && usdt > 0) {
      final coins = usdt / price;
      _amountCoinsController.text = coins.toStringAsFixed(2);
      setState(() {});
    }
  }

  void _recalcBuyUsdt() {
    final price = double.tryParse(_limitPriceController.text.replaceAll(',', '.')) ?? 0.0;
    final coins = double.tryParse(_amountCoinsController.text.replaceAll(',', '.')) ?? 0.0;
    if (price > 0 && coins > 0) {
      final usdt = coins * price;
      _totalUsdtController.text = usdt.toStringAsFixed(2);
      setState(() {});
    }
  }

  Widget _buildTabButton(int type, String label, Color color) {
    final isSelected = _selectedType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedType = type),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: AppColors.brutalistCell(
            color: isSelected ? color : AppColors.surfaceLight,
            borderWidth: isSelected ? 2.0 : 1.2,
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'monospace',
                fontWeight: FontWeight.w900,
                fontSize: 9.5,
                color: isSelected && type == 1 ? Colors.white : AppColors.ink,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller,
      {String hint = '', bool isNumber = false, ValueChanged<String>? onChanged}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'monospace',
            fontWeight: FontWeight.w900,
            fontSize: 9.5,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          decoration: AppColors.brutalistCell(
            color: AppColors.surfaceLight,
            borderWidth: 1.5,
          ),
          child: TextField(
            controller: controller,
            keyboardType: isNumber
                ? const TextInputType.numberWithOptions(decimal: true)
                : TextInputType.text,
            onChanged: onChanged,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontWeight: FontWeight.w900,
              fontSize: 13,
              color: AppColors.ink,
            ),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              border: InputBorder.none,
              hintText: hint,
              hintStyle: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                color: AppColors.textMuted,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
