import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/sentinel_auto_scanner.dart';
import '../../../orders/domain/order_entity.dart';

class ProfitReportsPage extends StatefulWidget {
  const ProfitReportsPage({super.key});

  @override
  State<ProfitReportsPage> createState() => _ProfitReportsPageState();
}

class _ProfitReportsPageState extends State<ProfitReportsPage> {
  String _selectedCoin = 'TODAS';
  String _selectedPeriod = 'TODAS'; // 'TODAS', 'HOY', 'ESTA SEMANA', 'ESTE MES', 'RANGO'
  DateTimeRange? _customDateRange;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: SentinelAutoScanner.instance,
      builder: (context, _) {
        final archivedOrders = SentinelAutoScanner.instance.archivedOrders
            .where((o) => o.isSell) // Solo consideramos ventas completadas que generaron ganancias
            .toList();

        // 1. Obtener lista única de monedas disponibles
        final availableCoins = <String>{'TODAS'};
        for (final o in archivedOrders) {
          availableCoins.add(o.displaySymbol.replaceAll(RegExp(r'\s*\(.*?\)'), '').trim().toUpperCase());
        }
        final coinList = availableCoins.toList()..sort();
        // Asegurar que 'TODAS' esté siempre primero
        coinList.remove('TODAS');
        coinList.insert(0, 'TODAS');

        // 2. Aplicar Filtro de Moneda
        var filteredOrders = archivedOrders.where((o) {
          if (_selectedCoin == 'TODAS') return true;
          final cleanSymbol = o.displaySymbol.replaceAll(RegExp(r'\s*\(.*?\)'), '').trim().toUpperCase();
          return cleanSymbol == _selectedCoin;
        }).toList();

        // 3. Aplicar Filtro de Fecha
        final now = DateTime.now();
        filteredOrders = filteredOrders.where((o) {
          final dateStr = (o.archivedAt ?? o.datePlaced).replaceAll(' BOT', '').trim();
          DateTime? orderDate;
          try {
            orderDate = DateTime.parse(dateStr.contains('T') ? dateStr : dateStr.replaceAll('/', '-'));
          } catch (_) {
            return true;
          }

          if (_selectedPeriod == 'HOY') {
            return orderDate.year == now.year && orderDate.month == now.month && orderDate.day == now.day;
          } else if (_selectedPeriod == 'ESTA SEMANA') {
            final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
            final startMidnight = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
            return orderDate.isAfter(startMidnight) || orderDate.isAtSameMomentAs(startMidnight);
          } else if (_selectedPeriod == 'ESTE MES') {
            return orderDate.year == now.year && orderDate.month == now.month;
          } else if (_selectedPeriod == 'RANGO' && _customDateRange != null) {
            final start = DateTime(_customDateRange!.start.year, _customDateRange!.start.month, _customDateRange!.start.day);
            final end = DateTime(_customDateRange!.end.year, _customDateRange!.end.month, _customDateRange!.end.day, 23, 59, 59);
            return (orderDate.isAfter(start) || orderDate.isAtSameMomentAs(start)) &&
                   (orderDate.isBefore(end) || orderDate.isAtSameMomentAs(end));
          }
          return true; // 'TODAS'
        }).toList();

        // 4. Calcular Total Ganado del filtro
        final totalNetProfit = filteredOrders.fold(0.0, (sum, o) => sum + o.netProfitUsdt);

        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSummaryCard(totalNetProfit, filteredOrders.length),
                        const SizedBox(height: 16),
                        _buildFilterSection(coinList),
                        const SizedBox(height: 16),
                        _buildTableHeader(),
                        const SizedBox(height: 8),
                        if (filteredOrders.isEmpty)
                          _buildEmptyState()
                        else
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: filteredOrders.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              return _buildReportRow(filteredOrders[index]);
                            },
                          ),
                        const SizedBox(height: 24),
                        _buildFooterFormulaNote(),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.ink, width: 2.5),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: AppColors.brutalistBox(
                  color: AppColors.gold,
                  borderWidth: 2.0,
                  shadowOffset: 2.0,
                ),
                child: const Icon(Icons.analytics_rounded, size: 20, color: AppColors.ink),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'REPORTE DE GANANCIAS',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                      color: AppColors.ink,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Text(
                    'AUDITORÍA DE BENEFICIOS SPOT',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                      fontSize: 9,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: AppColors.brutalistCell(
              color: AppColors.surfaceLight,
              borderWidth: 1.5,
            ),
            child: const Text(
              AppConstants.appVersion,
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
    );
  }

  Widget _buildSummaryCard(double totalNet, int count) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: AppColors.brutalistBox(
        color: AppColors.gold,
        borderWidth: 3.0,
        shadowOffset: 4.0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'TOTAL GANADO (FILTRO ACTUAL)',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: AppColors.ink,
                  letterSpacing: 0.5,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: AppColors.brutalistCell(
                  color: AppColors.ink,
                  borderWidth: 1.0,
                ),
                child: Text(
                  '$count ÓRDENES',
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    color: AppColors.gold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              '+${totalNet.toStringAsFixed(4)} USDT',
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: AppColors.ink,
                letterSpacing: -1.0,
              ),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Fórmula: Total Venta Cobrado - Costo de Compra - Comisión Binance',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection(List<String> coinList) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Filtro por Fecha / Período
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'FILTRAR POR FECHA:',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: AppColors.textMuted,
              ),
            ),
            if (_selectedPeriod == 'RANGO' && _customDateRange != null)
              GestureDetector(
                onTap: () => setState(() => _selectedPeriod = 'TODAS'),
                child: const Text(
                  '[LIMPIAR RANGO]',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: AppColors.orange,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              _buildPeriodChip('TODAS', 'TODO'),
              const SizedBox(width: 6),
              _buildPeriodChip('HOY', 'HOY'),
              const SizedBox(width: 6),
              _buildPeriodChip('ESTA SEMANA', 'SEMANA'),
              const SizedBox(width: 6),
              _buildPeriodChip('ESTE MES', 'MES'),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: _pickCustomDateRange,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: _selectedPeriod == 'RANGO'
                      ? AppColors.brutalistBox(color: const Color(0xFF00E5FF), borderWidth: 2.0, shadowOffset: 2.0)
                      : AppColors.brutalistCell(color: AppColors.surface, borderWidth: 1.5),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.date_range, size: 12, color: AppColors.ink),
                      const SizedBox(width: 4),
                      Text(
                        _selectedPeriod == 'RANGO' && _customDateRange != null
                            ? '${_customDateRange!.start.day}/${_customDateRange!.start.month} - ${_customDateRange!.end.day}/${_customDateRange!.end.month}'
                            : 'CALENDARIO',
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
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

        const SizedBox(height: 12),

        // Filtro por Moneda
        const Text(
          'FILTRAR POR MONEDA:',
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 10,
            fontWeight: FontWeight.w900,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 6),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: coinList.map((coin) {
              final isSelected = _selectedCoin == coin;
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedCoin = coin;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: isSelected
                        ? AppColors.brutalistBox(
                            color: AppColors.gold,
                            borderWidth: 2.0,
                            shadowOffset: 2.0,
                          )
                        : AppColors.brutalistCell(
                            color: AppColors.surface,
                            borderWidth: 1.5,
                          ),
                    child: Text(
                      coin,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildPeriodChip(String periodKey, String label) {
    final isSelected = _selectedPeriod == periodKey;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPeriod = periodKey;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: isSelected
            ? AppColors.brutalistBox(
                color: const Color(0xFF00E5FF),
                borderWidth: 2.0,
                shadowOffset: 2.0,
              )
            : AppColors.brutalistCell(
                color: AppColors.surface,
                borderWidth: 1.5,
              ),
        child: Text(
          label,
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 10,
            fontWeight: FontWeight.w900,
            color: AppColors.ink,
          ),
        ),
      ),
    );
  }

  Future<void> _pickCustomDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2026, 1, 1),
      lastDate: DateTime(2027, 12, 31),
      initialDateRange: _customDateRange ??
          DateTimeRange(
            start: DateTime.now().subtract(const Duration(days: 7)),
            end: DateTime.now(),
          ),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.gold,
              onPrimary: AppColors.ink,
              surface: AppColors.surface,
              onSurface: AppColors.ink,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _customDateRange = picked;
        _selectedPeriod = 'RANGO';
      });
    }
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: const BoxDecoration(
        color: AppColors.ink,
      ),
      child: Row(
        children: const [
          Expanded(
            flex: 34,
            child: Text(
              'FECHA',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 9,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ),
          Expanded(
            flex: 16,
            child: Text(
              'MONEDA',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 9,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ),
          Expanded(
            flex: 12,
            child: Text(
              'SEÑAL',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 9,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ),
          Expanded(
            flex: 18,
            child: Text(
              'DURACIÓN',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 9,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ),
          Expanded(
            flex: 20,
            child: Text(
              'GANANCIA',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 9,
                fontWeight: FontWeight.w900,
                color: AppColors.gold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportRow(OrderEntity order) {
    final cleanCoin = order.displaySymbol.replaceAll(RegExp(r'\s*\(.*?\)'), '').trim().toUpperCase();
    final netProfit = order.netProfitUsdt;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: AppColors.brutalistCell(
        color: AppColors.surface,
        borderWidth: 2.0,
      ),
      child: Row(
        children: [
          // 1. FECHA (Mi 21 de Oct del 26)
          Expanded(
            flex: 34,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.dateFormattedNatural,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: AppColors.ink,
                  ),
                ),
                Text(
                  order.displaySymbol.contains('TP')
                      ? order.displaySymbol
                      : (order.archivedReason ?? 'Venta Binance'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),

          // 2. MONEDA (AAA)
          Expanded(
            flex: 16,
            child: Text(
              cleanCoin,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: AppColors.ink,
              ),
            ),
          ),

          // 3. TIPO DE SEÑAL (S+)
          Expanded(
            flex: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: AppColors.brutalistCell(
                color: const Color(0xFF00E5FF),
                borderWidth: 1.0,
              ),
              child: Text(
                order.signalType,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 8.5,
                  fontWeight: FontWeight.w900,
                  color: AppColors.ink,
                ),
              ),
            ),
          ),

          // 4. DURACIÓN (N D N H N M)
          Expanded(
            flex: 18,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Text(
                order.durationFormatted,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textMuted,
                ),
              ),
            ),
          ),

          // 5. MONTO GANADO (+NN.NNNN USDT)
          Expanded(
            flex: 20,
            child: Text(
              '+${netProfit.toStringAsFixed(4)}',
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: AppColors.emerald,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: AppColors.brutalistCell(
        color: AppColors.surfaceLight,
        borderWidth: 2.0,
      ),
      child: Column(
        children: const [
          Icon(Icons.filter_list_off, size: 32, color: AppColors.textMuted),
          SizedBox(height: 8),
          Text(
            'SIN ÓRDENES PARA EL FILTRO ACTUAL',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: AppColors.ink,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Prueba seleccionando otra moneda o ampliando el rango de fecha',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 9,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterFormulaNote() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: AppColors.brutalistCell(
        color: AppColors.surfaceLight,
        borderWidth: 1.5,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            '📌 NOTA CONTABLE KAI & RICHARD:',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 9,
              fontWeight: FontWeight.w900,
              color: AppColors.ink,
            ),
          ),
          SizedBox(height: 4),
          Text(
            '• Cada ganancia mostrada descuenta el 100% del costo base de entrada y la comisión estándar de Binance Spot (0.1%).\n'
            '• La duración se mide exactamente desde el timestamp de colocación en Binance hasta el momento de cobro Take Profit.',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 8.5,
              color: AppColors.textMuted,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}
