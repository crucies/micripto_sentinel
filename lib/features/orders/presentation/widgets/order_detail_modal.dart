import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/native_alarm_service.dart';
import '../../domain/order_entity.dart';
import '../../../../core/services/sentinel_auto_scanner.dart';

class OrderDetailModal extends StatelessWidget {
  final OrderEntity order;

  const OrderDetailModal({super.key, required this.order});

  static void show(BuildContext context, OrderEntity order) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.72),
      builder: (_) => OrderDetailModal(order: order),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isBuy = order.isBuy;
    final tp1 = order.targetPrice * 1.030;
    final tp2 = order.targetPrice * 1.055;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: AppColors.brutalistBox(
              color: AppColors.surface,
              borderWidth: 3.0,
              shadowOffset: 7.0,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Header Brutalista: Par, Badge de Tipo y Botón Cerrar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: AppColors.brutalistBox(
                              color: isBuy ? const Color(0xFF00E5FF) : AppColors.gold,
                              borderWidth: 2.0,
                              shadowOffset: 3.0,
                            ),
                            child: Text(
                              order.displaySymbol,
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                                color: AppColors.ink,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            decoration: AppColors.brutalistCell(
                              color: isBuy ? const Color(0xFF00B0FF) : AppColors.orange,
                              borderWidth: 2.0,
                            ),
                            child: Text(
                              isBuy ? '🟢 LIMIT BUY' : '🎯 LIMIT SELL',
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.w900,
                                fontSize: 10,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: AppColors.brutalistBox(
                            color: AppColors.surfaceLight,
                            borderWidth: 2.0,
                            shadowOffset: 2.5,
                          ),
                          child: const Icon(
                            Icons.close,
                            color: AppColors.ink,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // 2. Bloque Hero Brutalista Diferenciado (Compra vs Venta)
                  if (isBuy)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: AppColors.brutalistBox(
                        color: const Color(0xFF00E5FF),
                        borderWidth: 2.5,
                        shadowOffset: 4.0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            color: AppColors.ink,
                            child: const Text(
                              '⚡ PRECIO LÍMITE DE COMPRA (SUELO DE ENTRADA)',
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.w900,
                                fontSize: 9.5,
                                color: Color(0xFF00E5FF),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: AppColors.brutalistCell(
                              color: AppColors.ink,
                              borderWidth: 2.5,
                            ),
                            child: Center(
                              child: Text(
                                '\$${order.targetPrice.toStringAsFixed(4)} USDT',
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontWeight: FontWeight.w900,
                                  fontSize: 24,
                                  color: Color(0xFF00E5FF),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            decoration: AppColors.brutalistCell(
                              color: AppColors.surface,
                              borderWidth: 2.0,
                            ),
                            child: Text(
                              '💵 Capital a Invertir: \$${order.expectedReturnUsdt.toStringAsFixed(2)} USDT (${order.amountCoins} ${order.displaySymbol})',
                              textAlign: TextAlign.center,
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
                    )
                  else
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: AppColors.brutalistBox(
                        color: AppColors.gold,
                        borderWidth: 2.5,
                        shadowOffset: 4.0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            color: AppColors.ink,
                            child: const Text(
                              '🎯 PRECIO TAKE PROFIT EN BINANCE SPOT',
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.w900,
                                fontSize: 10,
                                color: AppColors.gold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: AppColors.brutalistCell(
                              color: AppColors.orange,
                              borderWidth: 2.5,
                            ),
                            child: Center(
                              child: Text(
                                '\$${order.targetPrice.toStringAsFixed(4)} USDT',
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontWeight: FontWeight.w900,
                                  fontSize: 24,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            decoration: AppColors.brutalistCell(
                              color: AppColors.surface,
                              borderWidth: 2.0,
                            ),
                            child: Text(
                              '💰 Retorno al cobrar: \$${order.expectedReturnUsdt.toStringAsFixed(2)} USDT',
                              textAlign: TextAlign.center,
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

                  const SizedBox(height: 16),

                  // 3. Grilla de Datos Distribuida en 2x2 Celdas Brutalistas
                  if (isBuy) ...[
                    Row(
                      children: [
                        Expanded(
                          child: _buildGridCell(
                            label: 'CANTIDAD A COMPRAR',
                            value: '${order.amountCoins} ${order.displaySymbol}',
                            bgColor: AppColors.surfaceLight,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildGridCell(
                            label: 'PLAN SALIDA TP1 (+3%)',
                            value: '\$${tp1.toStringAsFixed(4)}',
                            bgColor: const Color(0xFFE0F7FA),
                            valueColor: const Color(0xFF00838F),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _buildGridCell(
                            label: 'ESTADO EN BINANCE',
                            value: order.status,
                            bgColor: AppColors.surface,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildGridCell(
                            label: 'PLAN SALIDA TP2 (+5.5%)',
                            value: '\$${tp2.toStringAsFixed(4)}',
                            bgColor: const Color(0xFFE0F7FA),
                            valueColor: const Color(0xFF00838F),
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    Row(
                      children: [
                        Expanded(
                          child: _buildGridCell(
                            label: 'CANTIDAD EN ORDEN',
                            value: '${order.amountCoins} ${order.displaySymbol}',
                            bgColor: AppColors.surfaceLight,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildGridCell(
                            label: 'GANANCIA NETA PROY.',
                            value: '+${order.projectedProfitUsdt} USDT',
                            bgColor: AppColors.orangeSoft,
                            valueColor: const Color(0xFFC2410C),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _buildGridCell(
                            label: 'PROGRESO DE LLENADO',
                            value: order.status,
                            bgColor: AppColors.surface,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildGridCell(
                            label: 'PRECIO DE ENTRADA',
                            value: '\$${order.entryPrice.toStringAsFixed(4)}',
                            bgColor: AppColors.surface,
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 20),

                  // 4. Botón Brutalista de Acción Directa a Binance
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).pop();
                      NativeAlarmService.openBinance();
                    },
                    child: Container(
                      width: double.infinity,
                      height: 50,
                      decoration: AppColors.brutalistBox(
                        color: isBuy ? const Color(0xFF00E5FF) : AppColors.orange,
                        borderWidth: 3.0,
                        shadowOffset: 5.0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isBuy ? Icons.shopping_cart : Icons.rocket_launch,
                            color: isBuy ? AppColors.ink : Colors.white,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isBuy ? 'ABRIR PAR EN BINANCE (COMPRA)' : 'ABRIR ESTE PAR EN BINANCE SPOT',
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.w900,
                              fontSize: 12,
                              color: isBuy ? AppColors.ink : Colors.white,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // 5. Botón Táctico de Archivar Orden
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).pop();
                      SentinelAutoScanner.instance.archiveOrder(
                        order,
                        reason: isBuy ? 'Compra Ejecutada en Binance' : 'Take Profit Cobrado en Binance',
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: AppColors.ink,
                          content: Text(
                            '📦 Orden ${order.displaySymbol} archivada con éxito',
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              color: AppColors.gold,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    },
                    child: Container(
                      width: double.infinity,
                      height: 48,
                      decoration: AppColors.brutalistBox(
                        color: AppColors.gold,
                        borderWidth: 2.5,
                        shadowOffset: 4.0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Text('📦 ', style: TextStyle(fontSize: 15)),
                          Text(
                            'ARCHIVAR ORDEN (GUARDAR EN HISTORIAL)',
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.w900,
                              fontSize: 11,
                              color: AppColors.ink,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGridCell({
    required String label,
    required String value,
    required Color bgColor,
    Color? valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: AppColors.brutalistCell(
        color: bgColor,
        borderWidth: 2.0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontWeight: FontWeight.w900,
              fontSize: 9,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'monospace',
              fontWeight: FontWeight.w900,
              fontSize: 12,
              color: valueColor ?? AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}
