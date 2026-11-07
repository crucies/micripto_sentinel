import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/native_alarm_service.dart';
import '../../../../core/services/smc_s_plus_scanner.dart';

class SignalDetailModal extends StatefulWidget {
  final SPlusCoinRadarItem item;
  final double defaultTradeAmount;

  const SignalDetailModal({
    super.key,
    required this.item,
    this.defaultTradeAmount = 100.0,
  });

  static Future<void> show(
    BuildContext context, {
    required SPlusCoinRadarItem item,
    double defaultTradeAmount = 100.0,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SignalDetailModal(
        item: item,
        defaultTradeAmount: defaultTradeAmount,
      ),
    );
  }

  @override
  State<SignalDetailModal> createState() => _SignalDetailModalState();
}

class _SignalDetailModalState extends State<SignalDetailModal> {
  late TextEditingController _amountController;
  late double _currentTradeAmount;
  double? _livePrice;
  bool _isAnalyzing = false;
  String? _analysisVerdict;
  Color _verdictBgColor = AppColors.gold;
  Color _verdictTextColor = AppColors.ink;
  String? _analysisDetail;

  @override
  void initState() {
    super.initState();
    _currentTradeAmount = widget.defaultTradeAmount > 0 ? widget.defaultTradeAmount : 100.0;
    _amountController = TextEditingController(text: _currentTradeAmount.toStringAsFixed(0));
    _livePrice = widget.item.currentPrice;
    _analyzeLivePrice(widget.item.currentPrice);
    _fetchFreshPriceFromBinance();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  String _fmt(double p) {
    if (p >= 100) return p.toStringAsFixed(2);
    return p.toStringAsFixed(4);
  }

  Color _getScoreColor(int score) {
    if (score >= 90) return const Color(0xFF00E5FF);
    if (score >= 80) return const Color(0xFF10B981);
    if (score >= 70) return AppColors.gold;
    return const Color(0xFFE5E0D5);
  }

  Future<void> _fetchFreshPriceFromBinance() async {
    setState(() => _isAnalyzing = true);
    try {
      final uri = Uri.parse('https://api.binance.com/api/v3/ticker/price?symbol=${widget.item.symbol}');
      final res = await http.get(uri).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final p = double.tryParse(data['price']?.toString() ?? '');
        if (p != null && p > 0 && mounted) {
          setState(() {
            _livePrice = p;
          });
          _analyzeLivePrice(p);
        }
      }
    } catch (_) {
      // Fallback a precio guardado
      if (mounted) _analyzeLivePrice(_livePrice ?? widget.item.currentPrice);
    } finally {
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }

  void _analyzeLivePrice(double price) {
    final entry = widget.item.entryPrice > 0 ? widget.item.entryPrice : widget.item.nearestFloorPrice;
    final tp1 = widget.item.tp1Price;
    final sl = widget.item.slTriggerPrice;
    final driftPct = entry > 0 ? ((price - entry) / entry) * 100.0 : 0.0;

    if (price >= tp1) {
      _analysisVerdict = '🛑 NO ENTRAR — TP1 ALCANZADO';
      _verdictBgColor = const Color(0xFFFF5500);
      _verdictTextColor = Colors.white;
      _analysisDetail = 'El precio tocó \$${_fmt(tp1)} (+3.0%). La ganancia ya se dio, entrar ahora es perseguir el precio con alto riesgo.';
    } else if (price <= sl) {
      _analysisVerdict = '🛑 NO ENTRAR — STOP LOSS PERFORADO';
      _verdictBgColor = const Color(0xFFFF5500);
      _verdictTextColor = Colors.white;
      _analysisDetail = 'El precio perforó el soporte en \$${_fmt(sl)} (-2.8%). La estructura alcista fue invalidada por los institucionales.';
    } else if (driftPct > 1.8) {
      _analysisVerdict = '⚠️ ENTRADA TARDÍA — RIESGO ELEVADO';
      _verdictBgColor = AppColors.gold;
      _verdictTextColor = AppColors.ink;
      _analysisDetail = 'El precio ya subió +${driftPct.toStringAsFixed(1)}% del suelo fractal. El margen restante de beneficio es inferior al riesgo asumido.';
    } else if (driftPct > 0.8) {
      _analysisVerdict = '🟡 ENTRADA VIABLE (PRECAUCIÓN)';
      _verdictBgColor = AppColors.gold;
      _verdictTextColor = AppColors.ink;
      _analysisDetail = 'Avanzó +${driftPct.toStringAsFixed(1)}% desde el gatillo. Aún es viable colocando una orden límite cercana a \$${_fmt(entry)}.';
    } else {
      _analysisVerdict = '✅ EXCELENTE PUNTO DE ENTRADA';
      _verdictBgColor = const Color(0xFF10B981);
      _verdictTextColor = Colors.white;
      _analysisDetail = 'El precio (\$${_fmt(price)}) se ubica en pleno suelo fractal (\$${_fmt(entry)}). Relación R:R óptima de 1:1.96.';
    }
  }

  void _recalculateAmount() {
    final parsed = double.tryParse(_amountController.text.trim());
    if (parsed != null && parsed > 0) {
      setState(() {
        _currentTradeAmount = parsed;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.ink,
          duration: const Duration(seconds: 2),
          content: Text(
            '🔄 Proyección recalculada para \$${_currentTradeAmount.toStringAsFixed(2)} USDT',
            style: const TextStyle(
              fontFamily: 'monospace',
              fontWeight: FontWeight.bold,
              fontSize: 11,
              color: Color(0xFF00E5FF),
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final scoreColor = _getScoreColor(item.confluenceScore);
    final p = _livePrice ?? item.currentPrice;
    final entry = item.entryPrice > 0 ? item.entryPrice : item.nearestFloorPrice;
    final driftPct = entry > 0 ? ((p - entry) / entry) * 100.0 : 0.0;
    // Ponderación exacta 50/50 Dual-TP de la página web (smcEngine / SignalsList.tsx)
    // Lote 1: 50% del capital en TP1 (+3.0%)
    // Lote 2: 50% del capital en TP2 (+5.5%)
    final tp1DistancePct = item.entryPrice > 0 ? ((item.tp1Price - item.entryPrice) / item.entryPrice) * 100.0 : 3.0;
    final tp2DistancePct = item.entryPrice > 0 ? ((item.tp2Price - item.entryPrice) / item.entryPrice) * 100.0 : 5.5;
    final slDistancePct = item.entryPrice > 0 ? ((item.entryPrice - item.slTriggerPrice) / item.entryPrice) * 100.0 : 2.8;

    final profitTp1 = (_currentTradeAmount * 0.5) * (tp1DistancePct / 100.0);
    final profitTp2 = (_currentTradeAmount * 0.5) * (tp2DistancePct / 100.0);
    final totalDualProfit = profitTp1 + profitTp2;
    final lossSl = _currentTradeAmount * (slDistancePct / 100.0);

    final dateStr = DateFormat('yyyy-MM-dd HH:mm:ss').format(item.detectedAt);

    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.50,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.background,
            border: Border(
              top: BorderSide(color: AppColors.ink, width: 4.0),
              left: BorderSide(color: AppColors.ink, width: 4.0),
              right: BorderSide(color: AppColors.ink, width: 4.0),
            ),
          ),
          child: Column(
            children: [
              // Barra de Arrastre Superior
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 10, bottom: 4),
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppColors.ink.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2.5),
                  ),
                ),
              ),

              // Cabecera Fija del Modal (Símbolo + Categoría + Botón Cerrar)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 12, 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          color: AppColors.ink,
                          child: Text(
                            '${item.displaySymbol} / USDT',
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: item.category == 'CARTERA' ? AppColors.gold : const Color(0xFF00E5FF),
                            border: Border.all(color: AppColors.ink, width: 1.5),
                          ),
                          child: Text(
                            item.category == 'CARTERA' ? '💼 CARTERA' : '🎯 CAZA',
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
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: AppColors.ink, size: 24),
                    ),
                  ],
                ),
              ),

              // Timestamp Exacto de Adición
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    border: Border.all(color: AppColors.ink, width: 1.5),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.access_time_filled, size: 14, color: AppColors.ink),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Adicionada: $dateStr',
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                            color: AppColors.ink,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        color: scoreColor,
                        child: Text(
                          '${item.grade} • ${item.confluenceScore}%',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.w900,
                            fontSize: 10,
                            color: item.confluenceScore >= 80 && item.confluenceScore < 90 ? Colors.white : AppColors.ink,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Contenido Scrolleable
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 6, 20, 16),
                  children: [
                    // 1. Módulo de Veredicto en Tiempo Real: ¿AÚN ES BUENA IDEA ENTRAR?
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: AppColors.brutalistBox(
                        color: AppColors.surface,
                        borderWidth: 3.0,
                        shadowOffset: 4.0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  'ANÁLISIS DE ENTRADA EN VIVO',
                                  style: TextStyle(
                                    fontFamily: 'monospace',
                                    fontWeight: FontWeight.w900,
                                    fontSize: 11,
                                    color: AppColors.ink,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              GestureDetector(
                                onTap: _isAnalyzing ? null : _fetchFreshPriceFromBinance,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF00E5FF),
                                    border: Border.all(color: AppColors.ink, width: 1.5),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        _isAnalyzing ? Icons.hourglass_top : Icons.refresh,
                                        size: 13,
                                        color: AppColors.ink,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        _isAnalyzing ? 'CONSULTANDO...' : 'RE-ANALIZAR',
                                        style: const TextStyle(
                                          fontFamily: 'monospace',
                                          fontWeight: FontWeight.w900,
                                          fontSize: 9.5,
                                          color: AppColors.ink,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Comparativa de Precios
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Alerta Inicial:',
                                      style: TextStyle(
                                        fontFamily: 'monospace',
                                        fontSize: 10,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    Text(
                                      '\$${_fmt(entry)}',
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
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Precio Binance:',
                                      style: TextStyle(
                                        fontFamily: 'monospace',
                                        fontSize: 10,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    Text(
                                      '\$${_fmt(p)}',
                                      style: TextStyle(
                                        fontFamily: 'monospace',
                                        fontWeight: FontWeight.w900,
                                        fontSize: 14,
                                        color: p >= entry ? const Color(0xFF10B981) : const Color(0xFFFF5500),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Distancia/Drift:',
                                      style: TextStyle(
                                        fontFamily: 'monospace',
                                        fontSize: 10,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    Text(
                                      '${driftPct >= 0 ? '+' : ''}${driftPct.toStringAsFixed(2)}%',
                                      style: TextStyle(
                                        fontFamily: 'monospace',
                                        fontWeight: FontWeight.w900,
                                        fontSize: 14,
                                        color: driftPct <= 0.8 && driftPct >= -0.5
                                            ? const Color(0xFF10B981)
                                            : driftPct > 1.8
                                                ? const Color(0xFFFF5500)
                                                : const Color(0xFFD97706),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          // Caja de Veredicto Táctico (Contraste 100% Garantizado)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: AppColors.ink, width: 2.0),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _verdictBgColor,
                                    border: Border.all(color: AppColors.ink, width: 1.5),
                                  ),
                                  child: Text(
                                    _analysisVerdict ?? 'ANALIZANDO...',
                                    style: TextStyle(
                                      fontFamily: 'monospace',
                                      fontWeight: FontWeight.w900,
                                      fontSize: 11,
                                      color: _verdictTextColor,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _analysisDetail ?? '',
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.ink,
                                    height: 1.35,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Bloque Táctico: Auditoría Adversarial de la Sesión
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: AppColors.brutalistBox(
                        color: const Color(0xFFE0FCFF),
                        borderWidth: 3.0,
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
                                    'AUDITORÍA ADVERSARIAL',
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
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                decoration: AppColors.brutalistCell(
                                  color: widget.item.adversarialVerdict.contains('APROBADA')
                                      ? const Color(0xFF00E5FF)
                                      : (widget.item.adversarialVerdict.contains('ZONA') ? const Color(0xFF10B981) : const Color(0xFFEF4444)),
                                  borderWidth: 1.2,
                                ),
                                child: Text(
                                  '${widget.item.adversarialVerdict} (${widget.item.adversarialScore}%)',
                                  style: TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                    color: widget.item.adversarialVerdict.contains('VETO') ? Colors.white : AppColors.ink,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            widget.item.adversarialSession,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.bold,
                              fontSize: 9.5,
                              color: Color(0xFF004D54),
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Tesis Alpha Scout
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: AppColors.brutalistCell(
                              color: Colors.white,
                              borderWidth: 1.5,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: const [
                                    Text('🐂 ', style: TextStyle(fontSize: 11)),
                                    Text(
                                      'ALPHA SCOUT (TESIS ALCISTA):',
                                      style: TextStyle(
                                        fontFamily: 'monospace',
                                        fontWeight: FontWeight.w900,
                                        fontSize: 9.5,
                                        color: Color(0xFF047857),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                ...widget.item.scoutArguments.map((arg) => Padding(
                                  padding: const EdgeInsets.only(bottom: 2),
                                  child: Text(
                                    '• $arg',
                                    style: const TextStyle(
                                      fontFamily: 'monospace',
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10,
                                      color: AppColors.ink,
                                    ),
                                  ),
                                )),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Ataque Adversary Inquisitor
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: AppColors.brutalistCell(
                              color: Colors.white,
                              borderWidth: 1.5,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: const [
                                    Text('🐻 ', style: TextStyle(fontSize: 11)),
                                    Text(
                                      'INQUISIDOR RED TEAM (PRUEBAS DE ESTRÉS):',
                                      style: TextStyle(
                                        fontFamily: 'monospace',
                                        fontWeight: FontWeight.w900,
                                        fontSize: 9.5,
                                        color: Color(0xFFB91C1C),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                if (widget.item.adversaryAttacks.isEmpty)
                                  const Text(
                                    '• 🛡️ Ninguna objeción crítica. El setup resistió todas las pruebas.',
                                    style: TextStyle(
                                      fontFamily: 'monospace',
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10,
                                      color: Color(0xFF047857),
                                    ),
                                  )
                                else
                                  ...widget.item.adversaryAttacks.map((att) => Padding(
                                    padding: const EdgeInsets.only(bottom: 2),
                                    child: Text(
                                      '• ⚠️ $att',
                                      style: const TextStyle(
                                        fontFamily: 'monospace',
                                        fontWeight: FontWeight.bold,
                                        fontSize: 10,
                                        color: Color(0xFFB91C1C),
                                      ),
                                    ),
                                  )),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Veredicto Juez
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: AppColors.brutalistCell(
                              color: AppColors.surface,
                              borderWidth: 1.5,
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('⚖️ ', style: TextStyle(fontSize: 11)),
                                Expanded(
                                  child: Text(
                                    'Juez Arbiter: ${widget.item.judgeSummary}',
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
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // 2. Calculadora de Ganancia Esperada con Monto Editable
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: AppColors.brutalistBox(
                        color: AppColors.surface,
                        borderWidth: 3.0,
                        shadowOffset: 4.0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'PROYECCIÓN DE GANANCIA',
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.w900,
                              fontSize: 11,
                              color: AppColors.ink,
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Selector y Editor de Monto a Invertir
                          Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: Container(
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    border: Border.all(color: AppColors.ink, width: 2.0),
                                  ),
                                  child: TextField(
                                    controller: _amountController,
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    style: const TextStyle(
                                      fontFamily: 'monospace',
                                      fontWeight: FontWeight.w900,
                                      fontSize: 14,
                                      color: AppColors.ink,
                                    ),
                                    decoration: const InputDecoration(
                                      prefixText: '\$ ',
                                      suffixText: 'USDT',
                                      prefixStyle: TextStyle(
                                        fontFamily: 'monospace',
                                        fontWeight: FontWeight.w900,
                                        color: AppColors.ink,
                                      ),
                                      suffixStyle: TextStyle(
                                        fontFamily: 'monospace',
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                                        color: AppColors.textSecondary,
                                      ),
                                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                      border: InputBorder.none,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 2,
                                child: GestureDetector(
                                  onTap: _recalculateAmount,
                                  child: Container(
                                    height: 42,
                                    decoration: AppColors.brutalistBox(
                                      color: AppColors.gold,
                                      borderWidth: 2.0,
                                      shadowOffset: 2.0,
                                    ),
                                    child: const Center(
                                      child: Text(
                                        '🔄 RECALCULAR',
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

                          const SizedBox(height: 8),

                          // Chips Rápidos de Montos
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [50, 100, 200, 500].map((amt) {
                              return GestureDetector(
                                onTap: () {
                                  _amountController.text = amt.toString();
                                  _recalculateAmount();
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _currentTradeAmount == amt ? AppColors.ink : Colors.white,
                                    border: Border.all(color: AppColors.ink, width: 1.5),
                                  ),
                                  child: Text(
                                    '\$$amt',
                                    style: TextStyle(
                                      fontFamily: 'monospace',
                                      fontWeight: FontWeight.w900,
                                      fontSize: 10,
                                      color: _currentTradeAmount == amt ? Colors.white : AppColors.ink,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),

                          const SizedBox(height: 14),

                          // Fichas de Resultados: TP1, TP2, SL, Ratio (Alto Contraste)
                          Row(
                            children: [
                              Expanded(
                                child: _buildTargetCard(
                                  title: 'TP1 (50% LOTE: +${tp1DistancePct.toStringAsFixed(1)}%)',
                                  targetPrice: '\$${_fmt(item.tp1Price)}',
                                  profitUsdt: '+${profitTp1.toStringAsFixed(2)} USDT',
                                  badgeBg: const Color(0xFF10B981),
                                  badgeTextColor: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildTargetCard(
                                  title: 'TP2 (50% LOTE: +${tp2DistancePct.toStringAsFixed(1)}%)',
                                  targetPrice: '\$${_fmt(item.tp2Price)}',
                                  profitUsdt: '+${profitTp2.toStringAsFixed(2)} USDT',
                                  badgeBg: const Color(0xFF00E5FF),
                                  badgeTextColor: AppColors.ink,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: _buildTargetCard(
                                  title: 'STOP LOSS (-2.8%)',
                                  targetPrice: '\$${_fmt(item.slTriggerPrice)}',
                                  profitUsdt: '-${lossSl.toStringAsFixed(2)} USDT',
                                  badgeBg: const Color(0xFFFF5500),
                                  badgeTextColor: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildTargetCard(
                                  title: 'RATIO RIESGO/BENEFICIO',
                                  targetPrice: '1 : 1.96',
                                  profitUsdt: 'PROB: ${item.confluenceScore}%',
                                  badgeBg: AppColors.gold,
                                  badgeTextColor: AppColors.ink,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: AppColors.brutalistCell(
                              color: AppColors.surfaceLight,
                              borderWidth: 1.5,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  '💰 GANANCIA DUAL-TP PONDERADA:',
                                  style: TextStyle(
                                    fontFamily: 'monospace',
                                    fontWeight: FontWeight.w900,
                                    fontSize: 9.5,
                                    color: AppColors.ink,
                                  ),
                                ),
                                Text(
                                  '+${totalDualProfit.toStringAsFixed(2)} USDT',
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                    fontWeight: FontWeight.w900,
                                    fontSize: 12,
                                    color: AppColors.emerald,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Bloque Táctico: Entrada Escalonada 50/50 & Blindaje Break-Even
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: AppColors.brutalistBox(
                        color: const Color(0xFFE8F5E9),
                        borderWidth: 3.0,
                        shadowOffset: 4.0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Text('🎯 ', style: TextStyle(fontSize: 14)),
                              Text(
                                'ESTRATEGIA SNIPER DCA 50/50 (REGLA INSTITUCIONAL)',
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontWeight: FontWeight.w900,
                                  fontSize: 10.5,
                                  color: Color(0xFF1B5E20),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'En lugar de arriesgar el 100% en el primer toque, divide tu capital (\$${_currentTradeAmount.toStringAsFixed(0)} USDT) en dos disparos sincronizados:',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2E7D32),
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: AppColors.brutalistCell(
                                    color: Colors.white,
                                    borderWidth: 1.5,
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'DISPARO 1 (50% LOTE):',
                                        style: TextStyle(fontFamily: 'monospace', fontSize: 8.5, fontWeight: FontWeight.bold, color: AppColors.textMuted),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '\$${_fmt(entry)}',
                                        style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w900, fontSize: 13, color: AppColors.ink),
                                      ),
                                      Text(
                                        '\$${(_currentTradeAmount / 2).toStringAsFixed(0)} USDT',
                                        style: const TextStyle(fontFamily: 'monospace', fontSize: 9.5, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
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
                                    color: Colors.white,
                                    borderWidth: 1.5,
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'DISPARO 2 RETEST (-1.8%):',
                                        style: TextStyle(fontFamily: 'monospace', fontSize: 8.5, fontWeight: FontWeight.bold, color: AppColors.textMuted),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '\$${_fmt(entry * 0.982)}',
                                        style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w900, fontSize: 13, color: AppColors.ink),
                                      ),
                                      Text(
                                        '\$${(_currentTradeAmount / 2).toStringAsFixed(0)} USDT',
                                        style: const TextStyle(fontFamily: 'monospace', fontSize: 9.5, fontWeight: FontWeight.bold, color: Color(0xFF00E5FF)),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(8),
                            decoration: AppColors.brutalistCell(
                              color: const Color(0xFFFFF9C4),
                              borderWidth: 1.5,
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('🛡️ ', style: TextStyle(fontSize: 12)),
                                Expanded(
                                  child: RichText(
                                    text: TextSpan(
                                      style: const TextStyle(fontFamily: 'monospace', fontSize: 9.5, color: AppColors.ink),
                                      children: [
                                        const TextSpan(
                                          text: 'REGLA BLINDAJE BREAK-EVEN: ',
                                          style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFFE65100)),
                                        ),
                                        TextSpan(
                                          text: 'Al tocar TP1 (+3.0%), vendes el 50% y mueves el Stop Loss de la mitad restante al precio de entrada (\$${_fmt(entry)}) para que sea un trade de \$0 riesgo (Free-Roll).',
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // 3. Detalle de Confirmaciones Técnicas SMC 1H (Condiciones Cumplidas vs Faltantes)
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: AppColors.brutalistBox(
                        color: AppColors.surface,
                        borderWidth: 2.5,
                        shadowOffset: 3.5,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'AUDITORÍA DE ESTRUCTURA INSTITUCIONAL (1H)',
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.w900,
                              fontSize: 11,
                              color: AppColors.ink,
                            ),
                          ),
                          const SizedBox(height: 12),

                          // 1. Suelo Fractal 1H
                          _buildAuditConditionRow(
                            label: 'Suelo Fractal 1H:',
                            valueText: '\$${_fmt(item.nearestFloorPrice)} (${item.distanceToFloorPct.toStringAsFixed(2)}%)',
                            isMet: item.distanceToFloorPct <= 1.5,
                            metText: 'EN ZONA',
                            pendingText: 'DISTANTE',
                          ),

                          // 2. Descuento 48h (Mínimo 3.5% para Smart Money)
                          _buildAuditConditionRow(
                            label: 'Descuento 48h:',
                            valueText: '-${item.dropFrom48hHighPct.toStringAsFixed(1)}% desde máx',
                            isMet: item.dropFrom48hHighPct >= 3.5,
                            metText: 'DESCUENTO CUMPLIDO',
                            pendingText: 'FALTA CAÍDA >= 3.5%',
                          ),

                          // 3. RSI 1H
                          _buildAuditConditionRow(
                            label: 'RSI 1H (14 períodos):',
                            valueText: item.currentRsi.toStringAsFixed(1),
                            isMet: item.currentRsi <= 46.0 || item.hasRsiDivergence,
                            metText: 'SOBREVENTA/REBOTE',
                            pendingText: 'ZONA NEUTRAL',
                          ),

                          // 4. Barrida 2do Toque (SFP)
                          _buildAuditConditionRow(
                            label: 'Barrida 2do Toque (SFP):',
                            valueText: item.hasUnbroken2ndTouchSweep ? 'CONFIRMADA' : 'NO DETECTADA',
                            isMet: item.hasUnbroken2ndTouchSweep,
                            metText: 'SFP CUMPLIDO',
                            pendingText: 'FALTA PARA S+',
                          ),

                          // 5. CHoCH Envolvente
                          _buildAuditConditionRow(
                            label: 'Vela Envolvente CHoCH:',
                            valueText: item.hasEngulfingChoch ? 'CONFIRMADA' : 'NO DETECTADA',
                            isMet: item.hasEngulfingChoch,
                            metText: 'CHoCH CUMPLIDO',
                            pendingText: 'FALTA PARA S+',
                          ),

                          // 6. Divergencia Alcista
                          _buildAuditConditionRow(
                            label: 'Divergencia Alcista RSI:',
                            valueText: item.hasRsiDivergence ? 'CONFIRMADA' : 'NO DETECTADA',
                            isMet: item.hasRsiDivergence,
                            metText: 'CONFIRMADA',
                            pendingText: 'OPCIONAL',
                            isOptional: true,
                          ),

                          const SizedBox(height: 10),

                          // Banner Explicativo: Qué le falta para subir de categoría
                          _buildGradeRequirementBanner(item),

                          const SizedBox(height: 10),

                          // Estado de Alerta (Con Flexibilidad para evitar overflow derecho)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: AppColors.ink, width: 1.5),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Estado de Alerta: ',
                                  style: TextStyle(
                                    fontFamily: 'monospace',
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10.5,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    item.expirationReason,
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
                        ],
                      ),
                    ),

                    const SizedBox(height: 10),
                  ],
                ),
              ),

              // Barra de Acciones Fija Inferior (Pinned Action Bar - Siempre Visible)
              Container(
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  border: Border(
                    top: BorderSide(color: AppColors.ink, width: 3.0),
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                child: SafeArea(
                  top: false,
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                            NativeAlarmService.openBinance();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            decoration: AppColors.brutalistBox(
                              color: AppColors.gold,
                              borderWidth: 2.5,
                              shadowOffset: 3.0,
                            ),
                            child: const Center(
                              child: Text(
                                '🟡 ABRIR EN BINANCE SPOT',
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontWeight: FontWeight.w900,
                                  fontSize: 12,
                                  color: AppColors.ink,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: () {
                          final modalLimitBuy = item.entryPrice > 0 ? item.entryPrice : item.nearestFloorPrice;
                          NativeAlarmService.scheduleTestAlarm(
                            delaySeconds: 5,
                            eventType: 'S_PLUS_ALPHA',
                            symbol: '${item.displaySymbol} / USDT (${item.grade} ${item.confluenceScore}%)',
                            price: '\$${_fmt(p)}',
                            amount: 'SUELO 1H: \$${_fmt(item.nearestFloorPrice)} (-${item.dropFrom48hHighPct.toStringAsFixed(1)}% 48h)',
                            targetPrice: '\$${_fmt(modalLimitBuy)}',
                            projectedProfit: 'TP1: \$${_fmt(item.tp1Price)} | TP2: \$${_fmt(item.tp2Price)}',
                            totalProfit: '+\$${profitTp2.toStringAsFixed(2)} USDT',
                            liquidCash: '\$${_currentTradeAmount.toStringAsFixed(2)} USDT',
                            tp1Price: '\$${_fmt(item.tp1Price)}',
                            tp2Price: '\$${_fmt(item.tp2Price)}',
                            slPrice: '\$${_fmt(item.slTriggerPrice)}',
                            limitBuyPrice: '\$${_fmt(modalLimitBuy)}',
                            tradeAmount: _currentTradeAmount,
                          );
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              backgroundColor: AppColors.ink,
                              duration: Duration(seconds: 4),
                              content: Text(
                                '⚡ Alarma programada en 5s. ¡Bloquea tu teléfono ahora!',
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                  color: Color(0xFF00E5FF),
                                ),
                              ),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(11),
                          decoration: AppColors.brutalistBox(
                            color: const Color(0xFF00E5FF),
                            borderWidth: 2.5,
                            shadowOffset: 3.0,
                          ),
                          child: const Icon(Icons.alarm_on, color: AppColors.ink, size: 24),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTargetCard({
    required String title,
    required String targetPrice,
    required String profitUsdt,
    required Color badgeBg,
    required Color badgeTextColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.ink, width: 2.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontWeight: FontWeight.w900,
              fontSize: 9.5,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            targetPrice,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontWeight: FontWeight.w900,
              fontSize: 13,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: badgeBg,
              border: Border.all(color: AppColors.ink, width: 1.0),
            ),
            child: Text(
              profitUsdt,
              style: TextStyle(
                fontFamily: 'monospace',
                fontWeight: FontWeight.w900,
                fontSize: 10,
                color: badgeTextColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuditConditionRow({
    required String label,
    required String valueText,
    required bool isMet,
    required String metText,
    required String pendingText,
    bool isOptional = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 10.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              Text(
                valueText,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w900,
                  fontSize: 10.5,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isMet
                    ? const Color(0xFF10B981) // Verde esmeralda si cumplió
                    : isOptional
                        ? const Color(0xFFE5E0D5) // Gris si es opcional
                        : const Color(0xFFFF5500), // Naranja/Rojo si falta para S+
                border: Border.all(color: AppColors.ink, width: 1.0),
              ),
              child: Text(
                isMet ? '✅ $metText' : '❌ $pendingText',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w900,
                  fontSize: 9,
                  color: isMet
                      ? Colors.white
                      : isOptional
                          ? AppColors.ink
                          : Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradeRequirementBanner(SPlusCoinRadarItem item) {
    if (item.grade == 'S+') {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFF10B981).withValues(alpha: 0.15),
          border: Border.all(color: const Color(0xFF10B981), width: 2.0),
        ),
        child: const Row(
          children: [
            Icon(Icons.stars, color: Color(0xFF10B981), size: 18),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                '⭐ GRADO S+ ACTIVO: Cumple los 4 pilares institucionales SMC (Suelo + Descuento + SFP + CHoCH).',
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
      );
    }

    if (item.grade == 'S') {
      final missingMsg = !item.hasEngulfingChoch && !item.hasUnbroken2ndTouchSweep
          ? 'Barrida SFP de 2do toque y Vela Envolvente'
          : !item.hasEngulfingChoch
              ? 'Vela Envolvente Alcista (CHoCH 1H)'
              : 'Barrida SFP de 2do toque';

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFF00E5FF).withValues(alpha: 0.15),
          border: Border.all(color: const Color(0xFF00E5FF), width: 2.0),
        ),
        child: Row(
          children: [
            const Icon(Icons.arrow_upward, color: Color(0xFF0090A0), size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '⬆️ PARA SUBIR A S+: Requiere confirmación de $missingMsg.',
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
      );
    }

    // Grado A
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.gold.withValues(alpha: 0.2),
        border: Border.all(color: AppColors.gold, width: 2.0),
      ),
      child: const Row(
        children: [
          Icon(Icons.upgrade, color: AppColors.ink, size: 18),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              '⬆️ PARA SUBIR A S / S+: Entrada temprana. Esperar confirmación de suelo fractal con barrida SFP y CHoCH envolvente.',
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
    );
  }
}
