class OrderEntity {
  final String id;
  final String symbol;
  final String displaySymbol;
  final String side; // 'SELL' o 'BUY'
  final double targetPrice;
  final double entryPrice;
  final double amountCoins;
  final double expectedReturnUsdt;
  final double projectedProfitUsdt;
  final String datePlaced;
  final String status;
  final String notes;

  const OrderEntity({
    required this.id,
    required this.symbol,
    required this.displaySymbol,
    required this.side,
    required this.targetPrice,
    this.entryPrice = 0.0,
    required this.amountCoins,
    required this.expectedReturnUsdt,
    required this.projectedProfitUsdt,
    required this.datePlaced,
    required this.status,
    this.notes = '',
  });

  factory OrderEntity.fromJson(Map<String, dynamic> json) {
    return OrderEntity(
      id: json['id']?.toString() ?? '',
      symbol: json['symbol']?.toString() ?? '',
      displaySymbol: json['displaySymbol']?.toString() ?? (json['symbol']?.toString().replaceAll('USDT', '') ?? ''),
      side: json['side']?.toString() ?? 'SELL',
      targetPrice: (json['targetPrice'] as num?)?.toDouble() ?? 0.0,
      entryPrice: (json['entryPrice'] as num?)?.toDouble() ?? 0.0,
      amountCoins: (json['amountCoins'] as num?)?.toDouble() ?? 0.0,
      expectedReturnUsdt: (json['expectedReturnUsdt'] as num?)?.toDouble() ?? 0.0,
      projectedProfitUsdt: (json['projectedProfitUsdt'] as num?)?.toDouble() ?? 0.0,
      datePlaced: json['datePlaced']?.toString() ?? '',
      status: json['status']?.toString() ?? 'FILLED_OPEN',
      notes: json['notes']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'symbol': symbol,
      'displaySymbol': displaySymbol,
      'side': side,
      'targetPrice': targetPrice,
      'entryPrice': entryPrice,
      'amountCoins': amountCoins,
      'expectedReturnUsdt': expectedReturnUsdt,
      'projectedProfitUsdt': projectedProfitUsdt,
      'datePlaced': datePlaced,
      'status': status,
      'notes': notes,
    };
  }

  // Lista oficial y autoritativa de las 6 órdenes vivas en Binance Spot de Richard
  static const List<OrderEntity> currentLiveOrders = [
    OrderEntity(
      id: 'order-render-tp2-1860',
      symbol: 'RENDERUSDT',
      displaySymbol: 'RENDER (TP2)',
      side: 'Limit Sell',
      targetPrice: 1.860,
      entryPrice: 1.7580,
      amountCoins: 56.88,
      expectedReturnUsdt: 105.7968,
      projectedProfitUsdt: 5.80,
      datePlaced: '2026-10-18 15:51:08 BOT',
      status: '0% Filled (Esperando)',
      notes: '50% restante hacia resistencia mayor',
    ),
    OrderEntity(
      id: 'order-render-tp1-1833',
      symbol: 'RENDERUSDT',
      displaySymbol: 'RENDER (TP1)',
      side: 'Limit Sell',
      targetPrice: 1.833,
      entryPrice: 1.7580,
      amountCoins: 56.88,
      expectedReturnUsdt: 104.2610,
      projectedProfitUsdt: 4.27,
      datePlaced: '2026-10-18 16:28:35 BOT',
      status: '0% Filled (Esperando)',
      notes: '50% defensivo en $1.833 (Break-Even)',
    ),
    OrderEntity(
      id: 'order-pendle-2190',
      symbol: 'PENDLEUSDT',
      displaySymbol: 'PENDLE',
      side: 'Limit Sell',
      targetPrice: 2.190,
      entryPrice: 2.0780,
      amountCoins: 72.1,
      expectedReturnUsdt: 157.8980,
      projectedProfitUsdt: 8.07,
      datePlaced: '2026-10-17 10:57:23 BOT',
      status: '0% Filled (Esperando)',
    ),
    OrderEntity(
      id: 'order-sui-10650',
      symbol: 'SUIUSDT',
      displaySymbol: 'SUI',
      side: 'Limit Sell',
      targetPrice: 1.0650,
      entryPrice: 1.0020,
      amountCoins: 149.7,
      expectedReturnUsdt: 159.4304,
      projectedProfitUsdt: 9.43,
      datePlaced: '2026-10-17 09:18:42 BOT',
      status: '0% Filled (Esperando)',
    ),
    OrderEntity(
      id: 'order-xrp-13580',
      symbol: 'XRPUSDT',
      displaySymbol: 'XRP',
      side: 'Limit Sell',
      targetPrice: 1.3580,
      entryPrice: 1.2798,
      amountCoins: 261.0,
      expectedReturnUsdt: 354.4380,
      projectedProfitUsdt: 20.36,
      datePlaced: '2026-10-15 16:51:27 BOT',
      status: '0% Filled (Esperando)',
    ),
    OrderEntity(
      id: 'order-ondo-04880',
      symbol: 'ONDOUSDT',
      displaySymbol: 'ONDO',
      side: 'Limit Sell',
      targetPrice: 0.4880,
      entryPrice: 0.4582,
      amountCoins: 1091.2,
      expectedReturnUsdt: 532.5056,
      projectedProfitUsdt: 32.52,
      datePlaced: '2026-10-14 08:35:19 BOT',
      status: '0% Filled (Esperando)',
    ),
  ];
}
