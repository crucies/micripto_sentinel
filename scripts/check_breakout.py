import urllib.request
import json

def get_ticker(symbol):
    url = f"https://api.binance.com/api/v3/ticker/24hr?symbol={symbol}"
    req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
    with urllib.request.urlopen(req, timeout=10) as resp:
        return json.loads(resp.read().decode())

btc = get_ticker("BTCUSDT")
inj = get_ticker("INJUSDT")
print(f"BTC: Price={btc['lastPrice']}, High24h={btc['highPrice']}, Low24h={btc['lowPrice']}, Chg={btc['priceChangePercent']}%")
print(f"INJ: Price={inj['lastPrice']}, High24h={inj['highPrice']}, Low24h={inj['lowPrice']}, Chg={inj['priceChangePercent']}%")
