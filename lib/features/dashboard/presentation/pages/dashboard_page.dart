import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/native_alarm_service.dart';
import '../../../../core/services/sentinel_auto_scanner.dart';
import '../../../orders/domain/order_entity.dart';
import '../../../orders/presentation/widgets/order_detail_modal.dart';

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

  @override
  void initState() {
    super.initState();
    _updateTime();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) => _updateTime());

    // Conectar el Centinela Autónomo (Descarga Nube + Auto-scan Binance cada 25s)
    SentinelAutoScanner.instance.addListener(_onScannerUpdate);
    SentinelAutoScanner.instance.init();
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
    String totalProfit = '+\$84.33 USDT',
    String liquidCash = '\$0.91 USDT',
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
    );
  }

  void _startCountdownAndAlarm({
    required String eventType,
    required String symbol,
    required String price,
    required String amount,
    required String targetPrice,
    required String projectedProfit,
    String totalProfit = '+\$84.33 USDT',
    String liquidCash = '\$0.91 USDT',
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
                          'V.0.1.8',
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
            // 1. Hero Card Brutalista: Resumen de Bóveda y Liquidez
            _buildVaultHeroCard(),

            const SizedBox(height: 24),

            // 2. Cabecera de Sección: Órdenes Vivas en Binance Spot
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: AppColors.brutalistBox(
                    color: AppColors.ink,
                    borderWidth: 2.0,
                    shadowOffset: 3.0,
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.bolt, color: AppColors.gold, size: 16),
                      SizedBox(width: 6),
                      Text(
                        'ÓRDENES VIVAS BINANCE SPOT',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.w900,
                          fontSize: 11,
                          color: AppColors.gold,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: AppColors.brutalistBox(
                    color: AppColors.gold,
                    borderWidth: 2.0,
                    shadowOffset: 3.0,
                  ),
                  child: Text(
                    '${SentinelAutoScanner.instance.orders.length} ACTIVAS',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      color: AppColors.ink,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Banner Táctico: Centinela Autónomo (Binance Scan cada 25s + Nube)
            _buildAutoScanBanner(),

            const SizedBox(height: 14),

            // 3. Lista Dinámica de Órdenes Vivas (Descargadas de la Nube)
            ...SentinelAutoScanner.instance.orders.map((order) => _buildOrderCard(order)),

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
                    'MiCripto Sentinel V.0.1.8 • Terminal Centinela & Radar S+',
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
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Color(0xFF10B981),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    scanner.isScanning ? 'ESCANEANDO BINANCE...' : 'AUTO-SCAN ACTIVO (Binance 25s)',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w900,
                      fontSize: 11,
                      color: AppColors.ink,
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: () => scanner.syncOrdersFromCloud(),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: AppColors.brutalistCell(
                    color: AppColors.gold,
                    borderWidth: 1.5,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.sync,
                        size: 11,
                        color: AppColors.ink,
                      ),
                      const SizedBox(width: 4),
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
    return GestureDetector(
      onTap: () => OrderDetailModal.show(context, order),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(14),
        decoration: AppColors.brutalistBox(
          color: AppColors.surface,
          borderWidth: 2.5,
          shadowOffset: 5.0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabecera de Orden: Par + Sello TP + Precio Objetivo Gigante
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: AppColors.brutalistCell(
                        color: AppColors.gold,
                        borderWidth: 2.0,
                      ),
                      child: Text(
                        order.displaySymbol,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                      decoration: AppColors.brutalistCell(
                        color: AppColors.orange,
                        borderWidth: 1.5,
                      ),
                      child: Text(
                        order.side.toUpperCase(),
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  '\$${order.targetPrice.toStringAsFixed(4)}',
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: AppColors.ink,
                  ),
                ),
              ],
            ),

            // Barra Táctica de Progreso hacia el TP (Indicador Visual desde Compra hasta TP)
            Builder(
              builder: (context) {
                final livePrice = SentinelAutoScanner.instance.livePrices[order.symbol];
                final entry = order.entryPrice;
                final target = order.targetPrice;
                final totalDelta = target - entry;

                double progressFactor = 0.0;
                double progressPct = 0.0;
                if (totalDelta > 0 && livePrice != null) {
                  final currentDelta = livePrice - entry;
                  progressFactor = (currentDelta / totalDelta).clamp(0.0, 1.0);
                  progressPct = (currentDelta / totalDelta) * 100.0;
                }

                Color barColor;
                if (progressPct >= 100) {
                  barColor = const Color(0xFF10B981);
                } else if (progressPct >= 70) {
                  barColor = AppColors.gold;
                } else {
                  barColor = AppColors.orange;
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.show_chart, size: 12, color: AppColors.ink),
                            const SizedBox(width: 4),
                            Text(
                              'PROGRESO AL TP (\$${entry.toStringAsFixed(4)} ➔ \$${target.toStringAsFixed(4)})',
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.bold,
                                fontSize: 9,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          livePrice != null
                              ? '${progressPct.toStringAsFixed(1)}%'
                              : '---%',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.w900,
                            fontSize: 10,
                            color: progressPct >= 100
                                ? const Color(0xFF10B981)
                                : (progressPct >= 70 ? AppColors.orange : AppColors.ink),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
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

            // Grilla de 3 Celdas Simétricas: Cantidad | Retorno | Ganancia
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
                        const Text(
                          'RETORNO TP',
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
                            '\$${order.expectedReturnUsdt.toStringAsFixed(2)}',
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
                      color: AppColors.orangeSoft,
                      borderWidth: 1.5,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'GANANCIA',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.w900,
                            fontSize: 9,
                            color: Color(0xFF9A3412),
                          ),
                        ),
                        const SizedBox(height: 3),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '+${order.projectedProfitUsdt} USDT',
                            maxLines: 1,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.w900,
                              fontSize: 11,
                              color: AppColors.orange,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Precios en vivo de Binance Spot y Proximidad hacia el TP
            Builder(
              builder: (context) {
                final livePrice = SentinelAutoScanner.instance.livePrices[order.symbol];
                final distPct = SentinelAutoScanner.instance.distancePctMap[order.id];
                if (livePrice == null) return const SizedBox.shrink();

                final isClose = distPct != null && distPct <= 1.0 && distPct > 0;
                final isHit = distPct != null && distPct <= 0;

                return Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: AppColors.brutalistCell(
                    color: isHit ? const Color(0xFF10B981) : (isClose ? AppColors.gold : AppColors.surfaceLight),
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
                              color: isHit ? Colors.white : (isClose ? AppColors.orange : const Color(0xFF10B981)),
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
                      if (distPct != null)
                        Text(
                          isHit
                              ? '🎯 ¡META TOCADA!'
                              : (distPct > 0
                                  ? 'Falta +${distPct.toStringAsFixed(2)}% para TP'
                                  : 'Superado por ${distPct.abs().toStringAsFixed(2)}%'),
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.w900,
                            fontSize: 10,
                            color: isHit ? Colors.white : (isClose ? AppColors.orange : AppColors.textSecondary),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 10),

            // Pie de Tarjeta: Fecha en su propia línea
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

            // Opción / Botón táctica en su propia línea completa (sin desbordes laterales)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
              decoration: AppColors.brutalistCell(
                color: AppColors.surfaceLight,
                borderWidth: 1.5,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Text(
                    'VER FICHA Y ABRIR BINANCE ➔',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w900,
                      fontSize: 11,
                      color: AppColors.orange,
                      letterSpacing: 0.3,
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

          // MODO 1: BUY_FILLED
          _buildModeTestCard(
            title: '⚡ MODO 1: COMPRA EN SUELO (BUY_FILLED)',
            badgeText: 'PLANTAR TP',
            bgCard: AppColors.surfaceLight,
            onImmediate: () => _triggerImmediateAlarm(
              eventType: 'BUY_FILLED',
              symbol: 'SUI / USDT',
              price: '\$1.0020',
              amount: '149.7 SUI (\$149.99 USDT)',
              targetPrice: '\$1.0650',
              projectedProfit: '+\$9.12 USDT (+6.08%)',
            ),
            onDelayed: () => _startCountdownAndAlarm(
              eventType: 'BUY_FILLED',
              symbol: 'SUI / USDT',
              price: '\$1.0020',
              amount: '149.7 SUI (\$149.99 USDT)',
              targetPrice: '\$1.0650',
              projectedProfit: '+\$9.12 USDT (+6.08%)',
            ),
          ),

          const SizedBox(height: 12),

          // MODO 2: TP_HIT
          _buildModeTestCard(
            title: '💰 MODO 2: TAKE PROFIT COBRADO (TP_HIT)',
            badgeText: 'GANANCIA',
            bgCard: AppColors.orangeSoft,
            onImmediate: () => _triggerImmediateAlarm(
              eventType: 'TP_HIT',
              symbol: 'SUI / USDT',
              price: '\$1.0650',
              amount: '149.7 SUI (\$159.43 USDT)',
              targetPrice: '\$1.0650',
              projectedProfit: '+\$9.12 USDT (+6.08%)',
              totalProfit: '+\$70.07 USDT',
              liquidCash: '\$36.59 USDT',
            ),
            onDelayed: () => _startCountdownAndAlarm(
              eventType: 'TP_HIT',
              symbol: 'SUI / USDT',
              price: '\$1.0650',
              amount: '149.7 SUI (\$159.43 USDT)',
              targetPrice: '\$1.0650',
              projectedProfit: '+\$9.12 USDT (+6.08%)',
              totalProfit: '+\$70.07 USDT',
              liquidCash: '\$36.59 USDT',
            ),
          ),

          const SizedBox(height: 12),

          // MODO 3: S_PLUS_ALPHA
          _buildModeTestCard(
            title: '🔥 MODO 3: OPORTUNIDAD ALFA S+ (RADAR)',
            badgeText: 'SCORE 90+',
            bgCard: AppColors.surfaceLight,
            onImmediate: () => _triggerImmediateAlarm(
              eventType: 'S_PLUS_ALPHA',
              symbol: 'NEAR / USDT',
              price: '\$4.9500',
              amount: 'Suelo de Absorción Institucional',
              targetPrice: '\$4.9500',
              projectedProfit: 'Soporte Macro 06:00 (R:R 3.4R)',
            ),
            onDelayed: () => _startCountdownAndAlarm(
              eventType: 'S_PLUS_ALPHA',
              symbol: 'NEAR / USDT',
              price: '\$4.9500',
              amount: 'Suelo de Absorción Institucional',
              targetPrice: '\$4.9500',
              projectedProfit: 'Soporte Macro 06:00 (R:R 3.4R)',
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
