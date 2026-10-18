import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/native_alarm_service.dart';
import '../../domain/order_entity.dart';

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
                  // 1. Header Brutalista: Par, Tipo y Botón Cerrar Cuadrado
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: AppColors.brutalistBox(
                              color: AppColors.gold,
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
                              color: AppColors.orange,
                              borderWidth: 2.0,
                            ),
                            child: Text(
                              order.side.toUpperCase(),
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

                  // 2. Bloque Hero Brutalista: Precio Take Profit en Binance
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
                            '💰 Retorno al ejecutar: \$${order.expectedReturnUsdt.toStringAsFixed(2)} USDT',
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
                          label: 'FECHA REGISTRADA',
                          value: order.datePlaced,
                          bgColor: AppColors.surface,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // 4. Botón Brutalista de Acción Directa a Binance
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).pop();
                      NativeAlarmService.openBinance();
                    },
                    child: Container(
                      width: double.infinity,
                      height: 52,
                      decoration: AppColors.brutalistBox(
                        color: AppColors.orange,
                        borderWidth: 3.0,
                        shadowOffset: 5.0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.rocket_launch, color: Colors.white, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'ABRIR ESTE PAR EN BINANCE SPOT',
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.w900,
                              fontSize: 12,
                              color: Colors.white,
                              letterSpacing: 0.4,
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
