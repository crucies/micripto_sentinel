import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';

class KaiBriefingModal extends StatelessWidget {
  final Map<String, dynamic> alert;

  const KaiBriefingModal({super.key, required this.alert});

  static void show(BuildContext context, Map<String, dynamic> alert) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      builder: (_) => KaiBriefingModal(alert: alert),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = alert['title']?.toString() ?? 'INFORME TÁCTICO KAI (3H)';
    final hero = alert['hero']?.toString() ?? 'PORTAFOLIO • 17 ÓRDENES ACTIVAS';
    final timestamp = alert['timestamp']?.toString() ?? '07/11/26 • 07:30 BOT';
    final summary = alert['summary']?.toString() ?? 'Vigilancia activa de mercado.';
    final action = alert['action']?.toString() ?? 'Mantener posiciones sin cambios.';

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Container(
            padding: const EdgeInsets.all(18),
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
                  // 1. Header Brutalista
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
                        child: Text(
                          '🧠 $title',
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.w900,
                            fontSize: 11,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: AppColors.ink),
                        onPressed: () => Navigator.of(context).pop(),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // 2. Timestamp
                  Text(
                    'Hora del Análisis: $timestamp',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // 3. Título Hero
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: AppColors.brutalistCell(
                      color: AppColors.gold,
                      borderWidth: 2.0,
                    ),
                    child: Text(
                      hero,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 4. Resumen Situacional
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: AppColors.brutalistCell(
                      color: Colors.white,
                      borderWidth: 2.0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '📊 RESUMEN CUANTITATIVO',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.w900,
                            fontSize: 11,
                            color: AppColors.ink,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          summary,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11,
                            height: 1.4,
                            color: AppColors.ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // 5. Acción Estratégica
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: AppColors.brutalistCell(
                      color: const Color(0xFFFEF3C7),
                      borderWidth: 2.0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '⚡ RECOMENDACIÓN TÁCTICA',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.w900,
                            fontSize: 11,
                            color: Color(0xFF78350F),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          action,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            height: 1.4,
                            color: AppColors.ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 6. Botones de Acción
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final uri = Uri.parse('https://www.binance.com/en/trade/NEAR_USDT');
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri, mode: LaunchMode.externalApplication);
                            }
                          },
                          child: Container(
                            height: 44,
                            alignment: Alignment.center,
                            decoration: AppColors.brutalistBox(
                              color: AppColors.orange,
                              borderWidth: 2.0,
                              shadowOffset: 3.0,
                            ),
                            child: const Text(
                              '🚀 ABRIR BINANCE',
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.w900,
                                fontSize: 11,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          height: 44,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          alignment: Alignment.center,
                          decoration: AppColors.brutalistBox(
                            color: Colors.white,
                            borderWidth: 2.0,
                            shadowOffset: 3.0,
                          ),
                          child: const Text(
                            '✅ ENTENDIDO',
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.w900,
                              fontSize: 11,
                              color: AppColors.ink,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Center(
                    child: Text(
                      'ALIANZA RICHARD & KAI • CENTINELA MILITAR',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                        fontSize: 8.5,
                        color: Color(0xFF78350F),
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
}
