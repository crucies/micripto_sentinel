import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/native_alarm_service.dart';
import '../../../../core/services/smc_s_plus_scanner.dart';
import '../../../dashboard/presentation/widgets/macro_regime_widget.dart';
import '../widgets/signal_detail_modal.dart';

class RadarSPlusPage extends StatefulWidget {
  const RadarSPlusPage({super.key});

  @override
  State<RadarSPlusPage> createState() => _RadarSPlusPageState();
}

class _RadarSPlusPageState extends State<RadarSPlusPage> {
  String _selectedCategory = 'TODAS'; // 'CAZA' | 'CARTERA' | 'TODAS'
  String _selectedQuality = 'TODAS';  // 'TODAS' | 'S_PLUS' | 'S' | 'A'
  String _sortBy = 'DATE';            // 'DATE' | 'PROFIT'
  bool _hideExpired = true;           // Ocultar señales no rentables por defecto
  double _defaultTradeAmount = 100.0;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    SmcSPlusScanner.instance.addListener(_onRadarUpdate);
    if (SmcSPlusScanner.instance.radarItems.isEmpty) {
      SmcSPlusScanner.instance.scanAllCoins1H();
    }
  }

  Future<void> _loadPreferences() async {
    final cat = await NativeAlarmService.getSetting('radar_filter_group', defaultValue: 'TODAS');
    final qual = await NativeAlarmService.getSetting('radar_filter_quality', defaultValue: 'TODAS');
    final sort = await NativeAlarmService.getSetting('radar_sort_by', defaultValue: 'DATE');
    final hideExp = await NativeAlarmService.getBoolSetting('radar_hide_expired', defaultValue: true);
    final amt = await NativeAlarmService.getDoubleSetting('default_trade_amount_usdt', defaultValue: 100.0);

    if (mounted) {
      setState(() {
        _selectedCategory = cat;
        _selectedQuality = qual;
        _sortBy = sort;
        _hideExpired = hideExp;
        _defaultTradeAmount = amt > 0 ? amt : 100.0;
      });
    }
  }

  Future<void> _saveCategory(String val) async {
    setState(() => _selectedCategory = val);
    await NativeAlarmService.setSetting('radar_filter_group', val);
  }

  Future<void> _saveQuality(String val) async {
    setState(() => _selectedQuality = val);
    await NativeAlarmService.setSetting('radar_filter_quality', val);
  }

  Future<void> _saveSortBy(String val) async {
    setState(() => _sortBy = val);
    await NativeAlarmService.setSetting('radar_sort_by', val);
  }

  Future<void> _toggleHideExpired() async {
    final next = !_hideExpired;
    setState(() => _hideExpired = next);
    await NativeAlarmService.setBoolSetting('radar_hide_expired', next);
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

  Color _getScoreColor(int score) {
    if (score >= 90) return const Color(0xFF00E5FF); // Celeste S+
    if (score >= 80) return const Color(0xFF10B981); // Verde S
    if (score >= 70) return AppColors.gold;          // Ámbar A
    return const Color(0xFFE5E0D5);                  // Neutro
  }

  Color _getScoreTextColor(int score) {
    if (score >= 80 && score < 90) return Colors.white;
    return AppColors.ink;
  }

  @override
  Widget build(BuildContext context) {
    final scanner = SmcSPlusScanner.instance;
    final allItems = scanner.radarItems;
    final activeSPlusCount = scanner.activeSPlusSignals.length;

    // 1. Filtrar por Grupo de Monedas
    var filtered = allItems.where((item) {
      if (_selectedCategory == 'CAZA') return item.category == 'CAZA';
      if (_selectedCategory == 'CARTERA') return item.category == 'CARTERA';
      return true;
    }).toList();

    // 2. Filtrar por Calidad de Señal
    filtered = filtered.where((item) {
      if (_selectedQuality == 'S_PLUS') return item.confluenceScore >= 90;
      if (_selectedQuality == 'S') return item.confluenceScore >= 80 && item.confluenceScore < 90;
      if (_selectedQuality == 'A') return item.confluenceScore >= 70 && item.confluenceScore < 80;
      return true;
    }).toList();

    // Conteo de expiradas en este subconjunto
    final expiredCount = filtered.where((i) => i.isExpired).length;

    // 3. Ocultar Señales Expiradas (Eliminar Ruido)
    if (_hideExpired) {
      filtered = filtered.where((item) => !item.isExpired).toList();
    }

    // 4. Ordenamiento
    if (_sortBy == 'DATE') {
      filtered.sort((a, b) => b.detectedAt.compareTo(a.detectedAt));
    } else if (_sortBy == 'PROFIT') {
      filtered.sort((a, b) {
        final profA = a.expectedProfitUsdt(_defaultTradeAmount, isTp2: true);
        final profB = b.expectedProfitUsdt(_defaultTradeAmount, isTp2: true);
        return profB.compareTo(profA);
      });
    }

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
                      '⚡ RADAR',
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
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Banner de Estado
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: AppColors.brutalistBox(
                color: AppColors.ink,
                borderWidth: 3.0,
                shadowOffset: 4.5,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          color: const Color(0xFF00E5FF),
                          child: const Text(
                            'SMART ENGINE 2.2 • 92.3% WR',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.w900,
                              fontSize: 10,
                              color: AppColors.ink,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        color: AppColors.ink,
                        child: Text(
                          'Scan: ${scanner.lastRadarScanTime}',
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                            color: AppColors.gold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Base de Cálculo: \$${_defaultTradeAmount.toStringAsFixed(0)} USDT por posición. Toca cualquier tarjeta para abrir su modal de análisis en vivo.',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildLegendBadge('S+ >=90%', const Color(0xFF00E5FF), AppColors.ink),
                      const SizedBox(width: 6),
                      _buildLegendBadge('S 80-89%', const Color(0xFF10B981), Colors.white),
                      const SizedBox(width: 6),
                      _buildLegendBadge('A 70-79%', AppColors.gold, AppColors.ink),
                      const Spacer(),
                      Text(
                        activeSPlusCount > 0 ? '🔥 $activeSPlusCount S+ ACTIVA' : '0 S+ AHORA',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.w900,
                          fontSize: 10,
                          color: activeSPlusCount > 0 ? const Color(0xFF00E5FF) : AppColors.gold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Semáforo de Régimen Macro BTC
            const MacroRegimeWidget(),

            const SizedBox(height: 14),

            // 1. Selector de Grupo de Monedas (Caza vs Cartera vs Todas)
            Container(
              padding: const EdgeInsets.all(4),
              decoration: AppColors.brutalistBox(
                color: AppColors.surface,
                borderWidth: 2.0,
                shadowOffset: 3.0,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildGroupTab('🎯 CAZA (33)', 'CAZA', const Color(0xFF00E5FF)),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: _buildGroupTab('💼 CARTERA (11)', 'CARTERA', AppColors.gold),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: _buildGroupTab('🌐 TODAS (44)', 'TODAS', const Color(0xFF10B981)),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // 2. Selector de Calidad de Señal (S+ >90%, S 80-89%, A 70-79%, Todas)
            Container(
              padding: const EdgeInsets.all(4),
              decoration: AppColors.brutalistBox(
                color: AppColors.surface,
                borderWidth: 2.0,
                shadowOffset: 3.0,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildQualityTab('TODAS', 'TODAS', AppColors.ink, Colors.white),
                  ),
                  const SizedBox(width: 3),
                  Expanded(
                    child: _buildQualityTab('⭐ S+ (>90%)', 'S_PLUS', const Color(0xFF00E5FF), AppColors.ink),
                  ),
                  const SizedBox(width: 3),
                  Expanded(
                    child: _buildQualityTab('🟢 S (80%)', 'S', const Color(0xFF10B981), Colors.white),
                  ),
                  const SizedBox(width: 3),
                  Expanded(
                    child: _buildQualityTab('🟡 A (70%)', 'A', AppColors.gold, AppColors.ink),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // 3. Fila de Ordenamiento y Filtro de Expiradas
            Row(
              children: [
                // Ordenar por
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      border: Border.all(color: AppColors.ink, width: 1.5),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'ORDEN:',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.w900,
                            fontSize: 9,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _saveSortBy(_sortBy == 'DATE' ? 'PROFIT' : 'DATE'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            color: AppColors.ink,
                            child: Text(
                              _sortBy == 'DATE' ? '⏱️ RECIENTES' : '💰 GANANCIA TP2',
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.w900,
                                fontSize: 9,
                                color: AppColors.gold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Toggle Ocultar Expiradas (Eliminar Ruido)
                GestureDetector(
                  onTap: _toggleHideExpired,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      color: _hideExpired ? AppColors.ink : Colors.white,
                      border: Border.all(color: AppColors.ink, width: 1.5),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _hideExpired ? Icons.visibility_off : Icons.visibility,
                          size: 13,
                          color: _hideExpired ? const Color(0xFF00E5FF) : AppColors.ink,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _hideExpired
                              ? 'SIN RUIDO ($expiredCount OCULTAS)'
                              : 'VER EXPIRADAS ($expiredCount)',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.w900,
                            fontSize: 9,
                            color: _hideExpired ? Colors.white : AppColors.ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Banner Táctico: Auditoría Adversarial Vigente (2x al día: 10:30 y 22:00 BOT)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: AppColors.brutalistBox(
                color: const Color(0xFFE0FCFF),
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
                        children: const [
                          Text('🛡️ ', style: TextStyle(fontSize: 14)),
                          Text(
                            'AUDITORÍA ADVERSARIAL VIGENTE',
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
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        color: AppColors.ink,
                        child: const Text(
                          '2x AL DÍA',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 8.5,
                            fontWeight: FontWeight.w900,
                            color: AppColors.gold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${scanner.adversarialSessionName} • ${scanner.adversarialApprovedCount} Aprobadas S+',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w900,
                      fontSize: 11.5,
                      color: Color(0xFF006064),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Próxima Sesión: ${scanner.adversarialNextSession} | Cero Tokens en Segundo Plano',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),

            // Lista de Tarjetas de Señal
            if (filtered.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(28),
                decoration: AppColors.brutalistBox(
                  color: AppColors.surface,
                  borderWidth: 2.5,
                  shadowOffset: 4.0,
                ),
                child: Center(
                  child: Column(
                    children: [
                      const Icon(Icons.radar, size: 36, color: AppColors.textSecondary),
                      const SizedBox(height: 10),
                      Text(
                        'Sin señales para el filtro seleccionado ($_selectedCategory • $_selectedQuality).',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: AppColors.ink,
                        ),
                      ),
                      if (_hideExpired && expiredCount > 0) ...[
                        const SizedBox(height: 6),
                        GestureDetector(
                          onTap: _toggleHideExpired,
                          child: Text(
                            'Hay $expiredCount señales expiradas ocultas. Toca aquí para verlas.',
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                              color: Color(0xFFFF5500),
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              )
            else
              ...filtered.map((item) => _buildCoinRadarCard(item)),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupTab(String label, String categoryKey, Color activeColor) {
    final isSelected = _selectedCategory == categoryKey;
    return GestureDetector(
      onTap: () => _saveCategory(categoryKey),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : Colors.transparent,
          border: Border.all(
            color: isSelected ? AppColors.ink : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontWeight: FontWeight.w900,
              fontSize: 10,
              color: AppColors.ink,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQualityTab(String label, String qualityKey, Color bg, Color fg) {
    final isSelected = _selectedQuality == qualityKey;
    return GestureDetector(
      onTap: () => _saveQuality(qualityKey),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? bg : Colors.transparent,
          border: Border.all(
            color: isSelected ? AppColors.ink : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'monospace',
              fontWeight: FontWeight.w900,
              fontSize: 9,
              color: isSelected ? fg : AppColors.ink,
            ),
          ),
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
    final profitTp1 = item.expectedProfitUsdt(_defaultTradeAmount, isTp2: false);
    final profitTp2 = item.expectedProfitUsdt(_defaultTradeAmount, isTp2: true);
    final dateStr = DateFormat('yyyy-MM-dd HH:mm').format(item.detectedAt);

    return GestureDetector(
      onTap: () {
        SignalDetailModal.show(
          context,
          item: item,
          defaultTradeAmount: _defaultTradeAmount,
        );
      },
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(13),
        decoration: AppColors.brutalistBox(
          color: item.confluenceScore >= 90
              ? const Color(0xFFE0FCFF) // Celeste S+
              : item.confluenceScore >= 80
                  ? const Color(0xFFEAF9F1) // Verde S
                  : item.confluenceScore >= 70
                      ? const Color(0xFFFFF9E6) // Amarillo A
                      : AppColors.surface,
          borderWidth: item.confluenceScore >= 90 ? 3.0 : 2.5,
          shadowOffset: 4.0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Cabecera: Moneda + Categoría + Precio + Badge de Score
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
                    const SizedBox(width: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: item.category == 'CARTERA' ? AppColors.gold : const Color(0xFF00E5FF),
                        border: Border.all(color: AppColors.ink, width: 1.0),
                      ),
                      child: Text(
                        item.category == 'CARTERA' ? 'CARTERA' : 'CAZA',
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.w900,
                          fontSize: 8,
                          color: AppColors.ink,
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
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
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

            const SizedBox(height: 6),

            // Badge de Auditoría Adversarial de la Sesión
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: AppColors.brutalistCell(
                    color: item.adversarialVerdict.contains('APROBADA')
                        ? const Color(0xFF00E5FF)
                        : (item.adversarialVerdict.contains('ZONA') ? const Color(0xFF10B981) : const Color(0xFFEF4444)),
                    borderWidth: 1.2,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(item.adversarialVerdict.contains('APROBADA') ? '🛡️ ' : (item.adversarialVerdict.contains('ZONA') ? '🟢 ' : '⛔ '),
                          style: const TextStyle(fontSize: 9)),
                      Text(
                        '${item.adversarialVerdict} (${item.adversarialScore}%)',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 8.5,
                          fontWeight: FontWeight.w900,
                          color: item.adversarialVerdict.contains('VETO') ? Colors.white : AppColors.ink,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    item.adversarialSession,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 8.5,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 6),

            // Fecha/Hora de Adición y Estado de Entrada
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '📅 $dateStr',
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                    fontSize: 9,
                    color: AppColors.textSecondary,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: item.isExpired ? const Color(0xFFFF5500).withValues(alpha: 0.15) : const Color(0xFF10B981).withValues(alpha: 0.15),
                    border: Border.all(
                      color: item.isExpired ? const Color(0xFFFF5500) : const Color(0xFF10B981),
                      width: 1.0,
                    ),
                  ),
                  child: Text(
                    item.isExpired ? 'PUNTO PERDIDO' : 'PUNTO VIGENTE ✅',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w900,
                      fontSize: 8,
                      color: item.isExpired ? const Color(0xFFFF5500) : const Color(0xFF0A7550),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Ganancia Proyectada Calculada con Monto de Ajustes
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: AppColors.ink, width: 1.5),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.trending_up, size: 14, color: Color(0xFF10B981)),
                      const SizedBox(width: 4),
                      Text(
                        'TP1: +\$${profitTp1.toStringAsFixed(2)} (+3%)',
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.w900,
                          fontSize: 10,
                          color: Color(0xFF0A7550),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'TP2: +\$${profitTp2.toStringAsFixed(2)} USDT (+5.5%)',
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

            const SizedBox(height: 6),

            // Motivo / Explicación
            Text(
              item.statusReason,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontWeight: FontWeight.bold,
                fontSize: 10,
                color: AppColors.textSecondary,
              ),
            ),

            const SizedBox(height: 8),

            // Indicador Táctil para Abrir Modal
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 4),
              color: AppColors.ink.withValues(alpha: 0.06),
              child: const Center(
                child: Text(
                  '👉 TOCA PARA ANALIZAR ENTRADA EN VIVO Y RECALCULAR',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w900,
                    fontSize: 8.5,
                    color: AppColors.ink,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
