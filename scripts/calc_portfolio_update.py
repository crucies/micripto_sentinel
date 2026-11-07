#!/usr/bin/env python3
import json

portfolio = [
    {"coin": "ONDO", "amount": 1352.2446, "price": 0.4098, "cost": 0.44590452},
    {"coin": "XRP", "amount": 387.38971614, "price": 1.30, "cost": 1.32},
    {"coin": "INJ", "amount": 50.28, "price": 7.96, "cost": 7.95},
    {"coin": "SUI", "amount": 358.4, "price": 0.9262, "cost": 1.03},
    {"coin": "NEAR", "amount": 64.1, "price": 4.64, "cost": 4.92},
    {"coin": "JUP", "amount": 955.0, "price": 0.2838, "cost": 0.31411564},
    {"coin": "ADA", "amount": 924.2993, "price": 0.2058, "cost": 0.21655011},
    {"coin": "AAVE", "amount": 1.353, "price": 137.35, "cost": 147.67},
    {"coin": "PENDLE", "amount": 93.3, "price": 1.97, "cost": 2.11},
    {"coin": "TIA", "amount": 338.0, "price": 0.5331, "cost": 0.5917},
    {"coin": "RENDER", "amount": 67.65, "price": 1.73, "cost": 1.82},
    {"coin": "TAO", "amount": 0.3731, "price": 254.20, "cost": 268.0},
    {"coin": "ALGO", "amount": 840.0, "price": 0.1054, "cost": 0.119},
    {"coin": "APT", "amount": 116.54, "price": 0.706, "cost": 0.695},
    {"coin": "OP", "amount": 727.08, "price": 0.1115, "cost": 0.1281},
    {"coin": "HBAR", "amount": 1026.972, "price": 0.07783, "cost": 0.07776491},
    {"coin": "XLM", "amount": 446.553, "price": 0.1688, "cost": 0.17860604},
    {"coin": "BNB", "amount": 0.01167766, "price": 742.35, "cost": 764.73},
]

usdt_free = 0.77960347

tot_inv = sum(p["amount"] * p["cost"] for p in portfolio)
tot_val = sum(p["amount"] * p["price"] for p in portfolio)
pnl_val = tot_val - tot_inv
pnl_pct = (pnl_val / tot_inv) * 100

print(f"Total Invertido en Cripto: ${tot_inv:,.2f} USDT")
print(f"Valor Actual en Cripto:   ${tot_val:,.2f} USDT")
print(f"USDT Libre:               ${usdt_free:,.2f} USDT")
print(f"Patrimonio Total Spot:    ${tot_val + usdt_free:,.2f} USDT")
print(f"PnL Flotante Total:       ${pnl_val:,.2f} USDT ({pnl_pct:.2f}%)")

print("\nDetalle por Moneda:")
for p in sorted(portfolio, key=lambda x: (x["amount"] * x["price"] - x["amount"] * x["cost"])):
    val = p["amount"] * p["price"]
    inv = p["amount"] * p["cost"]
    diff = val - inv
    pct = (diff / inv) * 100
    print(f"  * {p['coin']:7s}: Inv: ${inv:7.2f} | Val: ${val:7.2f} | PnL: ${diff:+6.2f} ({pct:+5.2f}%)")
