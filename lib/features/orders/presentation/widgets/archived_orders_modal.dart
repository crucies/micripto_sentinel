import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/native_alarm_service.dart';
import '../../../../core/services/sentinel_auto_scanner.dart';
import '../../domain/order_entity.dart';

class ArchivedOrdersModal extends StatelessWidget {
  const ArchivedOrdersModal({super.key});

  static void show(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.72),
      builder: (_) => const ArchivedOrdersModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480, maxHeight: 680),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: AppColors.brutalistBox(
              color: AppColors.background,
              borderWidth: 3.0,
              shadowOffset: 7.0,
            ),
            child: AnimatedBuilder(
              animation: SentinelAutoScanner.instance,
              builder: (context, _) {
                final archived = SentinelAutoScanner.instance.archivedOrders;
                final totalProfit = SentinelAutoScanner.instance.totalArchivedProfit;

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Header Brutalista con Botón Cerrar
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
                              child: const Row(
                                children: [
                                  Text(
                                    '📦 ',
                                    style: TextStyle(fontSize: 14),
                                  ),
                                  Text(
                                    'HISTORIAL ARCHIVADO',
                                    style: TextStyle(
                                      fontFamily: 'monospace',
                                      fontWeight: FontWeight.w900,
                                      fontSize: 13,
                                      color: AppColors.ink,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: AppColors.brutalistBox(
                              color: AppColors.surface,
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

                    const SizedBox(height: 12),

                    // 2. Banner de Métricas del Historial
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: AppColors.brutalistCell(
                        color: AppColors.surface,
                        borderWidth: 2.0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${archived.length} ÓRDENES COMPLETADAS',
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.w900,
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981),
                              border: Border.all(color: AppColors.ink, width: 1.5),
                            ),
                            child: Text(
                              '+${totalProfit.toStringAsFixed(2)} USDT GANADOS',
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
                    ),

                    const SizedBox(height: 12),

                    // 3. Lista de Órdenes Archivadas
                    Flexible(
                      child: archived.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24.0),
                                child: Text(
                                  'No hay órdenes archivadas en el historial.\nCuando una orden se ejecute, presiona "Archivar" para guardarla aquí.',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 12,
                                    color: AppColors.textMuted,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              itemCount: archived.length,
                              itemBuilder: (context, index) {
                                final order = archived[index];
                                return _buildArchivedOrderCard(context, order);
                              },
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildArchivedOrderCard(BuildContext context, OrderEntity order) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: AppColors.brutalistBox(
        color: AppColors.surface,
        borderWidth: 2.0,
        shadowOffset: 4.0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Fila Superior: Par + Badge Ejecutado + Precio TP
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: AppColors.brutalistCell(
                      color: AppColors.gold,
                      borderWidth: 1.5,
                    ),
                    child: Text(
                      order.displaySymbol,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981),
                      border: Border.all(color: AppColors.ink, width: 1.5),
                    ),
                    child: const Text(
                      '✅ COMPLETADA',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w900,
                        fontSize: 9,
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
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Celdas de Métricas
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: AppColors.brutalistCell(
                    color: AppColors.surfaceLight,
                    borderWidth: 1.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'CANTIDAD',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 8,
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${order.amountCoins} ${order.displaySymbol}',
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: AppColors.brutalistCell(
                    color: AppColors.surfaceLight,
                    borderWidth: 1.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'RETORNO USDT',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 8,
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '\$${order.expectedReturnUsdt.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: AppColors.brutalistCell(
                    color: const Color(0xFFD1FAE5),
                    borderWidth: 1.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'GANANCIA',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 8,
                          color: Color(0xFF065F46),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '+${order.projectedProfitUsdt.toStringAsFixed(2)} USDT',
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF047857),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          if (order.notes.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              order.notes,
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],

          if (order.archivedAt != null) ...[
            const SizedBox(height: 4),
            Text(
              '📦 Archivado el: ${order.archivedAt}',
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 9,
                color: AppColors.textMuted,
              ),
            ),
          ],

          const SizedBox(height: 10),

          // Botones de Acción
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    SentinelAutoScanner.instance.unarchiveOrder(order.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: AppColors.ink,
                        content: Text(
                          '🔄 Orden ${order.displaySymbol} restaurada al Dashboard',
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
                    height: 34,
                    decoration: AppColors.brutalistBox(
                      color: AppColors.gold,
                      borderWidth: 1.5,
                      shadowOffset: 2.5,
                    ),
                    child: const Center(
                      child: Text(
                        '🔄 RESTAURAR AL DASHBOARD',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  SentinelAutoScanner.instance.deleteArchivedOrder(order.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: AppColors.ink,
                      content: Text(
                        '🗑️ Orden eliminada del historial',
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          color: Colors.white,
                        ),
                      ),
                    ),
                  );
                },
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: AppColors.brutalistBox(
                    color: AppColors.surfaceLight,
                    borderWidth: 1.5,
                    shadowOffset: 2.5,
                  ),
                  child: const Icon(
                    Icons.delete_outline,
                    size: 16,
                    color: AppColors.orange,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => NativeAlarmService.openBinance(),
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: AppColors.brutalistBox(
                    color: AppColors.orange,
                    borderWidth: 1.5,
                    shadowOffset: 2.5,
                  ),
                  child: const Icon(
                    Icons.rocket_launch,
                    size: 16,
                    color: Colors.white,
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
