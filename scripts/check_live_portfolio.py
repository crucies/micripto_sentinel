import urllib.request
import json
import os

portfolio = [
    {"symbol": "ONDO", "amount": 1352.2446, "cost_price": 0.44590452, "category": "RWA"},
    {"symbol": "XRP", "amount": 387.38971614, "cost_price": 1.32, "category": "L1 / Payments"},
    {"symbol": "INJ", "amount": 50.28, "cost_price": 7.95, "category": "DeFi / L1"},
    {"symbol": "SUI", "amount": 358.4, "cost_price": 1.03, "category": "L1 High Throughput"},
    {"symbol": "NEAR", "amount": 64.1, "cost_price": 4.92, "category": "AI / L1"},
    {"symbol": "JUP", "amount": 955.00, "cost_price": 0.31411564, "category": "Solana DEX"},
    {"symbol": "ADA", "amount": 924.2993, "cost_price": 0.21655011, "category": "L1 Legacy"},
    {"symbol": "AAVE", "amount": 1.353, "cost_price": 147.67, "category": "DeFi Lending"},
    {"symbol": "PENDLE", "amount": 93.3, "cost_price": 2.11, "category": "Yield / DeFi"},
    {"symbol": "TIA", "amount": 338.00, "cost_price": 0.5917, "category": "Modular DA"},
    {"symbol": "RENDER", "amount": 67.65, "cost_price": 1.82, "category": "DePIN / GPU"},
    {"symbol": "TAO", "amount": 0.3731, "cost_price": 268.00, "category": "Decentralized AI"},
    {"symbol": "ALGO", "amount": 840.00, "cost_price": 0.119, "category": "L1 Legacy"},
    {"symbol": "APT", "amount": 116.54, "cost_price": 0.695, "category": "Move L1"},
    {"symbol": "OP", "amount": 727.08, "cost_price": 0.1281, "category": "Ethereum L2"},
    {"symbol": "HBAR", "amount": 1026.972, "cost_price": 0.07776491, "category": "Enterprise DLT"},
    {"symbol": "XLM", "amount": 446.553, "cost_price": 0.17860604, "category": "Payments"},
    {"symbol": "BNB", "amount": 0.01167766, "cost_price": 764.73, "category": "Exchange / Gas"},
]

free_usdt = 0.77960347

url = "https://api.binance.com/api/v3/ticker/24hr"
req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})

try:
    with urllib.request.urlopen(req, timeout=15) as resp:
        data = json.loads(resp.read().decode())
        ticker_map = {item["symbol"]: item for item in data}
except Exception as e:
    print(f"Error fetching 24hr tickers: {e}")
    ticker_map = {}

total_cost = sum(item["amount"] * item["cost_price"] for item in portfolio) + free_usdt
total_value = free_usdt

print(f"{'SYM':<7} | {'AMOUNT':<10} | {'COST':<9} | {'LIVE PRICE':<11} | {'24H CHG':<8} | {'PnL %':<8} | {'VALUE USDT':<10} | {'CAT':<15}")
print("-" * 95)

results = []
for item in portfolio:
    sym = item["symbol"]
    pair = f"{sym}USDT"
    info = ticker_map.get(pair)
    if info:
        live_price = float(info["lastPrice"])
        chg_24h = float(info["priceChangePercent"])
    else:
        live_price = item["cost_price"]
        chg_24h = 0.0

    cost = item["amount"] * item["cost_price"]
    val = item["amount"] * live_price
    pnl_pct = ((live_price - item["cost_price"]) / item["cost_price"]) * 100
    total_value += val

    results.append({
        "symbol": sym,
        "amount": item["amount"],
        "cost_price": item["cost_price"],
        "live_price": live_price,
        "chg_24h": chg_24h,
        "pnl_pct": pnl_pct,
        "cost_val": cost,
        "live_val": val,
        "category": item["category"]
    })

    print(f"{sym:<7} | {item['amount']:<10.2f} | ${item['cost_price']:<8.4f} | ${live_price:<10.4f} | {chg_24h:>+6.2f}% | {pnl_pct:>+6.2f}% | ${val:<9.2f} | {item['category']:<15}")

print("-" * 95)
print(f"USDT   | {free_usdt:<10.2f} | $1.0000   | $1.0000     |  +0.00% |  +0.00% | ${free_usdt:<9.2f} | Liquid Cash")
print("=" * 95)

net_pnl = total_value - total_cost
net_pnl_pct = (net_pnl / total_cost) * 100
print(f"TOTAL INVERTIDO : ${total_cost:.2f} USDT")
print(f"VALOR ACTUAL    : ${total_value:.2f} USDT")
print(f"PnL NETO        : ${net_pnl:+.2f} USDT ({net_pnl_pct:+.2f}%)")
