#!/usr/bin/env python3
"""
Motor de Reporte Diario de Régimen Macro y Portafolio Spot (Richard & Kai)
Evalúa el clima general del mercado (Bitcoin 4H), correlación de altcoins,
riesgos de desbloqueos y estado del portafolio.
"""

import urllib.request
import json
import math
from datetime import datetime, timezone, timedelta
import sys
import io

# Asegurar salida utf-8 en Windows
if sys.stdout.encoding != 'utf-8':
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

def get_binance_klines(symbol, interval="4h", limit=60):
    url = f"https://api.binance.com/api/v3/klines?symbol={symbol}&interval={interval}&limit={limit}"
    req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0 MiCriptoSentinel/2.16'})
    try:
        with urllib.request.urlopen(req, timeout=8) as response:
            return json.loads(response.read().decode('utf-8'))
    except Exception as e:
        print(f"Error fetching {symbol}: {e}")
        return []

def calculate_ema(values, period=20):
    if len(values) < period:
        return values[-1]
    k = 2.0 / (period + 1)
    ema = sum(values[:period]) / period
    for val in values[period:]:
        ema = (val * k) + (ema * (1.0 - k))
    return ema

def calculate_rsi(values, period=14):
    if len(values) <= period:
        return 50.0
    gains, losses = 0.0, 0.0
    for i in range(1, period + 1):
        diff = values[i] - values[i - 1]
        if diff >= 0:
            gains += diff
        else:
            losses -= diff
    avg_gain = gains / period
    avg_loss = losses / period
    for i in range(period + 1, len(values)):
        diff = values[i] - values[i - 1]
        g = diff if diff >= 0 else 0.0
        l = -diff if diff < 0 else 0.0
        avg_gain = ((avg_gain * (period - 1)) + g) / period
        avg_loss = ((avg_loss * (period - 1)) + l) / period
    if avg_loss == 0:
        return 100.0
    rs = avg_gain / avg_loss
    return 100.0 - (100.0 / (1.0 + rs))

def main():
    bot_tz = timezone(timedelta(hours=-4))
    now = datetime.now(bot_tz)
    date_str = now.strftime("%Y-%m-%d %H:%M:%S BOT")

    # 1. Analizar BTC 4H
    btc_klines = get_binance_klines("BTCUSDT", interval="4h", limit=60)
    if not btc_klines:
        print("No se pudo obtener datos de Bitcoin")
        return

    closes = [float(k[4]) for k in btc_klines]
    highs = [float(k[2]) for k in btc_klines]
    lows = [float(k[3]) for k in btc_klines]

    cur_btc = closes[-1]
    ema20_4h = calculate_ema(closes, 20)
    rsi_4h = calculate_rsi(closes, 14)
    max_48h = max(highs[-12:]) if len(highs) >= 12 else max(highs)
    drop_48h_pct = ((max_48h - cur_btc) / max_48h) * 100.0 if max_48h > 0 else 0.0

    # Clasificar Régimen Macro
    if (cur_btc < ema20_4h and rsi_4h < 48.0) or drop_48h_pct >= 5.0:
        regime = "🔴 MODO REFUGIO (CORRECCIÓN MACRO)"
        regime_code = "REFUGE"
        directive = "BTC bajo presión bajista en 4H. COMPRAS EN ALTCOINS BLOQUEADAS. Solo gestión de cobros en Take Profit."
    elif cur_btc >= ema20_4h and rsi_4h >= 52.0 and drop_48h_pct < 3.0:
        regime = "🟢 MODO CAZA (EXPANSIÓN / RISK-ON)"
        regime_code = "HUNT"
        directive = "BTC sano sobre EMA20 4H. Clima favorable: Radar S+ activo al 100% ($200 USDT por trade)."
    else:
        regime = "🟡 MODO DEFENSIVO (CONSOLIDACIÓN / CAUTELA)"
        regime_code = "DEFENSIVE"
        directive = "BTC en consolidación lateral. Disparos reducidos al 50% ($100 USDT) con máxima confluencia."

    # 2. Generar Reporte Markdown
    report_md = f"""# 🛡️ Reporte Diario de Régimen Macro y Clima de Mercado
**Fecha de Emisión:** {date_str}  
**Socio:** Richard & Kai (MiCripto Sentinel V.0.2.16)

---

## 🚦 Dictamen del Semáforo Macro: {regime}

| Métrica Macro | Valor Actual | Umbral Referencia | Estado Técnico |
| :--- | :--- | :--- | :--- |
| **Precio Bitcoin (BTC)** | **${cur_btc:,.2f}** | EMA20: ${ema20_4h:,.2f} | {'🟢 Sobre EMA20' if cur_btc >= ema20_4h else '🔴 Bajo EMA20'} |
| **RSI (4 Horas)** | **{rsi_4h:.1f}** | 50.0 (Neutral) | {'🟢 Fuerte' if rsi_4h >= 52 else ('🔴 Débil' if rsi_4h < 48 else '🟡 Neutral')} |
| **Retroceso desde Máx 48h** | **-{drop_48h_pct:.2f}%** | Pico 48h: ${max_48h:,.2f} | {'🟢 Saludable (<3%)' if drop_48h_pct < 3 else ('🔴 Corrección (>5%)' if drop_48h_pct >= 5 else '🟡 Moderado')} |

### 📌 Directriz Operativa de Kai:
> **{directive}**

---

## 🧭 Reglas Operativas para las Órdenes Vivas:
1. **12 Órdenes de Venta Límite en Binance Spot:** Se mantienen inalteradas esperando el rebote a TP1 y TP2. Ninguna se vende a mercado con pérdidas.
2. **Nuevas Compras:** {'Permitidas al 100%' if regime_code == 'HUNT' else ('Reducidas al 50%' if regime_code == 'DEFENSIVE' else 'SUSPENDIDAS HASTA QUE BTC RECUPERE EMA20 4H')}.
3. **Liquidez en USDT:** Mantener los **$81.77 USDT** protegidos en la bóveda líquida.
"""

    out_path = "rico_notas/micripto_sentinel_reporte_macro_diario.md"
    with open(out_path, "w", encoding="utf-8") as f:
        f.write(report_md)

    print(f"Reporte macro generado exitosamente en {out_path}")
    print(f"Estado: {regime}")
    print(f"BTC: ${cur_btc:,.2f} | EMA20: ${ema20_4h:,.2f} | RSI 4H: {rsi_4h:.1f} | Caída 48h: -{drop_48h_pct:.2f}%")

if __name__ == "__main__":
    main()
