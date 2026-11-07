import urllib.request
import json
import time

pairs = [
    "BTCUSDT", "ETHUSDT", "SOLUSDT", "BNBUSDT", "XRPUSDT", "DOGEUSDT", "ADAUSDT",
    "AVAXUSDT", "LINKUSDT", "SUIUSDT", "NEARUSDT", "APTUSDT", "DOTUSDT", "UNIUSDT",
    "ICPUSDT", "FETUSDT", "TAOUSDT", "RENDERUSDT", "AAVEUSDT", "INJUSDT", "TIAUSDT",
    "SEIUSDT", "ARBUSDT", "OPUSDT", "POLUSDT", "FTMUSDT", "ATOMUSDT", "ALGOUSDT",
    "HBARUSDT", "STXUSDT", "KASUSDT", "JUPUSDT", "ONDOUSDT", "PENDLEUSDT", "ENAUSDT",
    "WIFUSDT", "PEPEUSDT", "FLOKIUSDT", "BONKUSDT", "GALAUSDT", "SANDUSDT", "MANAUSDT",
    "CHZUSDT", "XLMUSDT"
]

def fetch_klines(symbol, interval="1h", limit=40):
    url = f"https://api.binance.com/api/v3/klines?symbol={symbol}&interval={interval}&limit={limit}"
    req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
    try:
        with urllib.request.urlopen(req, timeout=8) as resp:
            return json.loads(resp.read().decode())
    except:
        return None

def calc_rsi(closes, period=14):
    if len(closes) < period + 1:
        return 50.0
    gains = []
    losses = []
    for i in range(1, len(closes)):
        diff = closes[i] - closes[i-1]
        if diff > 0:
            gains.append(diff)
            losses.append(0.0)
        else:
            gains.append(0.0)
            losses.append(abs(diff))
    avg_gain = sum(gains[:period]) / period
    avg_loss = sum(losses[:period]) / period
    for i in range(period, len(gains)):
        avg_gain = (avg_gain * (period - 1) + gains[i]) / period
        avg_loss = (avg_loss * (period - 1) + losses[i]) / period
    if avg_loss == 0:
        return 100.0
    rs = avg_gain / avg_loss
    return 100.0 - (100.0 / (1.0 + rs))

detected = []

print("Scanning 44 pairs for S+ SMC signals...")
for p in pairs:
    klines = fetch_klines(p, "1h", 40)
    if not klines or len(klines) < 30:
        continue
    
    closes = [float(k[4]) for k in klines]
    highs = [float(k[2]) for k in klines]
    lows = [float(k[3]) for k in klines]
    volumes = [float(k[5]) for k in klines]

    current_price = closes[-1]
    current_low = lows[-1]
    current_high = highs[-1]
    
    # 20-period lowest low excluding current
    prior_lows = lows[-21:-1]
    recent_min = min(prior_lows)
    
    # Check liquidity sweep: did price pierce recent_min and close back above?
    liquidity_sweep = (lows[-1] <= recent_min or lows[-2] <= min(lows[-22:-2])) and (closes[-1] > recent_min)
    
    # Calculate RSI
    rsi = calc_rsi(closes)
    
    # Volume spike: current volume > 1.3x avg volume of last 10 candles
    avg_vol = sum(volumes[-11:-1]) / 10.0 if len(volumes) >= 11 else 1.0
    vol_ratio = volumes[-1] / avg_vol if avg_vol > 0 else 1.0
    
    # 24h change
    chg_24h = ((closes[-1] - closes[-25]) / closes[-25]) * 100 if len(closes) >= 25 else 0.0

    # Score calculation
    score = 0
    if liquidity_sweep:
        score += 35
    if rsi <= 42:
        score += 25
    elif rsi <= 48:
        score += 15
    if vol_ratio >= 1.2:
        score += 20
    if current_price > (current_low + (current_high - current_low) * 0.4): # closing near top of wick
        score += 20

    if score >= 65 or (liquidity_sweep and rsi <= 50):
        detected.append({
            "pair": p,
            "score": score,
            "price": current_price,
            "rsi": rsi,
            "vol_ratio": vol_ratio,
            "sweep": liquidity_sweep,
            "chg_24h": chg_24h
        })

print(f"\nFound {len(detected)} candidate signals:")
detected.sort(key=lambda x: x["score"], reverse=True)
for d in detected:
    print(f"-> {d['pair']:<10} | Score: {d['score']} | Price: ${d['price']:.4f} | RSI: {d['rsi']:.1f} | VolRatio: {d['vol_ratio']:.2f}x | Sweep: {d['sweep']} | 24h: {d['chg_24h']:+.2f}%")
