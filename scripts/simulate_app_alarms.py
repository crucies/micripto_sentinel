import urllib.request
import json
import math

# Load the exact adversarial report if available
try:
    with open("assets/data/adversarial_report.json", "r", encoding="utf-8") as f:
        adv_data = json.load(f)
        adv_map = {item["symbol"]: item for item in adv_data.get("ratings", [])}
except:
    adv_map = {}

symbols = [
    'RENDERUSDT', 'SUIUSDT', 'NEARUSDT', 'PENDLEUSDT', 'XRPUSDT',
    'ONDOUSDT', 'TAOUSDT', 'ALGOUSDT', 'HBARUSDT', 'XLMUSDT', 'BNBUSDT',
    'BTCUSDT', 'ETHUSDT', 'SOLUSDT', 'AVAXUSDT', 'LINKUSDT', 'INJUSDT',
    'APTUSDT', 'SEIUSDT', 'TIAUSDT', 'ARBUSDT', 'OPUSDT', 'FETUSDT',
    'AAVEUSDT', 'UNIUSDT', 'ADAUSDT', 'DOTUSDT', 'PYTHUSDT', 'GRTUSDT',
    'WLDUSDT', 'ARKMUSDT', 'FTMUSDT', 'POLUSDT', 'ICPUSDT', 'JUPUSDT',
    'RUNEUSDT', 'ENAUSDT', 'DOGEUSDT', 'ATOMUSDT', 'THETAUSDT', 'MKRUSDT',
    'CRVUSDT', 'LDOUSDT', 'STRKUSDT'
]

def fetch_klines(symbol, interval='1h', limit=35):
    url = f"https://api.binance.com/api/v3/klines?symbol={symbol}&interval={interval}&limit={limit}"
    req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
    try:
        with urllib.request.urlopen(req, timeout=5) as resp:
            return json.loads(resp.read().decode())
    except:
        return None

results = []

for s in symbols:
    klines = fetch_klines(s, '1h', 35)
    if not klines or len(klines) < 25:
        continue
    
    closes = [float(k[4]) for k in klines]
    highs = [float(k[2]) for k in klines]
    lows = [float(k[3]) for k in klines]
    vols = [float(k[5]) for k in klines]
    
    current_price = closes[-1]
    
    # 20-period floor (excluding last 2)
    eval_lows = lows[-22:-2]
    floor_price = min(eval_lows)
    
    # Sweep of liquidity: low of current or previous candle went below floor_price
    wick_low = min(lows[-1], lows[-2])
    has_sweep = wick_low < floor_price and current_price >= floor_price
    
    # Distance to floor %
    dist_to_floor = ((current_price - floor_price) / floor_price) * 100.0
    
    # RSI 14
    gains = []
    losses = []
    for i in range(1, len(closes)):
        diff = closes[i] - closes[i-1]
        gains.append(max(diff, 0.0))
        losses.append(max(-diff, 0.0))
    avg_g = sum(gains[-14:]) / 14.0
    avg_l = sum(losses[-14:]) / 14.0
    rsi = 100.0 - (100.0 / (1.0 + (avg_g / avg_l if avg_l > 0 else 999.0)))
    
    # Volume spike
    avg_v = sum(vols[-11:-1]) / 10.0 if len(vols) >= 11 else 1.0
    vol_ratio = vols[-1] / avg_v if avg_v > 0 else 1.0
    
    # Score matching SmcSPlusScanner
    score = 0
    if has_sweep:
        score += 35
    if rsi <= 35:
        score += 30
    elif rsi <= 45:
        score += 20
    elif rsi <= 52:
        score += 10
    if vol_ratio >= 1.5:
        score += 20
    elif vol_ratio >= 1.1:
        score += 10
    if dist_to_floor <= 0.8:
        score += 15
        
    is_drifting = dist_to_floor > 0.8
    adv_info = adv_map.get(s, {})
    verdict = adv_info.get("verdict", "APROBADO")
    
    if score >= 60:
        results.append({
            "symbol": s,
            "score": score,
            "price": current_price,
            "floor": floor_price,
            "dist_to_floor": dist_to_floor,
            "rsi": rsi,
            "vol_ratio": vol_ratio,
            "sweep": has_sweep,
            "is_drifting": is_drifting,
            "verdict": verdict
        })

results.sort(key=lambda x: x["score"], reverse=True)
print(f"{'SYMBOL':<10} | {'SCORE':<5} | {'PRICE':<10} | {'DIST %':<7} | {'RSI':<5} | {'VOL':<5} | {'SWEEP':<5} | {'DRIFT':<6} | {'ADV'}")
print("-" * 80)
for r in results:
    print(f"{r['symbol']:<10} | {r['score']:<5} | ${r['price']:<9.4f} | {r['dist_to_floor']:>+5.2f}% | {r['rsi']:<5.1f} | {r['vol_ratio']:<4.1f}x | {str(r['sweep']):<5} | {str(r['is_drifting']):<6} | {r['verdict']}")
