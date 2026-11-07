#!/usr/bin/env python3
import urllib.request
import json
import sys
import io

if sys.stdout.encoding != 'utf-8':
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

symbols = [
    # Cartera
    "RENDERUSDT", "SUIUSDT", "NEARUSDT", "PENDLEUSDT", "XRPUSDT",
    "ONDOUSDT", "TAOUSDT", "ALGOUSDT", "HBARUSDT", "XLMUSDT", "BNBUSDT",
    # Caza
    "BTCUSDT", "ETHUSDT", "SOLUSDT", "AVAXUSDT", "LINKUSDT",
    "INJUSDT", "APTUSDT", "SEIUSDT", "TIAUSDT", "ARBUSDT",
    "OPUSDT", "FETUSDT", "AAVEUSDT", "UNIUSDT", "ADAUSDT",
    "DOTUSDT", "PYTHUSDT", "GRTUSDT", "WLDUSDT", "ARKMUSDT",
    "FTMUSDT", "POLUSDT", "ICPUSDT", "JUPUSDT", "RUNEUSDT",
    "ENAUSDT", "DOGEUSDT", "ATOMUSDT", "THETAUSDT", "MKRUSDT",
    "CRVUSDT", "LDOUSDT", "STRKUSDT"
]

def fetch_klines(symbol, interval="1h", limit=120):
    url = f"https://api.binance.com/api/v3/klines?symbol={symbol}&interval={interval}&limit={limit}"
    req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
    try:
        with urllib.request.urlopen(req, timeout=5) as resp:
            return json.loads(resp.read().decode('utf-8'))
    except Exception:
        return []

def calc_rsi(closes, period=14):
    if len(closes) <= period: return [50.0] * len(closes)
    rsi = [50.0] * len(closes)
    gains, losses = 0.0, 0.0
    for i in range(1, period + 1):
        d = closes[i] - closes[i - 1]
        if d >= 0: gains += d
        else: losses -= d
    avg_g = gains / period
    avg_l = losses / period
    rsi[period] = 100.0 if avg_l == 0 else 100.0 - (100.0 / (1.0 + (avg_g / avg_l)))
    for i in range(period + 1, len(closes)):
        d = closes[i] - closes[i - 1]
        g = d if d >= 0 else 0.0
        l = -d if d < 0 else 0.0
        avg_g = ((avg_g * (period - 1)) + g) / period
        avg_l = ((avg_l * (period - 1)) + l) / period
        rsi[i] = 100.0 if avg_l == 0 else 100.0 - (100.0 / (1.0 + (avg_g / avg_l)))
    return rsi

candidates = []

print("Escaneando las 44 monedas con el motor Smart Engine 2.2...")
for sym in symbols:
    klines = fetch_klines(sym, interval="1h", limit=120)
    if len(klines) < 60: continue
    
    opens = [float(k[1]) for k in klines]
    highs = [float(k[2]) for k in klines]
    lows = [float(k[3]) for k in klines]
    closes = [float(k[4]) for k in klines]
    vols = [float(k[5]) for k in klines]
    
    rsi = calc_rsi(closes, 14)
    cur_p = closes[-1]
    cur_rsi = rsi[-1]
    
    # Evaluar retroceso de 48h
    high_48h = max(highs[-48:]) if len(highs) >= 48 else max(highs)
    drop_48h_pct = ((high_48h - cur_p) / high_48h) * 100.0 if high_48h > 0 else 0.0
    
    # Buscar swing lows en lookback 4
    n = len(klines)
    best_sweep = None
    
    for i in range(4, n - 4):
        is_low = True
        for j in range(i - 4, i + 5):
            if j == i: continue
            if lows[j] <= lows[i]:
                is_low = False
                break
        if not is_low: continue
        
        sw_price = lows[i]
        # Verificar si fue barrido
        for k in range(i + 1, n):
            if k <= i + 4:
                if lows[k] < sw_price * 0.997: break
                continue
            if k - i > 120: break
            
            if lows[k] < sw_price and closes[k] > sw_price:
                age = n - 1 - k
                if age <= 4: # Barrida reciente en las últimas 4 horas
                    # CHoCH inmediato
                    choch = closes[k] > highs[k - 1] and closes[k] > opens[k]
                    # Divergencia RSI
                    rsi_div = (rsi[k] > rsi[i] + 1.0 and rsi[i] < 48.0) or (rsi[k] < 45.0)
                    dist_to_entry = ((cur_p - closes[k]) / closes[k]) * 100.0
                    
                    if choch and dist_to_entry <= 1.5:
                        score = 80
                        if rsi_div: score += 10
                        if drop_48h_pct >= 4.0: score += 5
                        if cur_rsi < 45: score += 5
                        
                        best_sweep = {
                            "symbol": sym,
                            "cur_price": cur_p,
                            "entry_price": closes[k],
                            "floor_price": sw_price,
                            "drop_48h": drop_48h_pct,
                            "rsi": cur_rsi,
                            "confluence": score,
                            "drift_pct": dist_to_entry,
                            "tp1": cur_p * 1.030,
                            "tp2": cur_p * 1.055,
                            "sl": sw_price * 0.985
                        }
                        break
    
    if best_sweep:
        candidates.append(best_sweep)
    else:
        # Si no hay barrida fresca, buscar monedas con sobreventa extrema y soporte sólido
        if cur_rsi < 36.0 and drop_48h_pct >= 5.0:
            candidates.append({
                "symbol": sym,
                "cur_price": cur_p,
                "entry_price": cur_p,
                "floor_price": min(lows[-24:]),
                "drop_48h": drop_48h_pct,
                "rsi": cur_rsi,
                "confluence": 78,
                "drift_pct": 0.0,
                "tp1": cur_p * 1.030,
                "tp2": cur_p * 1.055,
                "sl": min(lows[-24:]) * 0.985
            })

# Ordenar por confluencia
candidates.sort(key=lambda x: (x["confluence"], -x["rsi"]), reverse=True)

print(f"\n--- TOTAL CANDIDATAS ENCONTRADAS: {len(candidates)} ---")
for c in candidates[:8]:
    print(f"[{c['symbol']}] Confluencia: {c['confluence']}% | Precio: ${c['cur_price']} | RSI: {c['rsi']:.1f} | Caída 48h: -{c['drop_48h']:.1f}% | TP1: ${c['tp1']:.4f} | TP2: ${c['tp2']:.4f}")
