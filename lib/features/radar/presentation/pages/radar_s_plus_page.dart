import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/native_alarm_service.dart';
import '../../../../core/services/smc_s_plus_scanner.dart';

class RadarSPlusPage extends StatefulWidget {
  const RadarSPlusPage({super.key});

  @override
  State<RadarSPlusPage> createState() => _RadarSPlusPageState();
}

class _RadarSPlusPageState extends State<RadarSPlusPage> {
  @override
  void initState() {
    super.initState();
    SmcSPlusScanner.instance.addListener(_onRadarUpdate);
    if (SmcSPlusScanner.instance.radarItems.isEmpty) {
      SmcSPlusScanner.instance.scanAllCoins1H();
    }
  }

  void _onRadarUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    SmcSPlusScanner.instance.removeListener(_onRadarUpdate);
    super.dispose();
  }

  String _fmt(double p) {
    if (p >= 100) return p.toStringAsFixed(2);
    return p.toStringAsFixed(4);
  }

  /// Jerarquía Cromática Oficial Estricta:
  /// - >= 90% (S+): Exclusivamente Celeste / Turquesa (#00E5FF)
  /// - 80-89% (S): Verde Esmeralda (#10B981)
  /// - 70-79% (A): Ámbar / Oro (#FFD600)
  /// - < 70% (B): Neutro (#E5E0D5)
  Color _getScoreColor(int score) {
    if (score >= 90) return const Color(0xFF00E5FF); // Celeste / Turquesa exclusivo S+
    if (score >= 80) return const Color(0xFF10B981); // Verde Esmeralda S
    if (score >= 70) return AppColors.gold;          // Ámbar / Oro A
    return const Color(0xFFE5E0D5);                  // Neutro
  }

  Color _getScoreTextColor(int score) {
    if (score >= 80 && score < 90) return Colors.white;
    return AppColors.ink;
  }

  void _testSPlusLockscreenAlarm(SPlusCoinRadarItem item) {
    NativeAlarmService.scheduleTestAlarm(
      delaySeconds: 5,
      eventType: 'S_PLUS_ALPHA',
      symbol: '${item.displaySymbol} / USDT (S+ ${item.confluenceScore >= 90 ? item.confluenceScore : 94}%)',
      price: '\$${_fmt(item.currentPrice)}',
      amount: 'SUELO 1H: \$${_fmt(item.nearestFloorPrice)} (-${item.dropFrom48hHighPct.toStringAsFixed(1)}% 48h)',
      targetPrice: 'TP1: \$${_fmt(item.tp1Price)} | TP2: \$${_fmt(item.tp2Price)}',
      projectedProfit: 'OCO SL Trigger: \$${_fmt(item.slTriggerPrice)} (-2.8%) | Limit: \$${_fmt(item.slLimitPrice)}',
      totalProfit: '92.3% WIN RATE (S+)',
      liquidCash: '\$0.91 USDT',
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: AppColors.ink,
        duration: Duration(seconds: 4),
        content: Text(
          '⚡ Alarma S+ programada en 5s. ¡Bloquea tu teléfono ahora para ver la Ficha OCO en bloqueo!',
          style: TextStyle(
            fontFamily: 'monospace',
            fontWeight: FontWeight.bold,
            fontSize: 11,
            color: Color(0xFF00E5FF),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scanner = SmcSPlusScanner.instance;
    final items = scanner.radarItems;
    final activeSPlusCount = scanner.activeSPlusSignals.length;

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
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: AppColors.brutalistBox(
                      color: const Color(0xFF00E5FF),
                      borderWidth: 2.5,
                      shadowOffset: 3.0,
                    ),
                    child: const Text(
                      '⚡ RADAR SUELOS S+ (1H)',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                        color: AppColors.ink,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => scanner.scanAllCoins1H(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: AppColors.brutalistBox(
                        color: AppColors.surface,
                        borderWidth: 2.0,
                        shadowOffset: 3.0,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            scanner.isScanning ? Icons.hourglass_top : Icons.radar,
                            color: AppColors.ink,
                            size: 15,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            scanner.isScanning ? 'ESCANEANDO...' : 'ESCANEAR 1H',
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.w900,
                              fontSize: 10,
                              color: AppColors.ink,
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(22, 18, 22, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Hero Card Smart Engine 2.2 (92.3% Win Rate)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: AppColors.brutalistBox(
                color: AppColors.ink,
                borderWidth: 3.0,
                shadowOffset: 5.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        color: const Color(0xFF00E5FF),
                        child: const Text(
                          'SMART ENGINE 2.2 • 92.3% WIN RATE',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.w900,
                            fontSize: 10,
                            color: AppColors.ink,
                          ),
                        ),
                      ),
                      Text(
                        'Scan: ${scanner.lastRadarScanTime}',
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                          color: AppColors.gold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Vigilancia autónoma cada 3 min (incluso con pantalla bloqueada) sobre estructura 1H de Binance. Sin depender de Vercel.',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Leyenda de Colores Oficiales
                  Row(
                    children: [
                      _buildLegendBadge('S+ >=90%', const Color(0xFF00E5FF), AppColors.ink),
                      const SizedBox(width: 6),
                      _buildLegendBadge('S 80-89%', const Color(0xFF10B981), Colors.white),
                      const SizedBox(width: 6),
                      _buildLegendBadge('A 70-79%', AppColors.gold, AppColors.ink),
                      const Spacer(),
                      Text(
                        activeSPlusCount > 0
                            ? '🔥 $activeSPlusCount S+ ACTIVA'
                            : '0 S+ AHORA',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.w900,
                          fontSize: 10,
                          color: activeSPlusCount > 0
                              ? const Color(0xFF00E5FF)
                              : AppColors.gold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            if (items.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: AppColors.brutalistBox(
                  color: AppColors.surface,
                  borderWidth: 2.5,
                  shadowOffset: 4.0,
                ),
                child: const Center(
                  child: Text(
                    'Analizando 10 pares institucionales en 1H directo desde Binance...',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: AppColors.ink,
                    ),
                  ),
                ),
              )
            else
              ...items.map((item) => _buildCoinRadarCard(item)),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendBadge(String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: Colors.white, width: 1.0),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'monospace',
          fontWeight: FontWeight.w900,
          fontSize: 9,
          color: fg,
        ),
      ),
    );
  }

  Widget _buildCoinRadarCard(SPlusCoinRadarItem item) {
    final badgeBg = _getScoreColor(item.confluenceScore);
    final badgeFg = _getScoreTextColor(item.confluenceScore);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: AppColors.brutalistBox(
        color: item.confluenceScore >= 90
            ? const Color(0xFFE0FCFF)
            : AppColors.surface,
        borderWidth: item.confluenceScore >= 90 ? 3.0 : 2.5,
        shadowOffset: 4.5,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Cabecera: Moneda + Precio + Score con color estricto
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    color: AppColors.ink,
                    child: Text(
                      item.displaySymbol,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '\$${_fmt(item.currentPrice)}',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      color: AppColors.ink,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: AppColors.brutalistCell(
                  color: badgeBg,
                  borderWidth: 2.0,
                ),
                child: Text(
                  '${item.grade} • ${item.confluenceScore}%',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                    color: badgeFg,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Estado de la estructura 1H
          Text(
            item.statusReason,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontWeight: FontWeight.bold,
              fontSize: 10,
              color: AppColors.textSecondary,
            ),
          ),

          const SizedBox(height: 10),

          // 2. Grilla de los 4 Pilares Cuantitativos S+
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _buildPillarChip('1. Suelo 2do Toque', item.hasUnbroken2ndTouchSweep),
              _buildPillarChip(
                '2. Desc 48h (-${item.dropFrom48hHighPct.toStringAsFixed(1)}%)',
                item.hasRealDiscount48h,
              ),
              _buildPillarChip('3. Vela CHoCH', item.hasEngulfingChoch),
              _buildPillarChip(
                '4. RSI 1H (${item.currentRsi.toStringAsFixed(0)})',
                item.hasRsiDivergence,
              ),
            ],
          ),

          const SizedBox(height: 10),

          // 3. Ficha Táctica de Niveles (Suelo 1H + TP1/TP2 + OCO Stop Loss)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: AppColors.brutalistCell(
              color: AppColors.surfaceLight,
              borderWidth: 2.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'SUELO 1H: \$${_fmt(item.nearestFloorPrice)}',
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w900,
                        fontSize: 10,
                        color: AppColors.ink,
                      ),
                    ),
                    Text(
                      'Dist: ${item.distanceToFloorPct >= 0 ? '+' : ''}${item.distanceToFloorPct.toStringAsFixed(2)}%',
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                        color: AppColors.orange,
                      ),
                    ),
                  ],
                ),
                const Divider(color: AppColors.ink, thickness: 1.2, height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '🛡️ TP1 (+3%): \$${_fmt(item.tp1Price)}',
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.w900,
                          fontSize: 10,
                          color: Color(0xFF047857),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        '🚀 TP2 (+5.5%): \$${_fmt(item.tp2Price)}',
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.w900,
                          fontSize: 10,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '🛑 OCO Trigger: \$${_fmt(item.slTriggerPrice)}',
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                          color: Color(0xFFB91C1C),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        '📉 OCO Limit: \$${_fmt(item.slLimitPrice)}',
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                          color: Color(0xFFB91C1C),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // 4. Botones de Acción (Simular Alarma S+ en bloqueo 5s + Abrir Binance)
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _testSPlusLockscreenAlarm(item),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: AppColors.brutalistCell(
                      color: const Color(0xFF00E5FF),
                      borderWidth: 2.0,
                    ),
                    child: const Center(
                      child: Text(
                        '🔔 PROBAR ALARMA S+ (5s)',
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
              const SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  onTap: () => NativeAlarmService.openBinance(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: AppColors.brutalistCell(
                      color: AppColors.gold,
                      borderWidth: 2.0,
                    ),
                    child: const Center(
                      child: Text(
                        '🚀 ABRIR BINANCE',
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

  Widget _buildPillarChip(String label, bool active) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: active ? const Color(0xFFD1FAE5) : AppColors.surfaceLight,
        border: Border.all(
          color: AppColors.ink,
          width: 1.5,
        ),
      ),
      child: Text(
        '${active ? '✓' : '○'} $label',
        style: TextStyle(
          fontFamily: 'monospace',
          fontWeight: FontWeight.w900,
          fontSize: 9,
          color: active ? const Color(0xFF065F46) : AppColors.textMuted,
        ),
      ),
    );
  }
}
