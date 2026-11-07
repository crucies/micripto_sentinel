const https = require('https');

function fetchJson(url) {
  return new Promise((resolve, reject) => {
    https.get(url, { headers: { 'User-Agent': 'Mozilla/5.0 MiCriptoSentinel/2.16' } }, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        try {
          resolve(JSON.parse(data));
        } catch (e) {
          reject(e);
        }
      });
    }).on('error', reject);
  });
}

function calculateEMA(values, period = 20) {
  if (values.length < period) return values[values.length - 1];
  const k = 2 / (period + 1);
  let ema = values.slice(0, period).reduce((a, b) => a + b, 0) / period;
  for (let i = period; i < values.length; i++) {
    ema = (values[i] * k) + (ema * (1 - k));
  }
  return ema;
}

function calculateRSI(values, period = 14) {
  if (values.length <= period) return 50.0;
  let gains = 0, losses = 0;
  for (let i = 1; i <= period; i++) {
    const diff = values[i] - values[i - 1];
    if (diff >= 0) gains += diff;
    else losses -= diff;
  }
  let avgGain = gains / period;
  let avgLoss = losses / period;

  for (let i = period + 1; i < values.length; i++) {
    const diff = values[i] - values[i - 1];
    const g = diff >= 0 ? diff : 0;
    const l = diff < 0 ? -diff : 0;
    avgGain = ((avgGain * (period - 1)) + g) / period;
    avgLoss = ((avgLoss * (period - 1)) + l) / period;
  }
  if (avgLoss === 0) return 100.0;
  const rs = avgGain / avgLoss;
  return 100 - (100 / (1 + rs));
}

