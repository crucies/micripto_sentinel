class OrderEntity {
  final String id;
  final String symbol;
  final String displaySymbol;
  final String side; // 'Limit Buy' o 'Limit Sell'
  final double targetPrice;
  final double entryPrice;
  final double amountCoins;
  final double expectedReturnUsdt;
  final double projectedProfitUsdt;
  final String datePlaced;
  final String status;
  final String notes;
  final String? archivedAt;
  final String? archivedReason;

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
    this.archivedAt,
    this.archivedReason,
  });

  bool get isBuy => side.toUpperCase().contains('BUY');
  bool get isSell => !isBuy;

  /// Costo de compra invertido (entryPrice * amountCoins)
  double get costBasisUsdt => entryPrice > 0 ? entryPrice * amountCoins : 0.0;

  /// Comisión estimada de Binance Spot (0.1% sobre el total vendido)
  double get binanceFeeUsdt => expectedReturnUsdt * 0.001;

  /// Monto Ganado Neto = Total Venta Cobrado - Costo de Compra - Comisión Binance
  double get netProfitUsdt {
    if (isBuy) return 0.0;
    if (costBasisUsdt > 0) {
      final net = expectedReturnUsdt - costBasisUsdt - binanceFeeUsdt;
      return net > 0 ? net : 0.0;
    }
    final net = projectedProfitUsdt - binanceFeeUsdt;
    return net > 0 ? net : 0.0;
  }

  /// Duración exacta entre orden colocada y archivada (N D N H N M)
  String get durationFormatted {
    try {
      final pStr = datePlaced.replaceAll(' BOT', '').trim();
      final aStr = (archivedAt ?? '').replaceAll(' BOT', '').trim();
      final placedDt = DateTime.parse(pStr.contains('T') ? pStr : pStr.replaceAll('/', '-'));
      final archDt = aStr.isNotEmpty
          ? DateTime.parse(aStr.contains('T') ? aStr : aStr.replaceAll('/', '-'))
          : DateTime.now().toUtc().subtract(const Duration(hours: 4));
      final diff = archDt.difference(placedDt);
      if (diff.isNegative) return '0 D 0 H 1 M';
      final days = diff.inDays;
      final hours = diff.inHours % 24;
      final minutes = diff.inMinutes % 60;
      return '$days D $hours H $minutes M';
    } catch (_) {
      return '0 D 4 H 3 M';
    }
  }

  /// Fecha en formato natural en español: Mi 21 de Oct del 26
  String get dateFormattedNatural {
    try {
      final target = (archivedAt != null && archivedAt!.isNotEmpty) ? archivedAt! : datePlaced;
      final clean = target.replaceAll(' BOT', '').trim();
      final dt = DateTime.parse(clean.contains('T') ? clean : clean.replaceAll('/', '-'));
      const daysEs = {1: 'Lu', 2: 'Ma', 3: 'Mi', 4: 'Ju', 5: 'Vi', 6: 'Sá', 7: 'Do'};
      const monthsEs = {1: 'Ene', 2: 'Feb', 3: 'Mar', 4: 'Abr', 5: 'May', 6: 'Jun', 7: 'Jul', 8: 'Ago', 9: 'Sep', 10: 'Oct', 11: 'Nov', 12: 'Dic'};
      final dName = daysEs[dt.weekday] ?? 'Mi';
      final mName = monthsEs[dt.month] ?? 'Oct';
      final yr = dt.year.toString().substring(2);
      return '$dName ${dt.day} de $mName del $yr';
    } catch (_) {
      return datePlaced;
    }
  }

  /// Tipo de señal SMC (S+, S, etc.)
  String get signalType {
    if (notes.toUpperCase().contains('S+')) return 'S+';
    if (notes.toUpperCase().contains('S')) return 'S';
    return 'S+';
  }

  OrderEntity copyWith({
    String? id,
    String? symbol,
    String? displaySymbol,
    String? side,
    double? targetPrice,
    double? entryPrice,
    double? amountCoins,
    double? expectedReturnUsdt,
    double? projectedProfitUsdt,
    String? datePlaced,
    String? status,
    String? notes,
    String? archivedAt,
    String? archivedReason,
  }) {
    return OrderEntity(
      id: id ?? this.id,
      symbol: symbol ?? this.symbol,
      displaySymbol: displaySymbol ?? this.displaySymbol,
      side: side ?? this.side,
      targetPrice: targetPrice ?? this.targetPrice,
      entryPrice: entryPrice ?? this.entryPrice,
      amountCoins: amountCoins ?? this.amountCoins,
      expectedReturnUsdt: expectedReturnUsdt ?? this.expectedReturnUsdt,
      projectedProfitUsdt: projectedProfitUsdt ?? this.projectedProfitUsdt,
      datePlaced: datePlaced ?? this.datePlaced,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      archivedAt: archivedAt ?? this.archivedAt,
      archivedReason: archivedReason ?? this.archivedReason,
    );
  }

  factory OrderEntity.fromJson(Map<String, dynamic> json) {
    return OrderEntity(
      id: json['id']?.toString() ?? '',
      symbol: json['symbol']?.toString() ?? '',
      displaySymbol: json['displaySymbol']?.toString() ?? (json['symbol']?.toString().replaceAll('USDT', '') ?? ''),
      side: json['side']?.toString() ?? (json['isBuy'] == true ? 'Limit Buy' : 'Limit Sell'),
      targetPrice: (json['targetPrice'] as num?)?.toDouble() ?? 0.0,
      entryPrice: (json['entryPrice'] as num?)?.toDouble() ?? 0.0,
      amountCoins: (json['amountCoins'] as num?)?.toDouble() ?? 0.0,
      expectedReturnUsdt: (json['expectedReturnUsdt'] as num?)?.toDouble() ?? 0.0,
      projectedProfitUsdt: (json['projectedProfitUsdt'] as num?)?.toDouble() ?? 0.0,
      datePlaced: json['datePlaced']?.toString() ?? '',
      status: json['status']?.toString() ?? 'FILLED_OPEN',
      notes: json['notes']?.toString() ?? '',
      archivedAt: json['archivedAt']?.toString(),
      archivedReason: json['archivedReason']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'symbol': symbol,
      'displaySymbol': displaySymbol,
      'side': side,
      'isBuy': isBuy,
      'targetPrice': targetPrice,
      'entryPrice': entryPrice,
      'amountCoins': amountCoins,
      'expectedReturnUsdt': expectedReturnUsdt,
      'projectedProfitUsdt': projectedProfitUsdt,
      'datePlaced': datePlaced,
      'status': status,
      'notes': notes,
      if (archivedAt != null) 'archivedAt': archivedAt,
      if (archivedReason != null) 'archivedReason': archivedReason,
    };
  }

  // Lista oficial de órdenes vivas en Binance Spot (18 Órdenes Activas: 1 Compra + 17 Ventas)
  static const List<OrderEntity> currentLiveOrders = [
    // 🎯 COMPRAS LÍMITE ACTIVAS EN SUELO (1 Orden)
    OrderEntity(
      id: 'binance-link-buy-10550',
      symbol: 'LINKUSDT',
      displaySymbol: 'LINK (Compra Límite)',
      side: 'Limit Buy',
      targetPrice: 10.5500,
      entryPrice: 10.5500,
      amountCoins: 9.47,
      expectedReturnUsdt: 99.9085,
      projectedProfitUsdt: 4.5000,
      datePlaced: '2026-11-07 06:27:48 BOT',
      status: '0% Filled (Esperando Suelo @ \$10.550)',
      notes: 'Limit Buy en retroceso clave @ \$10.550 (9.47 LINK = \$99.91 USDT)',
    ),

    // 🎯 VENTAS / TAKE PROFIT ACTIVAS (17 Órdenes Vivas Sincronizadas)
    // PENDLE
    OrderEntity(
      id: 'binance-pendle-sell-tp1-16800',
      symbol: 'PENDLEUSDT',
      displaySymbol: 'PENDLE (TP1)',
      side: 'Limit Sell',
      targetPrice: 1.6800,
      entryPrice: 1.6310,
      amountCoins: 30.65,
      expectedReturnUsdt: 51.4920,
      projectedProfitUsdt: 1.5018,
      datePlaced: '2026-11-07 07:30:00 BOT',
      status: '0% Filled (Esperando TP1)',
      notes: 'Limit Sell defensivo TP1 @ \$1.6800 (+3.0%) (30.65 PENDLE = \$51.49 USDT)',
    ),
    OrderEntity(
      id: 'binance-pendle-sell-tp2-17210',
      symbol: 'PENDLEUSDT',
      displaySymbol: 'PENDLE (TP2)',
      side: 'Limit Sell',
      targetPrice: 1.7210,
      entryPrice: 1.6310,
      amountCoins: 30.65,
      expectedReturnUsdt: 52.7486,
      projectedProfitUsdt: 2.7585,
      datePlaced: '2026-11-07 07:30:00 BOT',
      status: '0% Filled (Esperando TP2)',
      notes: 'Limit Sell expansivo TP2 @ \$1.7210 (+5.5%) (30.65 PENDLE = \$52.75 USDT)',
    ),

    // 🎯 VENTAS / TAKE PROFIT ACTIVAS (15 Órdenes Vivas Sincronizadas)
    // NEAR
    OrderEntity(
      id: 'binance-near-sell-tp1-38010',
      symbol: 'NEARUSDT',
      displaySymbol: 'NEAR (TP1)',
      side: 'Limit Sell',
      targetPrice: 3.8010,
      entryPrice: 3.6900,
      amountCoins: 13.55,
      expectedReturnUsdt: 51.5035,
      projectedProfitUsdt: 1.5040,
      datePlaced: '2026-11-07 06:22:00 BOT',
      status: '0% Filled (Esperando TP1)',
      notes: 'Limit Sell defensivo TP1 @ \$3.8010 (+3.0%) (13.55 NEAR = \$51.50 USDT)',
    ),
    OrderEntity(
      id: 'binance-near-sell-tp2-38930',
      symbol: 'NEARUSDT',
      displaySymbol: 'NEAR (TP2)',
      side: 'Limit Sell',
      targetPrice: 3.8930,
      entryPrice: 3.6900,
      amountCoins: 13.55,
      expectedReturnUsdt: 52.7501,
      projectedProfitUsdt: 2.7506,
      datePlaced: '2026-11-07 06:22:00 BOT',
      status: '0% Filled (Esperando TP2)',
      notes: 'Limit Sell expansivo TP2 @ \$3.8930 (+5.5%) (13.55 NEAR = \$52.75 USDT)',
    ),

    // APT
    OrderEntity(
      id: 'binance-apt-sell-07360',
      symbol: 'APTUSDT',
      displaySymbol: 'APT',
      side: 'Limit Sell',
      targetPrice: 0.7360,
      entryPrice: 0.6950,
      amountCoins: 57.11,
      expectedReturnUsdt: 42.0329,
      projectedProfitUsdt: 2.3415,
      datePlaced: '2026-10-25 10:36:28 BOT',
      status: '0% Filled (Esperando Venta)',
      notes: 'Limit Sell de toma de beneficios en Binance Spot @ \$0.7360 (57.11 APT = \$42.03 USDT)',
    ),

    // ALGO
    OrderEntity(
      id: 'binance-algo-sell-01165',
      symbol: 'ALGOUSDT',
      displaySymbol: 'ALGO',
      side: 'Limit Sell',
      targetPrice: 0.1165,
      entryPrice: 0.1190,
      amountCoins: 840.0,
      expectedReturnUsdt: 97.8600,
      projectedProfitUsdt: 0.0,
      datePlaced: '2026-10-22 09:08:55 BOT',
      status: '0% Filled (Esperando Venta)',
      notes: 'Limit Sell de rotación en Binance Spot @ \$0.1165 (840 ALGO = \$97.86 USDT)',
    ),

    // XLM
    OrderEntity(
      id: 'binance-xlm-sell-01840',
      symbol: 'XLMUSDT',
      displaySymbol: 'XLM',
      side: 'Limit Sell',
      targetPrice: 0.1840,
      entryPrice: 0.1786,
      amountCoins: 446.0,
      expectedReturnUsdt: 82.0640,
      projectedProfitUsdt: 2.4084,
      datePlaced: '2026-10-22 09:07:56 BOT',
      status: '0% Filled (Esperando Venta)',
      notes: 'Limit Sell de rotación en Binance Spot @ \$0.1840 (446 XLM = \$82.06 USDT)',
    ),

    // ADA (TP1 y TP2)
    OrderEntity(
      id: 'binance-ada-sell-tp1-02224',
      symbol: 'ADAUSDT',
      displaySymbol: 'ADA (TP1)',
      side: 'Limit Sell',
      targetPrice: 0.2224,
      entryPrice: 0.21655,
      amountCoins: 415.8,
      expectedReturnUsdt: 92.4739,
      projectedProfitUsdt: 2.4324,
      datePlaced: '2026-10-22 08:10:58 BOT',
      status: '0% Filled (Esperando TP1)',
      notes: 'Limit Sell defensivo TP1 en Binance Spot @ \$0.2224 (415.8 ADA = \$92.47 USDT)',
    ),
    OrderEntity(
      id: 'binance-ada-sell-tp2-02278',
      symbol: 'ADAUSDT',
      displaySymbol: 'ADA (TP2)',
      side: 'Limit Sell',
      targetPrice: 0.2278,
      entryPrice: 0.21655,
      amountCoins: 508.4,
      expectedReturnUsdt: 115.8135,
      projectedProfitUsdt: 5.7195,
      datePlaced: '2026-10-22 08:11:13 BOT',
      status: '0% Filled (Esperando TP2)',
      notes: 'Limit Sell expansivo TP2 en Binance Spot @ \$0.2278 (508.4 ADA = \$115.81 USDT)',
    ),

    // AAVE (TP1 y TP2)
    OrderEntity(
      id: 'binance-aave-sell-tp1-15244',
      symbol: 'AAVEUSDT',
      displaySymbol: 'AAVE (TP1)',
      side: 'Limit Sell',
      targetPrice: 152.44,
      entryPrice: 147.67,
      amountCoins: 0.622,
      expectedReturnUsdt: 94.8177,
      projectedProfitUsdt: 2.9669,
      datePlaced: '2026-10-22 07:36:24 BOT',
      status: '0% Filled (Esperando TP1)',
      notes: 'Limit Sell defensivo TP1 en Binance Spot @ \$152.44 (0.622 AAVE = \$94.82 USDT)',
    ),
    OrderEntity(
      id: 'binance-aave-sell-tp2-15614',
      symbol: 'AAVEUSDT',
      displaySymbol: 'AAVE (TP2)',
      side: 'Limit Sell',
      targetPrice: 156.14,
      entryPrice: 147.67,
      amountCoins: 0.731,
      expectedReturnUsdt: 114.1383,
      projectedProfitUsdt: 6.1916,
      datePlaced: '2026-10-22 07:37:57 BOT',
      status: '0% Filled (Esperando TP2)',
      notes: 'Limit Sell expansivo TP2 en Binance Spot @ \$156.14 (0.731 AAVE = \$114.14 USDT)',
    ),

    // JUP (TP1 y TP2)
    OrderEntity(
      id: 'binance-jup-sell-tp1-03252',
      symbol: 'JUPUSDT',
      displaySymbol: 'JUP (TP1)',
      side: 'Limit Sell',
      targetPrice: 0.3252,
      entryPrice: 0.314115,
      amountCoins: 450.0,
      expectedReturnUsdt: 146.3400,
      projectedProfitUsdt: 4.9883,
      datePlaced: '2026-10-22 07:21:04 BOT',
      status: '0% Filled (Esperando TP1)',
      notes: 'Limit Sell defensivo TP1 en Binance Spot @ \$0.3252 (450 JUP = \$146.34 USDT)',
    ),
    OrderEntity(
      id: 'binance-jup-sell-tp2-03331',
      symbol: 'JUPUSDT',
      displaySymbol: 'JUP (TP2)',
      side: 'Limit Sell',
      targetPrice: 0.3331,
      entryPrice: 0.314115,
      amountCoins: 505.0,
      expectedReturnUsdt: 168.2155,
      projectedProfitUsdt: 9.5874,
      datePlaced: '2026-10-22 07:21:36 BOT',
      status: '0% Filled (Esperando TP2)',
      notes: 'Limit Sell expansivo TP2 en Binance Spot @ \$0.3331 (505 JUP = \$168.22 USDT)',
    ),

    // TIA (TP1 y TP2)
    OrderEntity(
      id: 'binance-tia-sell-tp1-06200',
      symbol: 'TIAUSDT',
      displaySymbol: 'TIA (TP1)',
      side: 'Limit Sell',
      targetPrice: 0.6200,
      entryPrice: 0.5917,
      amountCoins: 169.0,
      expectedReturnUsdt: 104.7800,
      projectedProfitUsdt: 4.7827,
      datePlaced: '2026-10-22 07:05:51 BOT',
      status: '0% Filled (Esperando TP1)',
      notes: 'Limit Sell defensivo TP1 en Binance Spot @ \$0.6200 (169 TIA = \$104.78 USDT)',
    ),
    OrderEntity(
      id: 'binance-tia-sell-tp2-06450',
      symbol: 'TIAUSDT',
      displaySymbol: 'TIA (TP2)',
      side: 'Limit Sell',
      targetPrice: 0.6450,
      entryPrice: 0.5917,
      amountCoins: 169.0,
      expectedReturnUsdt: 109.0050,
      projectedProfitUsdt: 9.0077,
      datePlaced: '2026-10-22 07:06:51 BOT',
      status: '0% Filled (Esperando TP2)',
      notes: 'Limit Sell expansivo TP2 en Binance Spot @ \$0.6450 (169 TIA = \$109.01 USDT)',
    ),

    // OP (TP2)
    OrderEntity(
      id: 'binance-op-sell-tp2-01352',
      symbol: 'OPUSDT',
      displaySymbol: 'OP (TP2)',
      side: 'Limit Sell',
      targetPrice: 0.1352,
      entryPrice: 0.1281,
      amountCoins: 727.08,
      expectedReturnUsdt: 98.3012,
      projectedProfitUsdt: 5.1622,
      datePlaced: '2026-10-21 10:47:48 BOT',
      status: '0% Filled (Esperando TP2)',
      notes: 'Limit Sell expansivo en Binance Spot @ \$0.1352 (727.08 OP = \$98.30 USDT)',
    ),

    // SUI (TP2)
    OrderEntity(
      id: 'binance-sui-sell-10650',
      symbol: 'SUIUSDT',
      displaySymbol: 'SUI (TP2)',
      side: 'Limit Sell',
      targetPrice: 1.0650,
      entryPrice: 1.0020,
      amountCoins: 149.7,
      expectedReturnUsdt: 159.4304,
      projectedProfitUsdt: 9.4311,
      datePlaced: '2026-10-17 09:18:42 BOT',
      status: '0% Filled (Esperando TP2)',
      notes: 'Limit Sell expansivo TP2 en Binance Spot @ \$1.0650 (149.7 SUI = \$159.43 USDT)',
    ),
  ];

  // Historial oficial de órdenes completadas / archivadas en Binance Spot
  static const List<OrderEntity> defaultArchivedOrders = [
    // PENDLE (Compra ejecutada en suelo)
    OrderEntity(
      id: 'binance-pendle-buy-executed-16310',
      symbol: 'PENDLEUSDT',
      displaySymbol: 'PENDLE (Compra)',
      side: 'Limit Buy',
      targetPrice: 1.6310,
      entryPrice: 1.6310,
      amountCoins: 61.30,
      expectedReturnUsdt: 99.9803,
      projectedProfitUsdt: 0.0,
      datePlaced: '2026-11-07 06:06:47 BOT',
      status: 'EJECUTADA / ARCHIVADA',
      notes: '61.30 PENDLE compradas en suelo institucional @ \$1.6310 (\$99.98 USDT invertidos)',
      archivedAt: '2026-11-07 07:25:00 BOT',
      archivedReason: 'Compra Ejecutada en Binance Spot @ \$1.6310',
    ),
    // INJ (TP1 y TP2 completados)
    OrderEntity(
      id: 'binance-inj-sell-tp2-8320',
      symbol: 'INJUSDT',
      displaySymbol: 'INJ (TP2)',
      side: 'Limit Sell',
      targetPrice: 8.3200,
      entryPrice: 7.9500,
      amountCoins: 25.14,
      expectedReturnUsdt: 209.1648,
      projectedProfitUsdt: 9.2991,
      datePlaced: '2026-10-23 18:12:18 BOT',
      status: 'EJECUTADA / ARCHIVADA',
      archivedAt: '2026-11-05 06:40:00 BOT',
      archivedReason: 'TP2 Alcanzado en Binance Spot @ \$8.4800',
      notes: 'Limit Sell expansivo TP2 en Binance Spot @ \$8.320 (25.14 INJ = \$209.16 USDT)',
    ),
    OrderEntity(
      id: 'binance-inj-sell-tp1-8192',
      symbol: 'INJUSDT',
      displaySymbol: 'INJ (TP1)',
      side: 'Limit Sell',
      targetPrice: 8.1920,
      entryPrice: 7.9500,
      amountCoins: 25.14,
      expectedReturnUsdt: 205.9469,
      projectedProfitUsdt: 6.0812,
      datePlaced: '2026-10-23 18:11:53 BOT',
      status: 'EJECUTADA / ARCHIVADA',
      archivedAt: '2026-11-05 06:35:00 BOT',
      archivedReason: 'TP1 Alcanzado en Binance Spot @ \$8.4800',
      notes: 'Limit Sell defensivo TP1 en Binance Spot @ \$8.192 (25.14 INJ = \$205.95 USDT)',
    ),
    OrderEntity(
      id: 'binance-apt-buy-executed-06950',
      symbol: 'APTUSDT',
      displaySymbol: 'APT (Compra)',
      side: 'Limit Buy',
      targetPrice: 0.6950,
      entryPrice: 0.6950,
      amountCoins: 116.54,
      expectedReturnUsdt: 80.9953,
      projectedProfitUsdt: 0.0,
      datePlaced: '2026-10-25 08:30:00 BOT',
      status: 'EJECUTADA / ARCHIVADA',
      notes: '116.54 APT compradas en Binance Spot @ \$0.6950 (\$81.00 USDT invertidos)',
      archivedAt: '2026-10-25 09:00:00 BOT',
      archivedReason: 'Compra Ejecutada en Binance Spot @ \$0.6950',
    ),
    OrderEntity(
      id: 'binance-inj-buy-executed-7950',
      symbol: 'INJUSDT',
      displaySymbol: 'INJ (Compra)',
      side: 'Limit Buy',
      targetPrice: 7.9500,
      entryPrice: 7.9500,
      amountCoins: 50.28,
      expectedReturnUsdt: 399.7260,
      projectedProfitUsdt: 0.0,
      datePlaced: '2026-10-22 08:30:00 BOT',
      status: 'EJECUTADA / ARCHIVADA',
      notes: '50.28 INJ compradas en Binance Spot @ \$7.95 (\$393.24 - \$399.73 USDT invertidos)',
      archivedAt: '2026-10-22 09:00:00 BOT',
      archivedReason: 'Compra Ejecutada en Binance Spot @ \$7.9500',
    ),
    OrderEntity(
      id: 'binance-inj-buy-executed-8114',
      symbol: 'INJUSDT',
      displaySymbol: 'INJ (Compra)',
      side: 'Limit Buy',
      targetPrice: 8.1140,
      entryPrice: 8.1140,
      amountCoins: 24.640,
      expectedReturnUsdt: 199.9290,
      projectedProfitUsdt: 0.0,
      datePlaced: '2026-10-22 07:24:16 BOT',
      status: 'EJECUTADA / ARCHIVADA',
      notes: '24.64 INJ compradas en suelo @ \$8.1140 (\$199.93 USDT invertidos)',
      archivedAt: '2026-10-22 08:00:00 BOT',
      archivedReason: 'Compra Límite Ejecutada en Binance Spot @ \$8.1140',
    ),
    OrderEntity(
      id: 'binance-tia-buy-05917',
      symbol: 'TIAUSDT',
      displaySymbol: 'TIA (Compra)',
      side: 'Limit Buy',
      targetPrice: 0.5917,
      entryPrice: 0.5917,
      amountCoins: 338.00,
      expectedReturnUsdt: 199.9946,
      projectedProfitUsdt: 0.0,
      datePlaced: '2026-10-20 18:57:54 BOT',
      status: 'EJECUTADA / ARCHIVADA',
      notes: '338.00 TIA compradas en suelo @ \$0.5917 (\$199.99 USDT invertidos)',
      archivedAt: '2026-10-22 07:00:00 BOT',
      archivedReason: 'Compra Límite Ejecutada en Binance Spot @ \$0.5917',
    ),
    OrderEntity(
      id: 'binance-op-sell-tp1-01320',
      symbol: 'OPUSDT',
      displaySymbol: 'OP (TP1)',
      side: 'Limit Sell',
      targetPrice: 0.1320,
      entryPrice: 0.1281,
      amountCoins: 600.00,
      expectedReturnUsdt: 79.2000,
      projectedProfitUsdt: 2.3400,
      datePlaced: '2026-10-21 10:47:17 BOT',
      status: 'EJECUTADA / ARCHIVADA',
      notes: 'Take Profit 1 ejecutado con exito en Binance Spot @ .1320 (+2.34 USDT netos)',
      archivedAt: '2026-10-21 14:50:00 BOT',
      archivedReason: 'Take Profit 1 Ejecutado en Binance Spot @ .1320',
    ),
    OrderEntity(
      id: 'binance-sui-sell-10540',
      symbol: 'SUIUSDT',
      displaySymbol: 'SUI (TP1)',
      side: 'Limit Sell',
      targetPrice: 1.0540,
      entryPrice: 0.9967,
      amountCoins: 70.0,
      expectedReturnUsdt: 73.7800,
      projectedProfitUsdt: 4.0110,
      datePlaced: '2026-10-19 07:04:04 BOT',
      status: 'EJECUTADA / ARCHIVADA',
      notes: 'Take Profit 1 ejecutado con éxito en Binance Spot @ \$1.0540 (+4.01 USDT netos)',
      archivedAt: '2026-10-21 14:20:00 BOT',
      archivedReason: 'Take Profit 1 Ejecutado en Binance Spot @ \$1.0540',
    ),
    OrderEntity(
      id: 'trade-op-buy-filled-01281',
      symbol: 'OPUSDT',
      displaySymbol: 'OP (Compra)',
      side: 'Limit Buy',
      targetPrice: 0.1281,
      entryPrice: 0.1281,
      amountCoins: 1327.08,
      expectedReturnUsdt: 169.9989,
      projectedProfitUsdt: 0.0,
      datePlaced: '2026-10-20 19:14:20 BOT',
      status: 'EJECUTADA / ARCHIVADA',
      notes: '1,327.08 OP compradas en suelo @ \$0.1281 (\$170.00 USDT invertidos)',
      archivedAt: '2026-10-21 10:00:00 BOT',
      archivedReason: 'Compra Límite Ejecutada en Binance Spot @ \$0.1281',
    ),
    OrderEntity(
      id: 'binance-ondo-sell-04620',
      symbol: 'ONDOUSDT',
      displaySymbol: 'ONDO',
      side: 'Limit Sell',
      targetPrice: 0.4620,
      entryPrice: 0.4459,
      amountCoins: 1091.2,
      expectedReturnUsdt: 504.1344,
      projectedProfitUsdt: 17.5683,
      datePlaced: '2026-10-21 03:11:05 BOT',
      status: 'EJECUTADA / ARCHIVADA',
      notes: 'Limit Sell ejecutado con éxito en Binance Spot @ \$0.4620 (+17.57 USDT netos)',
      archivedAt: '2026-10-21 09:00:00 BOT',
      archivedReason: 'Take Profit Ejecutado en Binance Spot @ \$0.4620',
    ),
    OrderEntity(
      id: 'trade-sui-tp1-10280',
      symbol: 'SUIUSDT',
      displaySymbol: 'SUI (TP0)',
      side: 'Limit Sell',
      targetPrice: 1.0280,
      entryPrice: 0.9967,
      amountCoins: 70.0,
      expectedReturnUsdt: 71.9600,
      projectedProfitUsdt: 2.19,
      datePlaced: '2026-10-19 07:03:30 BOT',
      status: 'EJECUTADA / ARCHIVADA',
      notes: '50% defensivo (70 SUI @ \$1.0280). Ejecutado con éxito.',
      archivedAt: '2026-10-20 10:30:00 BOT',
      archivedReason: 'Take Profit Inicial Ejecutado en Binance Spot',
    ),
    OrderEntity(
      id: 'trade-render-tp2-1860',
      symbol: 'RENDERUSDT',
      displaySymbol: 'RENDER (TP2)',
      side: 'Limit Sell',
      targetPrice: 1.860,
      entryPrice: 1.7580,
      amountCoins: 56.88,
      expectedReturnUsdt: 105.7968,
      projectedProfitUsdt: 5.80,
      datePlaced: '2026-10-18 15:51:08 BOT',
      status: 'EJECUTADA / ARCHIVADA',
      notes: '50% expansivo cobrado a \$1.8600. Ganancia +\$5.80 USDT.',
      archivedAt: '2026-10-20 10:30:00 BOT',
      archivedReason: 'Take Profit 2 Ejecutado en Binance Spot',
    ),
  ];
}
