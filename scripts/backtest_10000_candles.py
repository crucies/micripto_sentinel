import sys
sys.stdout.reconfigure(encoding='utf-8')
import time
import json
import urllib.request
import math

SYMBOLS = [
    "BTCUSDT", "ETHUSDT", "SOLUSDT", "SUIUSDT", "OPUSDT", 
    "TIAUSDT", "NEARUSDT", "RENDERUSDT", "INJUSDT", "SEIUSDT"
]

CANDLES_PER_SYMBOL = 1000  # 10 símbolos * 1000 velas = 10,000 velas total
BASE_URL = "https://api.binance.com/api/v3/klines"

def fetch_klines(symbol, limit=1000):
    url = f"{BASE_URL}?symbol={symbol}&interval=1h&limit={limit}"
    req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0 MiCriptoSentinel/Backtest'})
    try:
        with urllib.request.urlopen(req, timeout=12) as resp:
            data = json.loads(resp.read().decode('utf-8'))
            candles = []
            for k in data:
                candles.append({
                    'time': int(k[0]),
                    'open': float(k[1]),
                    'high': float(k[2]),
                    'low': float(k[3]),
                    'close': float(k[4]),
                    'volume': float(k[5]),
                })
            return candles
    except Exception as e:
        print(f"Error fetching {symbol}: {e}")
        return []

def calculate_rsi(closes, period=14):
    n = len(closes)
    rsi = [50.0] * n
    if n <= period:
        return rsi

    gains = 0.0
    losses = 0.0
    for i in range(1, period + 1):
        diff = closes[i] - closes[i - 1]
        if diff >= 0:
            gains += diff
        else:
            losses -= diff

    avg_gain = gains / period
    avg_loss = losses / period
    rsi[period] = 100.0 if avg_loss == 0 else 100.0 - (100.0 / (1.0 + (avg_gain / avg_loss)))

    for i in range(period + 1, n):
        diff = closes[i] - closes[i - 1]
        g = diff if diff > 0 else 0.0
        l = -diff if diff < 0 else 0.0
        avg_gain = ((avg_gain * (period - 1)) + g) / period
        avg_loss = ((avg_loss * (period - 1)) + l) / period
        if avg_loss == 0:
            rsi[i] = 100.0
        else:
            rs = avg_gain / avg_loss
            rsi[i] = 100.0 - (100.0 / (1.0 + rs))

    return rsi

