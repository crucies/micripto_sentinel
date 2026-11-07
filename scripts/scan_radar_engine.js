const https = require('https');

const pairs = [
  "BTCUSDT", "ETHUSDT", "SOLUSDT", "BNBUSDT", "XRPUSDT", "DOGEUSDT", "ADAUSDT",
  "AVAXUSDT", "LINKUSDT", "SUIUSDT", "NEARUSDT", "APTUSDT", "DOTUSDT", "UNIUSDT",
  "ICPUSDT", "FETUSDT", "TAOUSDT", "RENDERUSDT", "AAVEUSDT", "INJUSDT", "TIAUSDT",
  "SEIUSDT", "ARBUSDT", "OPUSDT", "POLUSDT", "FTMUSDT", "ATOMUSDT", "ALGOUSDT",
  "HBARUSDT", "STXUSDT", "KASUSDT", "JUPUSDT", "ONDOUSDT", "PENDLEUSDT", "ENAUSDT",
  "WIFUSDT", "PEPEUSDT", "FLOKIUSDT", "BONKUSDT", "GALAUSDT", "SANDUSDT", "MANAUSDT",
  "CHZUSDT", "XLMUSDT"
];

function fetchKlines(symbol, interval = "1h", limit = 40) {
  return new Promise((resolve) => {
    https.get(`https://api.binance.com/api/v3/klines?symbol=${symbol}&interval=${interval}&limit=${limit}`, { headers: { 'User-Agent': 'Mozilla/5.0' } }, res => {
      let d = '';
      res.on('data', chunk => d += chunk);
      res.on('end', () => {
        try { 
          const parsed = JSON.parse(d);
          resolve(Array.isArray(parsed) ? parsed : null); 
        } catch { 
          resolve(null); 
        }
      });
    }).on('error', () => resolve(null));
  });
}

function calcRSI(closes, period = 14) {
  if (closes.length < period + 1) return 50.0;
  let gains = [], losses = [];
  for (let i = 1; i < closes.length; i++) {
    const diff = closes[i] - closes[i - 1];
    if (diff > 0) { gains.push(diff); losses.push(0); }
    else { gains.push(0); losses.push(Math.abs(diff)); }
  }
  let avgGain = gains.slice(0, period).reduce((a, b) => a + b, 0) / period;
  let avgLoss = losses.slice(0, period).reduce((a, b) => a + b, 0) / period;
  for (let i = period; i < gains.length; i++) {
    avgGain = (avgGain * (period - 1) + gains[i]) / period;
    avgLoss = (avgLoss * (period - 1) + losses[i]) / period;
  }
  if (avgLoss === 0) return 100.0;
  const rs = avgGain / avgLoss;
  return 100.0 - (100.0 / (1.0 + rs));
}

async function run() {
  console.log("=== ESCANEANDO 44 PARES CON MOTOR SMC S+ ===");
  const results = [];
  for (const p of pairs) {
    const klines = await fetchKlines(p, "1h", 40);
    if (!klines || !Array.isArray(klines) || klines.length < 30) continue;

    const closes = klines.map(k => parseFloat(k[4]));
    const highs = klines.map(k => parseFloat(k[2]));
    const lows = klines.map(k => parseFloat(k[3]));

    const cur = closes[closes.length - 1];
    const rsi = calcRSI(closes);

    const priorLows = lows.slice(-21, -1);
    const minLow = Math.min(...priorLows);
    const sweep = lows[lows.length - 1] <= minLow && cur > minLow;

    const priorHighs = highs.slice(-21, -1);
    const maxHigh = Math.max(...priorHighs);
    const distToHigh = ((maxHigh - cur) / maxHigh) * 100;
    const distToLow = ((cur - minLow) / minLow) * 100;

    let score = 50;
    if (rsi < 40) score += 20;
    else if (rsi < 45) score += 10;
    else if (rsi > 65) score -= 20;

    if (sweep) score += 25;
    if (distToLow < 2.0) score += 15;

    results.push({ symbol: p, price: cur, rsi, sweep, distToLow, distToHigh, score });
  }

  results.sort((a, b) => b.score - a.score);

  console.log("TOP 5 PARES MAS CERCANOS A SOPORTE:");
  results.slice(0, 5).forEach(r => {
    console.log(`${r.symbol.padEnd(10)} | Price: $${r.price.toFixed(4).padEnd(8)} | RSI: ${r.rsi.toFixed(1).padEnd(5)} | Sweep: ${r.sweep ? 'SI' : 'NO'} | DistLow: +${r.distToLow.toFixed(1)}% | Score: ${r.score}%`);
  });

  const overbought = results.filter(r => r.rsi > 65);
  console.log(`\nPares sobrecomprados en 1H (RSI > 65): ${overbought.length} de ${results.length}`);
  overbought.forEach(r => {
    console.log(`  -> ${r.symbol}: RSI ${r.rsi.toFixed(1)}`);
  });
}
run();
