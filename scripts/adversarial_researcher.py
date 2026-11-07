import json
import math
import os
import sys
import time
from datetime import datetime, timezone, timedelta
import urllib.request

SYMBOLS = [
    'RENDERUSDT', 'SUIUSDT', 'NEARUSDT', 'PENDLEUSDT', 'XRPUSDT',
    'ONDOUSDT', 'TAOUSDT', 'ALGOUSDT', 'HBARUSDT', 'XLMUSDT', 'BNBUSDT',
    'BTCUSDT', 'ETHUSDT', 'SOLUSDT', 'AVAXUSDT', 'LINKUSDT', 'INJUSDT',
    'APTUSDT', 'SEIUSDT', 'TIAUSDT', 'ARBUSDT', 'OPUSDT', 'FETUSDT',
    'AAVEUSDT', 'UNIUSDT', 'ADAUSDT', 'DOTUSDT', 'PYTHUSDT', 'GRTUSDT',
    'WLDUSDT', 'ARKMUSDT', 'FTMUSDT', 'POLUSDT', 'ICPUSDT', 'JUPUSDT',
    'RUNEUSDT', 'ENAUSDT', 'DOGEUSDT', 'ATOMUSDT', 'THETAUSDT', 'MKRUSDT',
    'CRVUSDT', 'LDOUSDT', 'STRKUSDT'
]

def fetch_klines(symbol, interval='1h', limit=72):
    url = f"https://api.binance.com/api/v3/klines?symbol={symbol}&interval={interval}&limit={limit}"
    req = urllib.request.Request(url, headers={'User-Agent': 'MiCriptoSentinel/1.0'})
    try:
        with urllib.request.urlopen(req, timeout=6) as response:
            data = json.loads(response.read().decode())
            candles = []
            for item in data:
                candles.append({
                    'time': int(item[0]) // 1000,
                    'open': float(item[1]),
                    'high': float(item[2]),
                    'low': float(item[3]),
                    'close': float(item[4]),
                    'volume': float(item[5]),
                })
            return candles
    except Exception as e:
        return []

def calculate_rsi(candles, period=14):
    if len(candles) <= period:
        return [50.0] * len(candles)
    rsi = [50.0] * len(candles)
    gains, losses = 0.0, 0.0
    for i in range(1, period + 1):
        diff = candles[i]['close'] - candles[i-1]['close']
        if diff >= 0:
            gains += diff
        else:
            losses -= diff
    avg_gain = gains / period
    avg_loss = losses / period
    rsi[period] = 100.0 if avg_loss == 0 else 100.0 - (100.0 / (1.0 + (avg_gain / avg_loss)))
    for i in range(period + 1, len(candles)):
        diff = candles[i]['close'] - candles[i-1]['close']
        gain = diff if diff >= 0 else 0.0
        loss = -diff if diff < 0 else 0.0
        avg_gain = ((avg_gain * (period - 1)) + gain) / period
        avg_loss = ((avg_loss * (period - 1)) + loss) / period
        rsi[i] = 100.0 if avg_loss == 0 else 100.0 - (100.0 / (1.0 + (avg_gain / avg_loss)))
    return rsi

