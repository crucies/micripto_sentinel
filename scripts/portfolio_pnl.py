coins = [
    ('ONDO', 1352.2446, 0.44590452, 0.4071, 'Sin Orden'),
    ('XRP', 387.38971614, 1.32000000, 1.2800, 'Sin Orden'),
    ('INJ', 50.2800, 7.95000000, 7.6600, 'Pendiente Venta TP'),
    ('SUI', 358.4000, 1.03000000, 0.9443, 'TP2 @ 1.065 (149.7 SUI)'),
    ('NEAR', 64.1000, 4.92000000, 4.4900, 'Sin Orden'),
    ('JUP', 955.0000, 0.31411564, 0.2920, 'TP1 @ 0.3252 + TP2 @ 0.3331'),
    ('AAVE', 1.3530, 147.67000000, 140.3500, 'TP1 @ 152.44 + TP2 @ 156.14'),
    ('ADA', 924.2993, 0.21655011, 0.2081, 'TP1 @ 0.2224 + TP2 @ 0.2278'),
    ('PENDLE', 93.3000, 2.11000000, 1.9900, 'Sin Orden'),
    ('TIA', 338.0000, 0.59170000, 0.5383, 'TP1 @ 0.6200 + TP2 @ 0.6450'),
    ('RENDER', 67.6500, 1.82000000, 1.7000, 'Sin Orden'),
    ('TAO', 0.3731, 268.00000000, 248.7000, 'Sin Orden'),
    ('ALGO', 840.0000, 0.11900000, 0.1045, 'Venta @ 0.1165 (840 ALGO)'),
    ('OP', 727.0800, 0.12810000, 0.1125, 'TP2 @ 0.1352 (727.08 OP)'),
    ('HBAR', 1026.9720, 0.07776491, 0.07662, 'Sin Orden'),
    ('XLM', 446.5530, 0.17860604, 0.1698, 'Venta @ 0.1840 (446 XLM)'),
    ('BNB', 0.01175967, 764.73000000, 732.6800, 'Fee Binance'),
]

total_cost = 0.0
total_val = 0.0

print(f"{'Moneda':<8} {'Cantidad':>10} {'Costo':>9} {'Actual':>9} {'Invertido':>10} {'Val Actual':>10} {'PnL ($)':>10} {'PnL (%)':>8}  {'Orden Binance'}")
print('-' * 95)
# Sorted from biggest dollar drawdown to smallest
for name, amt, cost, cur, order in sorted(coins, key=lambda x: (x[1]*x[3] - x[1]*x[2])):
    inv = amt * cost
    val = amt * cur
    pnl = val - inv
    pct = (pnl / inv) * 100
    total_cost += inv
    total_val += val
    print(f"{name:<8} {amt:>10.2f} ${cost:>8.4f} ${cur:>8.4f} ${inv:>9.2f} ${val:>9.2f} ${pnl:>9.2f} {pct:>7.2f}%  {order}")

print('-' * 95)
tot_pnl = total_val - total_cost
tot_pct = (tot_pnl / total_cost) * 100
print(f"TOTAL: Invertido: ${total_cost:.2f} USDT | Val Actual: ${total_val:.2f} USDT | PnL Flotante: ${tot_pnl:.2f} USDT ({tot_pct:.2f}%)")
