import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/macro_regime_service.dart';

class MacroRegimeWidget extends StatelessWidget {
  const MacroRegimeWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: MacroRegimeService.instance,
      builder: (context, _) {
        final service = MacroRegimeService.instance;
        final state = service.regimeState;

        Color bg;
        Color accent;
        Color textCol;
        IconData icon;

        switch (state) {
          case MacroRegimeState.hunt:
            bg = const Color(0xFFE8F5E9);
            accent = const Color(0xFF10B981);
            textCol = const Color(0xFF1B5E20);
            icon = Icons.radar;
            break;
          case MacroRegimeState.defensive:
            bg = const Color(0xFFFFF9C4);
            accent = const Color(0xFFFFB300);
            textCol = const Color(0xFFE65100);
            icon = Icons.shield_outlined;
            break;
          case MacroRegimeState.refuge:
            bg = const Color(0xFFFFEBEE);
            accent = const Color(0xFFD32F2F);
            textCol = const Color(0xFFB71C1C);
            icon = Icons.gpp_bad_outlined;
            break;
        }

        return Container(
          width: double.infinity,
          decoration: AppColors.brutalistBox(
            color: bg,
            borderWidth: 2.5,
            shadowOffset: 4.0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Barra de Título del Semáforo
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: accent,
                  border: const Border(
                    bottom: BorderSide(color: AppColors.ink, width: 2.5),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(icon, size: 16, color: Colors.white),
                        const SizedBox(width: 8),
                        Text(
                          service.regimeName,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.w900,
                            fontSize: 11,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Text(
                          'ACT: ${service.lastUpdate}',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 9.5,
                            fontWeight: FontWeight.bold,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: () => service.refreshRegime(),
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: AppColors.brutalistCell(
                              color: Colors.white,
                              borderWidth: 1.0,
                            ),
                            child: Icon(
                              Icons.refresh,
                              size: 13,
                              color: textCol,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // 2. Métricas Clave de Bitcoin 4H
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // Precio BTC
                        Expanded(
                          flex: 3,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: AppColors.brutalistCell(
                              color: Colors.white,
                              borderWidth: 1.5,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'BITCOIN (4H)',
                                  style: TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  service.btcPrice > 0
                                      ? '\$${service.btcPrice.toStringAsFixed(0)}'
                                      : 'Conectando...',
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                    fontWeight: FontWeight.w900,
                                    fontSize: 14,
                                    color: AppColors.ink,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // RSI 4H
                        Expanded(
                          flex: 2,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: AppColors.brutalistCell(
                              color: Colors.white,
                              borderWidth: 1.5,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'RSI 4H',
                                  style: TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  service.btcRsi4h.toStringAsFixed(1),
                                  style: TextStyle(
                                    fontFamily: 'monospace',
                                    fontWeight: FontWeight.w900,
                                    fontSize: 14,
                                    color: service.btcRsi4h < 45
                                        ? const Color(0xFFD32F2F)
                                        : (service.btcRsi4h > 55 ? const Color(0xFF2E7D32) : AppColors.ink),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Caída 48h
                        Expanded(
                          flex: 2,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: AppColors.brutalistCell(
                              color: Colors.white,
                              borderWidth: 1.5,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '48H MAX',
                                  style: TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '-${service.btcDropFromHighPct.toStringAsFixed(1)}%',
                                  style: TextStyle(
                                    fontFamily: 'monospace',
                                    fontWeight: FontWeight.w900,
                                    fontSize: 14,
                                    color: service.btcDropFromHighPct >= 4.0
                                        ? const Color(0xFFD32F2F)
                                        : AppColors.ink,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // Directriz Operativa de Kai
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: AppColors.brutalistCell(
                        color: Colors.white,
                        borderWidth: 1.5,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            service.isBuyAllowed ? Icons.verified : Icons.lock_clock,
                            size: 16,
                            color: textCol,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              service.regimeDirective,
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: textCol,
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