def analyze_symbol(symbol):
    candles = fetch_klines(symbol, interval='1h', limit=72)
    if len(candles) < 48:
        return None

    rsi_arr = calculate_rsi(candles, 14)
    current_candle = candles[-1]
    current_price = current_candle['close']
    current_rsi = rsi_arr[-1]

    # Maximo de 48h
    high_48h = max(c['high'] for c in candles[-48:])
    drop_from_high_pct = ((high_48h - current_price) / high_48h) * 100.0 if high_48h > 0 else 0.0

    # Deteccion de suelos y pools
    lows = [c['low'] for c in candles[-48:]]
    min_low_48h = min(lows)

    # Identificar swing lows significativos
    swing_floors = []
    for i in range(5, len(candles) - 5):
        low_i = candles[i]['low']
        is_swing = all(low_i <= candles[i+k]['low'] for k in [-2, -1, 1, 2])
        if is_swing:
            swing_floors.append({'price': low_i, 'idx': i, 'rsi': rsi_arr[i]})

    nearest_floor = min_low_48h
    if swing_floors:
        below_floors = [f['price'] for f in swing_floors if f['price'] <= current_price]
        if below_floors:
            nearest_floor = max(below_floors)
        else:
            nearest_floor = swing_floors[-1]['price']

    dist_to_floor_pct = ((current_price - nearest_floor) / current_price) * 100.0 if current_price > 0 else 0.0

    # Evaluacion de mecha de rechazo en la vela actual y anterior
    lower_wick_cur = (min(current_candle['open'], current_candle['close']) - current_candle['low'])
    total_range_cur = current_candle['high'] - current_candle['low']
    wick_ratio_cur = (lower_wick_cur / total_range_cur) if total_range_cur > 0 else 0.0

    prev_candle = candles[-2]
    lower_wick_prev = (min(prev_candle['open'], prev_candle['close']) - prev_candle['low'])
    total_range_prev = prev_candle['high'] - prev_candle['low']
    wick_ratio_prev = (lower_wick_prev / total_range_prev) if total_range_prev > 0 else 0.0

    has_strong_wick = wick_ratio_cur >= 0.35 or wick_ratio_prev >= 0.35

    # Divergencia RSI
    rsi_divergence = False
    if swing_floors:
        last_floor = swing_floors[-1]
        if current_price <= last_floor['price'] * 1.01 and current_rsi > last_floor['rsi'] + 2.0:
            rsi_divergence = True

    # Volume surge
    vol_sma_20 = sum(c['volume'] for c in candles[-20:]) / 20.0 if len(candles) >= 20 else 1.0
    vol_ratio = (current_candle['volume'] / vol_sma_20) if vol_sma_20 > 0 else 1.0

    # Targets
    entry_price = current_price
    tp1 = entry_price * 1.030
    tp2 = entry_price * 1.055
    sl = entry_price * 0.972

    return {
        'symbol': symbol,
        'display': symbol.replace('USDT', ''),
        'current_price': current_price,
        'high_48h': high_48h,
        'drop_48h_pct': drop_from_high_pct,
        'nearest_floor': nearest_floor,
        'dist_to_floor_pct': dist_to_floor_pct,
        'rsi': current_rsi,
        'rsi_divergence': rsi_divergence,
        'has_strong_wick': has_strong_wick,
        'wick_ratio': max(wick_ratio_cur, wick_ratio_prev),
        'vol_ratio': vol_ratio,
        'tp1': tp1,
        'tp2': tp2,
        'sl': sl
    }

