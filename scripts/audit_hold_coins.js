const https = require('https');

const holdCoins = [
  { sym: "ONDO", name: "Ondo Finance", cat: "RWA / Bonos Tokenizados", coins: 1352.2446, cost: 0.4459 },
  { sym: "XRP", name: "Ripple", cat: "Pagos Transfronterizos", coins: 387.3897, cost: 1.3200 },
  { sym: "NEAR", name: "NEAR Protocol", cat: "IA + Sharding L1", coins: 64.10, cost: 4.9200 },
  { sym: "PENDLE", name: "Pendle Finance", cat: "Yield Trading / DeFi", coins: 93.30, cost: 2.1100 },
  { sym: "RENDER", name: "Render Network", cat: "GPU Computing / DePIN", coins: 67.65, cost: 1.8200 },
  { sym: "TAO", name: "Bittensor", cat: "Red Neuronal / IA", coins: 0.3731, cost: 268.00 },
  { sym: "HBAR", name: "Hedera Hashgraph", cat: "DLT Empresarial", coins: 1026.972, cost: 0.0778 },
];

function fetchTicker(symbol) {
  return new Promise((resolve) => {
    https.get(`https://api.binance.com/api/v3/ticker/24hr?symbol=${symbol}USDT`, { headers: { 'User-Agent': 'Mozilla/5.0' } }, res => {
      let d = '';
      res.on('data', chunk => d += chunk);
      res.on('end', () => {
        try { resolve(JSON.parse(d)); } catch { resolve(null); }
      });
    }).on('error', () => resolve(null));
  });
}

async function run() {
  console.log("=== AUDITORIA DE CRIPTOS EN HOLD ESTRATEGICO ===");
  console.log("SYM     | CATEGORIA           | COSTO    | PRECIO EN VIVO | 24H CHG | PnL %    | ESTADO INSTITUCIONAL");
  console.log("--------------------------------------------------------------------------------------------------");

  for (const c of holdCoins) {
    const t = await fetchTicker(c.sym);
    const live = t ? parseFloat(t.lastPrice) : c.cost;
    const chg = t ? parseFloat(t.priceChangePercent) : 0;
    const pnl = ((live - c.cost) / c.cost) * 100;

    let stance = "Hold Seguro";
    if (pnl >= -1.0 && pnl <= 2.0) stance = "🟢 En Punto de Equilibrio (Break-even)";
    else if (pnl < -15.0) stance = "🟡 Zona de Descuento (Monitorear Retest)";

    console.log(
      `${c.sym.padEnd(7)} | ${c.cat.padEnd(19)} | $${c.cost.toFixed(4).padEnd(8)} | $${live.toFixed(4).padEnd(14)} | ${chg >= 0 ? '+' : ''}${chg.toFixed(2)}% | ${pnl >= 0 ? '+' : ''}${pnl.toFixed(2)}% | ${stance}`
    );
  }
}
run();