def run_backtest():
    print("=" * 70)
    print("INICIANDO AUDITORIA CUANTITATIVA RIGUROSA: 10,000 VELAS 1H (BINANCE)")
    print("=" * 70)

    all_trades = []
    symbol_stats = {}

    for symbol in SYMBOLS:
        print(f"Descargando {CANDLES_PER_SYMBOL} velas 1H para {symbol}...")
        candles = fetch_klines(symbol, limit=CANDLES_PER_SYMBOL)
        if len(candles) < 200:
            print(f"Insuficientes velas para {symbol}")
            continue

        closes = [c['close'] for c in candles]
        highs = [c['high'] for c in candles]
        lows = [c['low'] for c in candles]
        opens = [c['open'] for c in candles]

        rsi = calculate_rsi(closes, 14)

        trades = []
        lookback = 4
        in_trade_until = 0

        for i in range(50, len(candles) - 30):
            if i < in_trade_until:
                continue

            # 1. Encontrar Swing Low previo (en las últimas 24 a 48 velas)
            found_swing = False
            swing_low_val = 0.0
            swing_low_idx = 0

            for j in range(i - 6, max(0, i - 48), -1):
                is_low = True
                for k in range(1, lookback + 1):
                    if j - k < 0 or j + k >= i:
                        is_low = False
                        break
                    if lows[j] >= lows[j - k] or lows[j] >= lows[j + k]:
                        is_low = False
                        break
                if is_low:
                    found_swing = True
                    swing_low_val = lows[j]
                    swing_low_idx = j
                    break

            if not found_swing:
                continue

            # 2. Barrida de liquidez (SFP): el mínimo actual perfora el swing low pero el cierre queda por encima
            swept = lows[i] < swing_low_val and closes[i] > swing_low_val
            if not swept:
                continue

            # 3. Descuento en 48 horas >= 3.5%
            max_high_48h = max(highs[max(0, i - 48):i])
            drop_48h = ((max_high_48h - lows[i]) / max_high_48h) * 100.0
            if drop_48h < 3.5:
                continue

            # 4. Mecha inferior de absorción >= 35% del rango total de la vela
            candle_range = highs[i] - lows[i]
            if candle_range <= 0:
                continue
            lower_wick = min(opens[i], closes[i]) - lows[i]
            wick_ratio = lower_wick / candle_range
            if wick_ratio < 0.35:
                continue

            # 5. CHoCH Envolvente o RSI de sobreventa / divergencia
            choch = closes[i] > highs[i - 1] or (closes[i] > opens[i] and wick_ratio >= 0.45)
            rsi_oversold_or_div = rsi[i] < 48.0 or (rsi[i] > rsi[swing_low_idx] and lows[i] < swing_low_val)

            if not (choch and rsi_oversold_or_div):
                continue

            confluence = 90
            if wick_ratio >= 0.45: confluence += 2
            if drop_48h >= 5.0: confluence += 2
            if rsi[i] < 42.0: confluence += 2

            entry_price = closes[i]
            tp1_price = entry_price * 1.030
            tp2_price = entry_price * 1.055
            sl_price = entry_price * 0.972

            # Simular desenlace en las siguientes velas
            tp1_hit = False
            tp2_hit = False
            sl_hit = False
            tp1_bar = 0
            tp2_bar = 0
            sl_bar = 0

            max_forward = min(len(candles), i + 120) # máximo 5 días (120 horas)
            for f in range(i + 1, max_forward):
                # Verificar SL
                if lows[f] <= sl_price:
                    sl_hit = True
                    sl_bar = f - i
                    break

                # Verificar TP1
                if not tp1_hit and highs[f] >= tp1_price:
                    tp1_hit = True
                    tp1_bar = f - i

                # Verificar TP2
                if tp1_hit and highs[f] >= tp2_price:
                    tp2_hit = True
                    tp2_bar = f - i
                    break

            win = tp1_hit
            full_win = tp1_hit and tp2_hit
            duration = sl_bar if sl_hit else (tp2_bar if tp2_hit else (tp1_bar if tp1_hit else (max_forward - i)))

            trade_record = {
                'symbol': symbol,
                'entry_idx': i,
                'entry_price': entry_price,
                'tp1_price': tp1_price,
                'tp2_price': tp2_price,
                'sl_price': sl_price,
                'win_tp1': win,
                'win_tp2': full_win,
                'sl_hit': sl_hit,
                'duration_hours': duration,
                'confluence': confluence,
                'drop_48h': drop_48h,
                'wick_ratio': wick_ratio * 100
            }
            trades.append(trade_record)
            all_trades.append(trade_record)
            in_trade_until = i + duration

        symbol_stats[symbol] = {
            'total_trades': len(trades),
            'tp1_wins': sum(1 for t in trades if t['win_tp1']),
            'tp2_wins': sum(1 for t in trades if t['win_tp2']),
            'losses': sum(1 for t in trades if t['sl_hit']),
            'avg_duration_h': (sum(t['duration_hours'] for t in trades) / len(trades)) if trades else 0
        }
        time.sleep(0.15)

    total_t = len(all_trades)
    tp1_w = sum(1 for t in all_trades if t['win_tp1'])
    tp2_w = sum(1 for t in all_trades if t['win_tp2'])
    losses = sum(1 for t in all_trades if t['sl_hit'])

    win_rate_tp1 = (tp1_w / total_t * 100.0) if total_t > 0 else 0
    win_rate_tp2 = (tp2_w / total_t * 100.0) if total_t > 0 else 0

    durations_tp1 = [t['duration_hours'] for t in all_trades if t['win_tp1']]
    durations_tp2 = [t['duration_hours'] for t in all_trades if t['win_tp2']]

    avg_h_tp1 = (sum(durations_tp1) / len(durations_tp1)) if durations_tp1 else 0
    avg_h_tp2 = (sum(durations_tp2) / len(durations_tp2)) if durations_tp2 else 0

    days_tested = CANDLES_PER_SYMBOL / 24.0
    signals_per_day_10coins = total_t / days_tested if days_tested > 0 else 0
    signals_per_day_44coins = (total_t * 4.4) / days_tested if days_tested > 0 else 0

    print("\n" + "=" * 70)
    print("RESULTADOS CONSOLIDADOS DEL BACKTEST (10,000 VELAS)")
    print("=" * 70)
    print(f"Total de Velas 1H Auditadas: {len(SYMBOLS) * CANDLES_PER_SYMBOL} velas")
    print(f"Periodo temporal equivalente: {days_tested:.1f} dias de mercado (~1.4 meses por activo)")
    print(f"Total de Senales S+ detectadas: {total_t} operaciones")
    print(f"[TP1] Aciertos (+3.0%): {tp1_w} de {total_t} ({win_rate_tp1:.1f}%)")
    print(f"[TP2] Aciertos (+5.5%): {tp2_w} de {total_t} ({win_rate_tp2:.1f}%)")
    print(f"[SL] Stops Loss Tocados (-2.8%): {losses} de {total_t} ({(losses/total_t*100 if total_t>0 else 0):.1f}%)")
    print("-" * 70)
    print(f"Tiempo promedio hasta TP1 (+3%): {avg_h_tp1:.1f} horas ({avg_h_tp1/24.0:.1f} dias)")
    print(f"Tiempo promedio hasta TP2 (+5.5%): {avg_h_tp2:.1f} horas ({avg_h_tp2/24.0:.1f} dias)")
    print("-" * 70)
    print(f"Frecuencia en las 10 monedas auditadas: {signals_per_day_10coins:.2f} senales S+/dia")
    print(f"Frecuencia proyectada en nuestro universo (44 monedas): {signals_per_day_44coins:.2f} senales S+/dia")
    print("=" * 70)

    print("\nDetalle por Simbolo:")
    for sym, st in symbol_stats.items():
        wr = (st['tp1_wins'] / st['total_trades'] * 100) if st['total_trades'] > 0 else 0
        print(f"  * {sym:10s}: {st['total_trades']:2d} trades | TP1 WR: {wr:5.1f}% | Perdidas: {st['losses']} | Duracion prom: {st['avg_duration_h']:.1f}h")

    # Guardar reporte
    results = {
        'candles_analyzed': len(SYMBOLS) * CANDLES_PER_SYMBOL,
        'days_tested': days_tested,
        'total_trades': total_t,
        'win_rate_tp1': win_rate_tp1,
        'win_rate_tp2': win_rate_tp2,
        'loss_rate': (losses / total_t * 100) if total_t > 0 else 0,
        'avg_hours_tp1': avg_h_tp1,
        'avg_hours_tp2': avg_h_tp2,
        'signals_per_day_10coins': signals_per_day_10coins,
        'signals_per_day_44coins': signals_per_day_44coins,
        'symbol_stats': symbol_stats,
        'trades': all_trades
    }
    with open('assets/data/backtest_10000_results.json', 'w', encoding='utf-8') as f:
        json.dump(results, f, indent=2)
    print("\nReporte guardado en assets/data/backtest_10000_results.json")

if __name__ == "__main__":
    run_backtest()