def run_adversarial_simulation():
    now_bot = datetime.now(timezone(timedelta(hours=-4)))
    date_str = now_bot.strftime('%Y-%m-%d %H:%M:%S')
    current_hour = now_bot.hour

    if current_hour >= 16 or current_hour < 4:
        session_name = "SESIÓN ASIÁTICA (Tokio & Hong Kong)"
        session_code = "ASIA_SESSION"
        next_session = "10:30 BOT (Sesión Americana / Wall Street)"
    else:
        session_name = "SESIÓN AMERICANA (Wall Street & ETFs)"
        session_code = "NY_SESSION"
        next_session = "22:00 BOT (Sesión Asiática)"

    print(f"[{session_name}] Iniciando escaneo cuantitativo en vivo sobre {len(SYMBOLS)} activos...")
    results = []
    for s in SYMBOLS:
        res = analyze_symbol(s)
        if res:
            results.append(res)
        time.sleep(0.04)

    # Filtrar candidatos prometedores
    candidates = []
    for r in results:
        is_candidate = (
            (r['dist_to_floor_pct'] <= 2.5 and r['drop_48h_pct'] >= 3.0) or
            (r['rsi'] < 42.0 and r['dist_to_floor_pct'] <= 3.5) or
            (r['has_strong_wick'] and r['drop_48h_pct'] >= 3.0)
        )
        if is_candidate:
            candidates.append(r)

    print(f"Candidatos preliminares para examen adversarial: {len(candidates)}")

    adversarial_reports = []
    for c in candidates:
        # 1. Tesis Alpha Scout
        scout_score = 70
        scout_arguments = []
        if c['dist_to_floor_pct'] <= 1.2:
            scout_score += 12
            scout_arguments.append(f"En suelo institucional 1H (${c['nearest_floor']:.4f}), distancia minima: {c['dist_to_floor_pct']:.2f}%")
        elif c['dist_to_floor_pct'] <= 2.5:
            scout_score += 6
            scout_arguments.append(f"Cercano al suelo 1H (${c['nearest_floor']:.4f})")

        if c['drop_48h_pct'] >= 4.0:
            scout_score += 10
            scout_arguments.append(f"Descuento real de 48h de -{c['drop_48h_pct']:.1f}%")
        elif c['drop_48h_pct'] >= 3.0:
            scout_score += 5
            scout_arguments.append(f"Descuento moderado de 48h de -{c['drop_48h_pct']:.1f}%")

        if c['has_strong_wick']:
            scout_score += 8
            scout_arguments.append(f"Rechazo de mecha absorbente detectado: {c['wick_ratio']*100:.1f}% de la vela")

        if c['rsi_divergence']:
            scout_score += 10
            scout_arguments.append("Divergencia alcista RSI confirmada frente al suelo anterior")
        elif c['rsi'] < 40.0:
            scout_score += 6
            scout_arguments.append(f"RSI en sobreventa saludable ({c['rsi']:.1f})")

        # 2. Ataque Adversarial (Inquisitor Red Team)
        adversary_penalties = 0
        adversary_attacks = []

        if not c['has_strong_wick']:
            adversary_penalties += 8
            adversary_attacks.append("Falta mecha de absorcion agresiva: presion de venta aun activa.")

        if c['dist_to_floor_pct'] > 1.8:
            adversary_penalties += 7
            adversary_attacks.append(f"Entrada prematura: aun le queda {c['dist_to_floor_pct']:.2f}% para testear el soporte real.")

        if c['vol_ratio'] < 0.7:
            adversary_penalties += 6
            adversary_attacks.append(f"Volumen debil ({c['vol_ratio']:.2f}x de SMA20): falta participacion institucional compradora.")

        if c['rsi'] < 30.0 and not c['has_strong_wick']:
            adversary_penalties += 8
            adversary_attacks.append("Capitulacion sin frenado: RSI extremo pero sin mecha de absorcion.")

        # 3. Arbitraje y Veredicto Cuantitativo (Arbiter Judge)
        final_confluence = min(96, max(60, scout_score - adversary_penalties))

        if final_confluence >= 90:
            grade = "S+"
            verdict = "APROBADA S+"
            verdict_desc = "Supero todas las objeciones del Adversario. Apta para entrada con $500 USDT."
        elif final_confluence >= 80:
            grade = "S"
            verdict = "ZONA S"
            verdict_desc = "Estructura solida pero esperando retroceso fino al suelo limite antes de gatillar."
        else:
            grade = "RECHAZADA"
            verdict = "VETO ADVERSARIAL"
            verdict_desc = "El Inquisidor expuso debilidades criticas. Prohibido arriesgar capital aqui."

        adversarial_reports.append({
            'symbol': c['symbol'],
            'display': c['display'],
            'price': c['current_price'],
            'nearest_floor': c['nearest_floor'],
            'dist_to_floor_pct': c['dist_to_floor_pct'],
            'drop_48h_pct': c['drop_48h_pct'],
            'rsi': c['rsi'],
            'tp1': c['tp1'],
            'tp2': c['tp2'],
            'sl': c['sl'],
            'scout_score': scout_score,
            'scout_arguments': scout_arguments,
            'adversary_attacks': adversary_attacks,
            'final_confluence': final_confluence,
            'grade': grade,
            'verdict': verdict,
            'verdict_desc': verdict_desc
        })

    adversarial_reports.sort(key=lambda x: x['final_confluence'], reverse=True)

    # 1. Guardar JSON para la App Móvil
    os.makedirs(os.path.join('assets', 'data'), exist_ok=True)
    json_path = os.path.join('assets', 'data', 'adversarial_report.json')

    json_payload = {
        'updatedAt': date_str,
        'sessionName': session_name,
        'sessionCode': session_code,
        'nextSession': next_session,
        'approvedCount': sum(1 for r in adversarial_reports if r['grade'] == 'S+'),
        'totalScanned': len(SYMBOLS),
        'candidates': adversarial_reports
    }

    with open(json_path, 'w', encoding='utf-8') as f:
        json.dump(json_payload, f, indent=2)
    print(f"JSON exportado con exito en {json_path}")

    # 2. Guardar Documento Markdown en rico_notas
    report_md = f"""# 🛡️ REPORTE DE INVESTIGACIÓN ADVERSARIAL CUANTITATIVA
**Alianza:** Richard & Kai — *Protocolo Antigravity*  
**Sesión Operativa:** {session_name}  
**Fecha de Emisión:** {date_str} BOT  
**Próxima Sesión:** {next_session}  
**Motor:** Smart Money Concepts (SMC) + Red Team Adversarial Validation  
**Universo Monitoreado:** 44 Pares Oficiales Binance Spot  
**Capital Asignado por Disparo:** $500.00 USDT  
**Disponibilidad Líquida Binance:** $891.00 USDT  

---

## 🎯 RESUMEN EJECUTIVO DE LA {session_name.upper()}
Este informe es el resultado del combate analítico entre nuestro **Alpha Scout** y el **Adversary Inquisitor**, evaluados por el **Arbiter Judge** 1 hora después de la apertura de los mercados mundiales.

| Moneda | Precio Actual | Suelo 1H | Distancia Suelo | Descuento 48h | RSI 1H | Score Final | Grado | Veredicto Adversarial |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :--- |
"""

    for r in adversarial_reports[:12]:
        badge = "🔥 **S+**" if r['grade'] == 'S+' else ("🟢 **S**" if r['grade'] == 'S' else "⛔ RECHAZADA")
        report_md += f"| **{r['display']}** | ${r['price']:.4f} | ${r['nearest_floor']:.4f} | {r['dist_to_floor_pct']:.2f}% | -{r['drop_48h_pct']:.1f}% | {r['rsi']:.1f} | **{r['final_confluence']}%** | {badge} | {r['verdict']} |\n"

    report_md += "\n---\n\n## ⚔️ DETALLE DE COMBATE ADVERSARIAL (TOP CONFIGURACIONES)\n"

    for r in adversarial_reports[:6]:
        report_md += f"""
### 🪙 {r['display']} / USDT — Veredicto: {r['verdict']} (Score: {r['final_confluence']}%)
- **Métricas Clave:**
  - **Precio Actual:** ${r['price']:.4f}
  - **Suelo Institucional:** ${r['nearest_floor']:.4f} (Distancia: `{r['dist_to_floor_pct']:.2f}%`)
  - **Descuento 48h:** `-{r['drop_48h_pct']:.1f}%`
  - **RSI 1H:** `{r['rsi']:.1f}`
  - **Niveles Sugeridos:** TP1 (+3.0%): `${r['tp1']:.4f}` | TP2 (+5.5%): `${r['tp2']:.4f}` | SL OCO (-2.8%): `${r['sl']:.4f}`

- **🟢 Alegato del Alpha Scout (Tesis Alcista):**
"""
        for arg in r['scout_arguments']:
            report_md += f"  - ✅ {arg}\n"

        report_md += "\n- **🔴 Ataque del Adversary Inquisitor (Riesgos & Objeciones):**\n"
        if r['adversary_attacks']:
            for att in r['adversary_attacks']:
                report_md += f"  - ⚠️ {att}\n"
        else:
            report_md += "  - 🛡️ *Ninguna objeción crítica encontrada: El setup resistió todas las pruebas de estrés.*\n"

        report_md += f"\n- **⚖️ Veredicto del Arbiter Judge:**\n"
        report_md += f"  - **{r['verdict_desc']}**\n"
        report_md += "\n"

    report_md += f"""
---
## 💡 PROTOCOLO DE EJECUCIÓN PARA RICHARD
1. **Para Activos Grado S+ (Score >= 90%):** Entrada táctica con $500 USDT usando Orden Límite en el suelo detectado con OCO inmediato (TP1 +3%, TP2 +5.5%, SL -2.8%).
2. **Para Activos Grado S (Score 80-89%):** Colocar orden de compra límite en el suelo exacto y esperar el retroceso sin perseguir el precio al alza.
3. **Para Activos Rechazados:** Cero dólares asignados; se evita el riesgo de atrape o capital congelado.

---
*Próxima actualización programada: {next_session}*
"""

    out_path = os.path.join('rico_notas', 'micripto_sentinel_investigacion_adversarial.md')
    with open(out_path, 'w', encoding='utf-8') as f:
        f.write(report_md)

    print(f"Reporte adversarial generado con exito en {out_path}")
    return adversarial_reports

if __name__ == '__main__':
    run_adversarial_simulation()
