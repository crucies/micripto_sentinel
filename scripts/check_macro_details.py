import urllib.request
import json

def fetch_klines(symbol, interval, limit=25):
    url = f"https://api.binance.com/api/v3/klines?symbol={symbol}&interval={interval}&limit={limit}"
    req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
    with urllib.request.urlopen(req, timeout=10) as resp:
        return json.loads(resp.read().decode())

btc_4h = fetch_klines("BTCUSDT", "4h", limit=20)
btc_1d = fetch_klines("BTCUSDT", "1d", limit=10)
eth_4h = fetch_klines("ETHUSDT", "4h", limit=10)
sol_4h = fetch_klines("SOLUSDT", "4h", limit=10)

print(f"BTC Current 4H Candle: Open={btc_4h[-1][1]}, High={btc_4h[-1][2]}, Low={btc_4h[-1][3]}, Close={btc_4h[-1][4]}")
print(f"BTC Prev 4H Candle: Open={btc_4h[-2][1]}, High={btc_4h[-2][2]}, Low={btc_4h[-2][3]}, Close={btc_4h[-2][4]}")
print(f"BTC 1D Current: Open={btc_1d[-1][1]}, High={btc_1d[-1][2]}, Low={btc_1d[-1][3]}, Close={btc_1d[-1][4]}")

# Fetch BTC funding rate
try:
    f_url = "https://fapi.binance.com/fapi/v1/premiumIndex?symbol=BTCUSDT"
    req_f = urllib.request.Request(f_url, headers={"User-Agent": "Mozilla/5.0"})
    with urllib.request.urlopen(req_f, timeout=10) as resp:
        f_data = json.loads(resp.read().decode())
        print(f"BTC Funding Rate: {float(f_data.get('lastFundingRate', 0))*100:.4f}% | Mark Price: {f_data.get('markPrice')}")
except Exception as e:
    print("Funding rate error:", e)