async function main() {
  try {
    // 1. BTC 4h klines
    const btcKlines = await fetchJson('https://api.binance.com/api/v3/klines?symbol=BTCUSDT&interval=4h&limit=60');
    const closes = btcKlines.map(k => parseFloat(k[4]));
    const highs = btcKlines.map(k => parseFloat(k[2]));
    const lows = btcKlines.map(k => parseFloat(k[3]));

    const curBtc = closes[closes.length - 1];
    const ema20 = calculateEMA(closes, 20);
    const rsi = calculateRSI(closes, 14);
    const last12Highs = highs.slice(-12);
    const max48h = Math.max(...last12Highs);
    const drop48h = ((max48h - curBtc) / max48h) * 100;

    let regime = "🟡 MODO DEFENSIVO (CONSOLIDACIÓN / CAUTELA)";
    let regimeKey = "DEFENSIVE";
    let directive = "BTC en consolidación lateral previa al FOMC. Disparos reducidos al 50% ($100 USDT) con máxima confluencia.";

    if ((curBtc < ema20 && rsi < 48.0) || drop48h >= 5.0) {
      regime = "🔴 MODO REFUGIO (CORRECCIÓN MACRO)";
      regimeKey = "REFUGE";
      directive = "BTC bajo presión bajista en 4H. COMPRAS EN ALTCOINS BLOQUEADAS. Solo gestión de cobros en Take Profit.";
    } else if (curBtc >= ema20 && rsi >= 52.0 && drop48h < 3.0) {
      regime = "🟢 MODO CAZA (EXPANSIÓN / RISK-ON)";
      regimeKey = "HUNT";
      directive = "BTC sano sobre EMA20 4H. Clima favorable: Radar S+ activo al 100% ($200 USDT por trade).";
    }

    console.log("=== MACRO BTC 4H ===");
    console.log(`BTC Precio Actual: $${curBtc.toFixed(2)}`);
    console.log(`EMA20 (4h): $${ema20.toFixed(2)}`);
    console.log(`RSI (14, 4h): ${rsi.toFixed(2)}`);
    console.log(`Máx 48h: $${max48h.toFixed(2)} | Drop: ${drop48h.toFixed(2)}%`);
    console.log(`Régimen: ${regime}`);
    console.log(`Directriz: ${directive}\n`);

    // 2. Portfolio Conciliado con Binance Spot (5 de Noviembre 2026)
    const portfolio = [
      { symbol: "ONDO", amount: 1352.2446, cost_price: 0.44590452, category: "RWA" },
      { symbol: "XRP", amount: 387.38971614, cost_price: 1.32, category: "L1 / Payments" },
      { symbol: "SUI", amount: 358.4, cost_price: 1.03, category: "L1 High Throughput" },
      { symbol: "NEAR", amount: 64.1, cost_price: 4.92, category: "AI / L1" },
      { symbol: "JUP", amount: 955.00, cost_price: 0.31411564, category: "Solana DEX" },
      { symbol: "ADA", amount: 924.2993, cost_price: 0.21655011, category: "L1 Legacy" },
      { symbol: "AAVE", amount: 1.353, cost_price: 147.67, category: "DeFi Lending" },
      { symbol: "PENDLE", amount: 93.3, cost_price: 2.11, category: "Yield / DeFi" },
      { symbol: "TIA", amount: 338.00, cost_price: 0.5917, category: "Modular DA" },
      { symbol: "RENDER", amount: 67.65, cost_price: 1.82, category: "DePIN / GPU" },
      { symbol: "TAO", amount: 0.3731, cost_price: 268.00, category: "Decentralized AI" },
      { symbol: "ALGO", amount: 840.00, cost_price: 0.119, category: "L1 Legacy" },
      { symbol: "OP", amount: 727.08, cost_price: 0.1281, category: "Ethereum L2" },
      { symbol: "XLM", amount: 446.553, cost_price: 0.17860604, category: "Payments" },
      { symbol: "HBAR", amount: 1026.972, cost_price: 0.07776491, category: "Enterprise DLT" },
      { symbol: "APT", amount: 57.11, cost_price: 0.695, category: "Move L1" },
      { symbol: "BNB", amount: 0.01121081, cost_price: 764.73, category: "Exchange / Gas" },
    ];

    const freeUsdt = 458.59173847;

    const tickers = await fetchJson('https://api.binance.com/api/v3/ticker/24hr');
    const tickerMap = {};
    for (const t of tickers) {
      tickerMap[t.symbol] = t;
    }

    let totalCost = freeUsdt;
    let totalValue = freeUsdt;

    console.log("=== PORTAFOLIO EN VIVO ===");
    console.log("SYM     | AMOUNT     | COST      | LIVE PRICE  | 24H CHG  | PnL %    | VALUE USDT");
    console.log("---------------------------------------------------------------------------------");

    for (const p of portfolio) {
      const pair = `${p.symbol}USDT`;
      const t = tickerMap[pair];
      const livePrice = t ? parseFloat(t.lastPrice) : p.cost_price;
      const chg24 = t ? parseFloat(t.priceChangePercent) : 0;
      const costVal = p.amount * p.cost_price;
      const liveVal = p.amount * livePrice;
      const pnlPct = ((livePrice - p.cost_price) / p.cost_price) * 100;

      totalCost += costVal;
      totalValue += liveVal;

      console.log(
        `${p.symbol.padEnd(7)} | ${p.amount.toFixed(2).padStart(10)} | $${p.cost_price.toFixed(4).padEnd(8)} | $${livePrice.toFixed(4).padEnd(10)} | ${(chg24 >= 0 ? '+' : '') + chg24.toFixed(2).padStart(5)}% | ${(pnlPct >= 0 ? '+' : '') + pnlPct.toFixed(2).padStart(5)}% | $${liveVal.toFixed(2).padStart(8)}`
      );
    }

    const netPnl = totalValue - totalCost;
    const netPnlPct = (netPnl / totalCost) * 100;

    console.log("---------------------------------------------------------------------------------");
    console.log(`USDT    | ${freeUsdt.toFixed(2).padStart(10)} | $1.0000   | $1.0000     |   +0.00% |   +0.00% | $${freeUsdt.toFixed(2).padStart(8)}`);
    console.log("=================================================================================");
    console.log(`TOTAL INVERTIDO : $${totalCost.toFixed(2)} USDT`);
    console.log(`VALOR ACTUAL    : $${totalValue.toFixed(2)} USDT`);
    console.log(`PnL NETO        : ${(netPnl >= 0 ? '+' : '') + netPnl.toFixed(2)} USDT (${(netPnlPct >= 0 ? '+' : '') + netPnlPct.toFixed(2)}%)`);

  } catch (err) {
    console.error("Error:", err);
  }
}

main();
